class Mission {
  final String id, slug, title, description, type, activity, unit;
  final int target, coinReward, xpReward, progress;
  final bool completed;
  const Mission({required this.id, required this.slug, required this.title, required this.description, required this.type, required this.activity, required this.unit, required this.target, required this.coinReward, required this.xpReward, required this.progress, required this.completed});
  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
    id: j['id'] as String, slug: j['slug'] as String, title: j['title'] as String,
    description: j['description'] as String, type: j['type'] as String, activity: j['activity'] as String,
    unit: j['unit'] as String, target: (j['target'] as num).toInt(),
    coinReward: (j['coin_reward'] as num).toInt(), xpReward: (j['xp_reward'] as num).toInt(),
    progress: (j['progress'] as num? ?? 0).toInt(), completed: j['completed'] as bool? ?? false,
  );
  double get progressPct => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
}
