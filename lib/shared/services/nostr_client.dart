import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
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

    String levelTitle = 'Focus Explorer';
    try {
      final content = jsonDecode(event['content'] as String? ?? '{}');
      if (content is Map && content['level_title'] != null) {
        levelTitle = content['level_title'] as String;
      }
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

/// Community chat channel message (Kind 42 public chat or Kind 1 tagged note).
class NostrChannelMessage {
  final String id;
  final String channelId;
  final String pubkey;
  final String content;
  final DateTime createdAt;
  final bool isMilestone;
  final int? expEarned;

  NostrChannelMessage({
    required this.id,
    required this.channelId,
    required this.pubkey,
    required this.content,
    required this.createdAt,
    this.isMilestone = false,
    this.expEarned,
  });

  factory NostrChannelMessage.fromEvent(Map<String, dynamic> event) {
    final tags = (event['tags'] as List<dynamic>?) ?? [];
    String channelId = 'global_focus';
    bool isMilestone = false;
    int? expEarned;

    for (final tag in tags) {
      if (tag is List && tag.length >= 2) {
        final key = tag[0] as String;
        final val = tag[1] as String;
        if (key == 'e' || key == 'channel') {
          channelId = val;
        } else if (key == 'milestone') {
          isMilestone = true;
        } else if (key == 'exp') {
          expEarned = int.tryParse(val);
        }
      }
    }

    final createdSeconds = (event['created_at'] as int?) ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);

    return NostrChannelMessage(
      id: event['id'] as String? ?? '',
      channelId: channelId,
      pubkey: event['pubkey'] as String? ?? '',
      content: event['content'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdSeconds * 1000),
      isMilestone: isMilestone,
      expEarned: expEarned,
    );
  }
}

/// Focus channel specification
class NostrFocusChannel {
  final String id;
  final String name;
  final String description;

  const NostrFocusChannel({
    required this.id,
    required this.name,
    required this.description,
  });
}

/// Relay client managing real WebSocket pools, Kind 30150 leaderboard publishing & listening,
/// Kind 42 channel messaging, contact lists, and offline queue draining.
class NostrClient {
  final NostrKeyManager _keyManager;
  final List<String> relays = AppConstants.defaultRelays;
  final Set<String> _followedPubkeys = {};

  final Map<String, WebSocketChannel> _sockets = {};
  final Map<String, StreamSubscription> _socketSubscriptions = {};

  bool _isConnected = false;
  String _activeChannelId = 'global_focus';

  // Streams for reactive UI updates
  final StreamController<List<NostrLeaderboardEntry>> _leaderboardController =
      StreamController<List<NostrLeaderboardEntry>>.broadcast();
  final StreamController<NostrChannelMessage> _channelMessageController =
      StreamController<NostrChannelMessage>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  // In-memory cache of channel messages & leaderboard entries
  final Map<String, List<NostrChannelMessage>> _channelMessagesCache = {
    'global_focus': [],
    'deep_work': [],
    'sprint_club': [],
  };
  final Map<String, NostrLeaderboardEntry> _leaderboardCache = {};

  NostrClient(this._keyManager);

  bool get isConnected => _isConnected;
  int get activeSocketCount => _sockets.length;
  String get activeChannelId => _activeChannelId;
  Set<String> get followedPubkeys => Set.unmodifiable(_followedPubkeys);

  Stream<List<NostrLeaderboardEntry>> get leaderboardStream =>
      _leaderboardController.stream;
  Stream<NostrChannelMessage> get channelMessageStream =>
      _channelMessageController.stream;
  Stream<bool> get connectionStream => _connectionStateController.stream;

  List<NostrChannelMessage> getCachedChannelMessages(String channelId) {
    return List.unmodifiable(_channelMessagesCache[channelId] ?? []);
  }

  List<NostrLeaderboardEntry> getCachedLeaderboard() {
    final list = _leaderboardCache.values.toList();
    list.sort((a, b) => b.exp.compareTo(a.exp));
    return list;
  }

  /// Sets the currently active focus channel and subscribes to its events.
  void setActiveChannel(String channelId) {
    _activeChannelId = channelId;
    _channelMessagesCache.putIfAbsent(channelId, () => []);
    _subscribeToChannel(channelId);
  }

  /// Connects to the relay WebSocket pool.
  Future<void> connect() async {
    _isConnected = true;
    _connectionStateController.add(true);

    for (final relayUrl in relays) {
      _connectToRelay(relayUrl);
    }

    await drainOfflineQueue();
  }

  /// Disconnects from all active relays (e.g. for Ghost Mode or offline).
  Future<void> disconnect() async {
    _isConnected = false;
    _connectionStateController.add(false);

    for (final sub in _socketSubscriptions.values) {
      await sub.cancel();
    }
    _socketSubscriptions.clear();

    for (final ws in _sockets.values) {
      try {
        await ws.sink.close();
      } catch (_) {}
    }
    _sockets.clear();
  }

  Future<void> _connectToRelay(String url) async {
    if (!_isConnected) return;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _sockets[url] = channel;

      final sub = channel.stream.listen(
        (data) => _handleRelayMessage(data.toString()),
        onError: (_) => _handleRelayDisconnect(url),
        onDone: () => _handleRelayDisconnect(url),
      );
      _socketSubscriptions[url] = sub;

      // Subscribe to leaderboards and active channel
      _subscribeToLeaderboards(channel);
      _subscribeToChannel(_activeChannelId, channel);
    } catch (_) {
      _sockets.remove(url);
    }
  }

  void _handleRelayDisconnect(String url) {
    _sockets.remove(url);
    _socketSubscriptions.remove(url);
  }

  void _handleRelayMessage(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List && decoded.isNotEmpty) {
        final type = decoded[0] as String;
        if (type == 'EVENT' && decoded.length >= 3) {
          final subId = decoded[1] as String;
          final event = decoded[2] as Map<String, dynamic>;
          _processIncomingEvent(subId, event);
        }
      }
    } catch (_) {}
  }

  void _processIncomingEvent(String subId, Map<String, dynamic> event) {
    final kind = event['kind'] as int?;

    // Kind 30150: Leaderboard score
    if (kind == AppConstants.kindLeaderboardScore) {
      final entry = NostrLeaderboardEntry.fromEvent(event);
      if (entry.pubkey.isNotEmpty) {
        _leaderboardCache[entry.pubkey] = entry;
        _leaderboardController.add(getCachedLeaderboard());
      }
    }

    // Kind 42 (Channel message) or Kind 1 (Text note)
    if (kind == 42 || kind == AppConstants.kindTextNote) {
      final msg = NostrChannelMessage.fromEvent(event);
      final cache = _channelMessagesCache.putIfAbsent(msg.channelId, () => []);
      if (!cache.any((m) => m.id == msg.id)) {
        cache.add(msg);
        cache.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _channelMessageController.add(msg);
      }
    }
  }

  void _subscribeToLeaderboards([WebSocketChannel? targetWs]) {
    final subId = 'toma_lb_${DateTime.now().millisecondsSinceEpoch}';
    final req = jsonEncode([
      'REQ',
      subId,
      {
        'kinds': [AppConstants.kindLeaderboardScore],
        'limit': 50,
      }
    ]);

    if (targetWs != null) {
      try {
        targetWs.sink.add(req);
      } catch (_) {}
    } else {
      _sendToAllRelays(req);
    }
  }

  void _subscribeToChannel(String channelId, [WebSocketChannel? targetWs]) {
    final subId = 'toma_ch_${channelId}_${DateTime.now().millisecondsSinceEpoch}';
    final req = jsonEncode([
      'REQ',
      subId,
      {
        'kinds': [42, AppConstants.kindTextNote],
        '#e': [channelId],
        'limit': 50,
      }
    ]);

    if (targetWs != null) {
      try {
        targetWs.sink.add(req);
      } catch (_) {}
    } else {
      _sendToAllRelays(req);
    }
  }

  /// Sends a chat message to the specified Nostr channel.
  Future<NostrChannelMessage> sendChannelMessage({
    required String channelId,
    required String text,
  }) async {
    final tags = [
      ['e', channelId, relays.first, 'root'],
      ['channel', channelId],
      ['t', 'toma_channel'],
    ];

    final event = _createAndSignEvent(
      kind: 42,
      tags: tags,
      content: text,
    );

    final message = NostrChannelMessage.fromEvent(event);
    final cache = _channelMessagesCache.putIfAbsent(channelId, () => []);
    cache.add(message);
    _channelMessageController.add(message);

    if (!_isConnected) {
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

    return message;
  }

  /// Broadcasts a completed focus milestone to the active channel.
  Future<NostrChannelMessage> shareFocusMilestone({
    required String channelId,
    required int durationMinutes,
    required int expEarned,
    required String modeLabel,
  }) async {
    final content = 'Completed a $durationMinutes min $modeLabel focus sprint (+ $expEarned EXP)';
    final tags = [
      ['e', channelId, relays.first, 'root'],
      ['channel', channelId],
      ['milestone', 'focus_completed'],
      ['exp', expEarned.toString()],
      ['t', 'toma_milestone'],
    ];

    final event = _createAndSignEvent(
      kind: 42,
      tags: tags,
      content: content,
    );

    final message = NostrChannelMessage.fromEvent(event);
    final cache = _channelMessagesCache.putIfAbsent(channelId, () => []);
    cache.add(message);
    _channelMessageController.add(message);

    if (!_isConnected) {
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

    return message;
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

    // Update local user's entry in leaderboard
    final userEntry = NostrLeaderboardEntry.fromEvent(event);
    _leaderboardCache[userEntry.pubkey] = userEntry;
    _leaderboardController.add(getCachedLeaderboard());

    if (!_isConnected) {
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
      final decoded = Bech32.decode('npub', npub);
      if (decoded != null) {
        friendPubkey = decoded.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      }
    }

    _followedPubkeys.add(friendPubkey);

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
    final payload = jsonEncode(['EVENT', event]);
    _sendToAllRelays(payload);
  }

  void _sendToAllRelays(String payload) {
    for (final ws in _sockets.values) {
      try {
        ws.sink.add(payload);
      } catch (_) {}
    }
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
