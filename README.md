# 🍅 Toma

> A pomodoro session tracker with deep gamification and a **fully decentralized community** powered by the Nostr protocol. No central server. No database. No distance limits.

---

## Architecture & Features

### 1. Dual Progression: EXP & Coins 🪙
- **EXP (Experience Points)**: Public metric driving the 10-level hierarchy. Computed dynamically from session duration (10 EXP/min), completion bonus (+20%), active daily streak multiplier (+5% per day up to +50%), and session chaining. Publicly broadcasted to Nostr relays (`Kind 30150`).
- **Coins (🪙)**: Spendable in-app currency stored in the user's private wallet. Earned from sessions, daily challenges, and milestone badges. Used to unlock themes and cosmetics in the Aesthetics Shop.

### 2. Aesthetics & Visuals Shop
- **Featured Aesthetic: Monochrome Theme (200 🪙)**: Pure high-contrast obsidian and silver minimalism with custom liquid ink fluid background shader and frosted glass borders.
- Additional unlockable liquid shaders (Ocean Blue, Sunset Blaze, Aurora Borealis) and custom timer rings (Neon Pulse, Organic Vine).

### 3. Visual Effects & Animations
- **GLSL Fragment Shader (`shaders/lava_lamp.frag`)**: Hardware-accelerated fluid metaball shader with dynamic color uniform inputs. Automatically stops tickers when app is paused/inactive.
- **Glassmorphism**: Standardized `FrostedGlassCard` with native `BackdropFilter` (sigma: 16) and light refraction borders.
- **Reduced Motion**: Setting to disable continuous shaders and micro-animations for power-saving or accessibility.

### 4. Decentralized Nostr Community & Ghost Mode 👻
- **No Crypto Jargon**: 10-second onboarding with Name, Avatar, and PIN/Fingerprint lock. Keypairs generated and encrypted silently into Android Keystore.
- **Ghost Mode**: Instant one-tap home screen toggle that cuts all WebSocket connections to Nostr relays. Offline actions are queued in local SQLite and auto-drained when re-enabled.

---

## Directory Structure

```
toma/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── app.dart                       # Root MaterialApp, MultiBlocProvider, Navigation
│   ├── core/
│   │   ├── constants/                 # AppConstants, default relays, event kinds
│   │   └── theme/                     # AppColors, AppTheme, AppTypography, AppSpacing
│   ├── features/
│   │   ├── timer/                     # TimerBloc, TimerRing, Session entities & controls
│   │   ├── connectivity/              # ConnectivityCubit, GhostToggle
│   │   ├── stats/                     # StatsScreen, heatmap, badges
│   │   ├── shop/                      # ShopScreen, Monochrome Theme purchase flow
│   │   ├── community/                 # CommunityScreen, Nostr EXP leaderboard
│   │   └── profile/                   # ProfileScreen, 1-tap recovery card
│   └── shared/
│       └── widgets/                   # FrostedGlassCard, LavaLampBackground, CoinPill, ExpBar
├── shaders/
│   └── lava_lamp.frag                 # GLSL fragment shader
└── pubspec.yaml                       # Dependencies and asset registrations
```

---

## Running Toma

```bash
flutter pub get
flutter run
```
