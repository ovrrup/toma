import 'dart:async';
import 'nostr_client.dart';
import 'nostr_key_manager.dart';

export 'nostr_client.dart'
    show NostrLeaderboardEntry, NostrChannelMessage, NostrFocusChannel;

/// Central façade coordinating decentralized Nostr services across the app.
class NostrService {
  static NostrService? _instance;
  static NostrService get instance {
    if (_instance == null) {
      final km = NostrKeyManager();
      final cl = NostrClient(km);
      _instance = NostrService._(km, cl);
    }
    return _instance!;
  }

  final NostrKeyManager keyManager;
  final NostrClient client;

  // Curated Focus Channels
  static const List<NostrFocusChannel> focusChannels = [
    NostrFocusChannel(
      id: 'global_focus',
      name: 'Global Focus Lounge',
      description: 'Shared sanctuary for daily study, quiet work, and gentle accountability.',
    ),
    NostrFocusChannel(
      id: 'deep_work',
      name: 'Deep Work Hall',
      description: 'Extended uninterrupted sprints, research sessions, and flow state logs.',
    ),
    NostrFocusChannel(
      id: 'sprint_club',
      name: 'Sprint Club',
      description: 'Rapid 25-minute Pomodoro check-ins and shared harvest milestones.',
    ),
  ];

  NostrService._(this.keyManager, this.client) {
    _initSubsystems();
  }

  Future<void> _initSubsystems() async {
    await keyManager.init();
    await client.connect();
  }

  Future<void> init() async {
    await _initSubsystems();
  }

  String? get npub => keyManager.bech32Npub ?? keyManager.npubHex;
  String? get nsec => keyManager.bech32Nsec ?? keyManager.nsecHex;
  String? get recoveryPhrase => keyManager.mnemonic;

  bool get isConnected => client.isConnected;
  int get relayCount => client.activeSocketCount;
  String get activeChannelId => client.activeChannelId;

  Stream<List<NostrLeaderboardEntry>> get leaderboardStream => client.leaderboardStream;
  Stream<NostrChannelMessage> get channelMessageStream => client.channelMessageStream;
  Stream<bool> get connectionStream => client.connectionStream;

  List<NostrChannelMessage> getMessagesForChannel(String channelId) =>
      client.getCachedChannelMessages(channelId);

  List<NostrLeaderboardEntry> getLeaderboard() => client.getCachedLeaderboard();

  void setActiveChannel(String channelId) {
    client.setActiveChannel(channelId);
  }

  /// Sends a message into a Nostr focus channel.
  Future<NostrChannelMessage> sendChannelMessage({
    required String channelId,
    required String text,
  }) async {
    return client.sendChannelMessage(channelId: channelId, text: text);
  }

  /// Shares a completed focus session milestone into the channel.
  Future<NostrChannelMessage> shareMilestone({
    required String channelId,
    required int durationMinutes,
    required int expEarned,
    required String modeLabel,
  }) async {
    return client.shareFocusMilestone(
      channelId: channelId,
      durationMinutes: durationMinutes,
      expEarned: expEarned,
      modeLabel: modeLabel,
    );
  }

  /// Broadcasts or queues an EXP leaderboard update.
  Future<void> broadcastProgress({
    required int exp,
    required int level,
    required int streakDays,
    required int totalMinutes,
  }) async {
    await client.publishLeaderboardScore(
      exp: exp,
      level: level,
      streakDays: streakDays,
      totalMinutes: totalMinutes,
    );
  }

  /// Pairs with a peer by scanning their Nostr QR.
  Future<void> pairFriendFromQr(String qrData) async {
    await client.addFriendFromQr(qrData);
  }

  /// Gets the payload string for displaying the user's pairing QR card.
  String getPairingQr() => client.generatePairingQrPayload();

  /// Called by ConnectivityCubit to pause/resume relay sockets.
  void setGhostMode(bool isGhost) {
    if (isGhost) {
      client.disconnect();
    } else {
      client.connect();
    }
  }
}
