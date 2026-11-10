enum SessionType {
  pomodoro(
    label: 'Pomodoro',
    defaultMinutes: 25,
    baseExp: 300,
    baseCoins: 10,
    isBreak: false,
  ),
  shortBreak(
    label: 'Short Break',
    defaultMinutes: 5,
    baseExp: 0,
    baseCoins: 0,
    isBreak: true,
  ),
  longBreak(
    label: 'Long Break',
    defaultMinutes: 15,
    baseExp: 0,
    baseCoins: 0,
    isBreak: true,
  ),
  deepWork(
    label: 'Deep Work',
    defaultMinutes: 50,
    baseExp: 700,
    baseCoins: 25,
    isBreak: false,
  ),
  custom(
    label: 'Custom',
    defaultMinutes: 30,
    baseExp: 360,
    baseCoins: 12,
    isBreak: false,
  ),
  stopwatch(
    label: 'Stopwatch',
    defaultMinutes: 0,
    baseExp: 0,
    baseCoins: 0,
    isBreak: false,
  );

  final String label;
  final int defaultMinutes;
  final int baseExp;
  final int baseCoins;
  final bool isBreak;

  const SessionType({
    required this.label,
    required this.defaultMinutes,
    required this.baseExp,
    required this.baseCoins,
    required this.isBreak,
  });
}
