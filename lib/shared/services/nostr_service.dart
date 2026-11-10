import 'nostr_client.dart';
import 'nostr_key_manager.dart';

export 'nostr_client.dart' show NostrLeaderboardEntry;

/// Central façade coordinating decentralized Nostr services across the app.
class NostrService {
  static NostrService? _instance;
  static NostrService get instance => _instance ??= NostrService._();

  final NostrKeyManager keyManager;
  final NostrClient client;

  NostrService._()
      : keyManager = NostrKeyManager(),
        client = NostrClient(NostrKeyManager()) {
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
