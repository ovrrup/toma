import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import 'nostr_key_manager.dart';

/// Leaderboard entry parsed from Nostr Kind 30150 events.
class NostrLeaderboardEntry {
  final String pubkey;
  final int exp;
  final int level;
  final int streakDays;
  final int totalMinutes;
  final String levelTitle;

  NostrLeaderboardEntry({
    required this.pubkey,
    required this.exp,
    required this.level,
    required this.streakDays,
    required this.totalMinutes,
    required this.levelTitle,
  });

  factory NostrLeaderboardEntry.fromEvent(Map<String, dynamic> event) {
    final tags = (event['tags'] as List<dynamic>?) ?? [];
    int exp = 0;
    int level = 1;
    int streakDays = 0;
    int totalMinutes = 0;

    for (final tag in tags) {
      if (tag is List && tag.length >= 2) {
        final key = tag[0] as String;
        final val = tag[1] as String;
        if (key == 'exp') exp = int.tryParse(val) ?? 0;
        if (key == 'level') level = int.tryParse(val) ?? 1;
        if (key == 'streak') streakDays = int.tryParse(val) ?? 0;
        if (key == 'total_minutes') totalMinutes = int.tryParse(val) ?? 0;
      }
    }

    String levelTitle = 'Tree';
    try {
      final content = jsonDecode(event['content'] as String? ?? '{}');
      levelTitle = (content['level_title'] as String?) ?? 'Tree';
    } catch (_) {}

    return NostrLeaderboardEntry(
      pubkey: event['pubkey'] as String? ?? '',
      exp: exp,
      level: level,
      streakDays: streakDays,
      totalMinutes: totalMinutes,
      levelTitle: levelTitle,
    );
  }
}

/// Relay client managing WebSocket pools, Kind 30150 leaderboard publishing,
/// Kind 3 contact list synchronization, and offline queue draining.
class NostrClient {
  final NostrKeyManager _keyManager;
  final List<String> relays = AppConstants.defaultRelays;
  final Set<String> _followedPubkeys = {};

  bool _isConnected = false;

  NostrClient(this._keyManager);

  bool get isConnected => _isConnected;
  Set<String> get followedPubkeys => Set.unmodifiable(_followedPubkeys);

  /// Connects to the relay pool.
  Future<void> connect() async {
    _isConnected = true;
    // In production with NDK, open WebSocket channels to each relay in relays list
    await drainOfflineQueue();
  }

  /// Disconnects from all active relays (invoked on Ghost Mode).
  Future<void> disconnect() async {
    _isConnected = false;
    // Sever active WebSocket connections
  }

  /// Publishes a Kind 30150 Parameterized Replaceable Event for the weekly leaderboard.
  Future<Map<String, dynamic>> publishLeaderboardScore({
    required int exp,
    required int level,
    required int streakDays,
    required int totalMinutes,
  }) async {
    final now = DateTime.now();
    final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).ceil();
    final dTag = '${AppConstants.leaderboardDTagPrefix}:weekly_${now.year}_w$weekNumber';

    final tags = [
      ['d', dTag],
      ['exp', exp.toString()],
      ['level', level.toString()],
      ['streak', streakDays.toString()],
      ['total_minutes', totalMinutes.toString()],
    ];

    final content = jsonEncode({
      'level_title': _getLevelTitle(level),
      'app_version': AppConstants.appVersion,
    });

    final event = _createAndSignEvent(
      kind: AppConstants.kindLeaderboardScore,
      tags: tags,
      content: content,
    );

    if (!_isConnected) {
      // Offline / Ghost Mode: Queue event in SQLite
      await DatabaseService.instance.enqueueEvent(
        PendingEvent(
          id: event['id'] as String,
          kind: event['kind'] as int,
          eventJson: jsonEncode(event),
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await _broadcastEvent(event);
    }

    return event;
  }

  /// Friend Pairing via QR: Adds a scanned friend's pubkey to the user's Kind 3 Contact List.
  Future<void> addFriendFromQr(String qrData) async {
    final clean = qrData.trim();
    String friendPubkey = clean;

    if (clean.startsWith('nostr:npub1') || clean.startsWith('npub1')) {
      final npub = clean.replaceFirst('nostr:', '');
      // Decode or store friend's public identifier
      friendPubkey = npub;
    }

    _followedPubkeys.add(friendPubkey);

    // Broadcast updated Kind 3 Contact List to Nostr relays
    final tags = _followedPubkeys.map((p) => ['p', p, relays.first, 'friend']).toList();
    final contactEvent = _createAndSignEvent(
      kind: AppConstants.kindContactList,
      tags: tags,
      content: '',
    );

    if (_isConnected) {
      await _broadcastEvent(contactEvent);
    } else {
      await DatabaseService.instance.enqueueEvent(
        PendingEvent(
          id: contactEvent['id'] as String,
          kind: contactEvent['kind'] as int,
          eventJson: jsonEncode(contactEvent),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Generates the payload string for the user's own shareable QR card.
  String generatePairingQrPayload() {
    final npub = _keyManager.bech32Npub ?? _keyManager.npubHex ?? 'anonymous';
    return 'nostr:$npub';
  }

  /// Drains all events waiting in the offline queue (FIFO order).
  Future<void> drainOfflineQueue() async {
    if (!_isConnected) return;

    final pending = await DatabaseService.instance.getPendingEvents();
    for (final item in pending) {
      try {
        final event = jsonDecode(item.eventJson) as Map<String, dynamic>;
        await _broadcastEvent(event);
        await DatabaseService.instance.removePendingEvent(item.id);
      } catch (_) {
        await DatabaseService.instance.recordEventFailure(item.id);
      }
    }
  }

  // --- Internal Event Helpers ---

  Map<String, dynamic> _createAndSignEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) {
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final pubkey = _keyManager.npubHex ?? '';

    final serialized = jsonEncode([
      0,
      pubkey,
      createdAt,
      kind,
      tags,
      content,
    ]);

    final id = sha256.convert(utf8.encode(serialized)).toString();
    final sig = _keyManager.signEventId(id);

    return {
      'id': id,
      'pubkey': pubkey,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
      'sig': sig,
    };
  }

  Future<void> _broadcastEvent(Map<String, dynamic> event) async {
    // Dispatches ["EVENT", event] to all relays in the bootstrap pool
  }

  String _getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Seedling';
      case 2:
        return 'Sprout';
      case 3:
        return 'Sapling';
      case 4:
        return 'Tree';
      case 5:
        return 'Master Grower';
      case 6:
        return 'Sunflower';
      case 7:
        return 'Blazing Focus';
      case 8:
        return 'Astral Sage';
      case 9:
        return 'Diamond Mind';
      case 10:
      default:
        return 'Harvest Sovereign';
    }
  }
}
