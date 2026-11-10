/// Global constants and default configurations for Toma.
class AppConstants {
  AppConstants._();

  static const String appName = 'Toma';
  static const String appTagline = 'Grow your focus. Share the harvest.';
  static const String appVersion = '1.0.0';

  // Default free public Nostr relays for the decentralized community
  static const List<String> defaultRelays = [
    'wss://nos.lol',
    'wss://relay.damus.io',
    'wss://relay.primal.net',
  ];

  // Nostr Event Kinds
  static const int kindProfile = 0;
  static const int kindTextNote = 1;
  static const int kindContactList = 3;
  static const int kindBadgeAward = 8;
  static const int kindLeaderboardScore = 30150;
  static const int kindBadgeDefinition = 30009;
  static const int kindStudyGroup = 34550;

  // Leaderboard namespace
  static const String leaderboardDTagPrefix = 'toma:leaderboard';
}
