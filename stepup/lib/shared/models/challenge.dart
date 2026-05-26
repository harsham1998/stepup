import 'package:flutter/material.dart';

class Challenge {
  final String id, title, type, status, activityType;
  final int stepGoal, entryFee, prizePool, participantCount;
  final DateTime startTime, endTime;
  final int? maxParticipants;
  final String mode;
  final List<ChallengeMission> missions;
  final List<PrizeTier> prizeTiers;

  const Challenge({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.activityType,
    required this.stepGoal,
    required this.entryFee,
    required this.prizePool,
    required this.participantCount,
    required this.startTime,
    required this.endTime,
    this.maxParticipants,
    this.mode = 'individual',
    this.missions = const [],
    this.prizeTiers = const [],
  });

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: j['id'] as String,
        title: j['title'] as String,
        type: j['type'] as String,
        status: j['status'] as String,
        activityType: (j['activity_type'] as String?) ?? 'steps',
        stepGoal: (j['step_goal'] as num).toInt(),
        entryFee: (j['entry_fee'] as num).toInt(),
        prizePool: (j['prize_pool'] as num).toInt(),
        participantCount: (j['participant_count'] as num?)?.toInt() ?? 0,
        startTime: DateTime.parse(j['start_time'] as String),
        endTime: DateTime.parse(j['end_time'] as String),
        maxParticipants: (j['max_participants'] as num?)?.toInt(),
        mode: (j['mode'] as String?) ?? 'individual',
        missions: (j['missions'] as List? ?? [])
            .map((e) => ChallengeMission.fromJson(e as Map<String, dynamic>))
            .toList(),
        prizeTiers: (j['prize_tiers'] as List? ?? [])
            .map((e) => PrizeTier.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get isPaid => entryFee > 0;
  bool get isLive => status == 'active';

  String get modeLabel {
    switch (mode) {
      case 'duo':
        return 'Duo';
      case 'group':
        return 'Group';
      case 'team':
        return 'Team';
      default:
        return 'Individual';
    }
  }

  String get cadence {
    const cadenceValues = {'daily', 'weekly', 'monthly', 'seasonal'};
    if (cadenceValues.contains(type.toLowerCase())) return type.toLowerCase();
    final days = endTime.difference(startTime).inDays;
    if (days <= 1) return 'daily';
    if (days <= 7) return 'weekly';
    if (days <= 31) return 'monthly';
    return 'seasonal';
  }

  String get entryFeeInr => entryFee == 0 ? 'Free' : '₹${(entryFee / 100).toStringAsFixed(0)}';
  String get prizePoolInr => '₹${(prizePool / 100).toStringAsFixed(0)}';
  String get entryFeeCoins => entryFee == 0 ? 'FREE' : '${entryFee ~/ 100}¢';
  String get prizePoolCoins => '${prizePool ~/ 100}¢';

  String get goalLabel {
    switch (activityType) {
      case 'gym':
        return '$stepGoal sessions';
      case 'outdoor':
        return '$stepGoal matches';
      case 'cycling':
        return '${stepGoal}km';
      case 'running':
        return stepGoal >= 1000
            ? '${(stepGoal / 1000).toStringAsFixed(0)}k steps'
            : '${stepGoal}km';
      default:
        return stepGoal >= 1000
            ? '${(stepGoal / 1000).toStringAsFixed(stepGoal % 1000 == 0 ? 0 : 1)}k steps'
            : '$stepGoal steps';
    }
  }

  String get durationLabel {
    final days = endTime.difference(startTime).inDays + 1;
    return days == 1 ? '1 day' : '${days}d';
  }

  static const _config = {
    'steps': ActivityConfig(Colors.indigo, Color(0xFF6366F1), Color(0xFF8B5CF6), '👟', 'Steps'),
    'walking': ActivityConfig(Colors.teal, Color(0xFF14B8A6), Color(0xFF0EA5E9), '🚶', 'Walking'),
    'running': ActivityConfig(Colors.orange, Color(0xFFF97316), Color(0xFFEF4444), '🏃', 'Running'),
    'gym': ActivityConfig(Colors.red, Color(0xFFEF4444), Color(0xFFEC4899), '💪', 'Gym'),
    'outdoor': ActivityConfig(Colors.green, Color(0xFF22C55E), Color(0xFF10B981), '⚽', 'Outdoor'),
    'cycling': ActivityConfig(Colors.blue, Color(0xFF3B82F6), Color(0xFF06B6D4), '🚴', 'Cycling'),
  };

  ActivityConfig get activity => _config[activityType] ?? _config['steps']!;
}

class ActivityConfig {
  final Color base;
  final Color colorA, colorB;
  final String emoji, label;
  const ActivityConfig(this.base, this.colorA, this.colorB, this.emoji, this.label);
}

class ChallengeProgress {
  final bool joined;
  final int current;
  final int goal;
  final double percent;
  final int totalDays;
  final int daysPassed;
  final int daysLeft;
  final int dailyGoal;
  final bool completedToday;
  final List<bool> dailyCheckins;
  final int? rank;
  final int totalParticipants;
  final String activityType;
  final int prizePool;
  final List<MissionProgress> missionProgress;

  const ChallengeProgress({
    required this.joined,
    required this.current,
    required this.goal,
    required this.percent,
    required this.totalDays,
    required this.daysPassed,
    required this.daysLeft,
    required this.dailyGoal,
    required this.completedToday,
    required this.dailyCheckins,
    required this.rank,
    required this.totalParticipants,
    required this.activityType,
    required this.prizePool,
    required this.missionProgress,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> j) => ChallengeProgress(
        joined: j['joined'] as bool,
        current: (j['current'] as num).toInt(),
        goal: (j['goal'] as num).toInt(),
        percent: (j['percent'] as num).toDouble(),
        totalDays: (j['totalDays'] as num).toInt(),
        daysPassed: (j['daysPassed'] as num).toInt(),
        daysLeft: (j['daysLeft'] as num).toInt(),
        dailyGoal: (j['dailyGoal'] as num).toInt(),
        completedToday: j['completedToday'] as bool,
        dailyCheckins: (j['dailyCheckins'] as List).map((e) => e as bool).toList(),
        rank: (j['rank'] as num?)?.toInt(),
        totalParticipants: (j['totalParticipants'] as num).toInt(),
        activityType: (j['activityType'] as String?) ?? 'steps',
        prizePool: (j['prizePool'] as num).toInt(),
        missionProgress: (j['mission_progress'] as List? ?? [])
            .map((e) => MissionProgress.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get prizePoolCoins => '${prizePool ~/ 100}¢';
}

class ChallengeMission {
  final String id;
  final String missionId;
  final String title;
  final String description;
  final String type;
  final int target;
  final String unit;
  final int xpReward;
  final int bonusXp;

  const ChallengeMission({
    required this.id,
    required this.missionId,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.unit,
    required this.xpReward,
    required this.bonusXp,
  });

  int get totalXp => xpReward + bonusXp;

  factory ChallengeMission.fromJson(Map<String, dynamic> j) => ChallengeMission(
        id: j['id'] as String,
        missionId: (j['mission_id'] as String?) ?? j['id'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'daily',
        target: (j['target'] as num).toInt(),
        unit: (j['unit'] as String?) ?? 'steps',
        xpReward: (j['xp_reward'] as num).toInt(),
        bonusXp: (j['bonus_xp'] as num).toInt(),
      );
}

class PrizeTier {
  final int topPercent;
  final String label;
  final int coins;

  const PrizeTier({required this.topPercent, required this.label, required this.coins});

  factory PrizeTier.fromJson(Map<String, dynamic> j) => PrizeTier(
        topPercent: (j['top_percent'] as num).toInt(),
        label: j['label'] as String,
        coins: (j['coins'] as num).toInt(),
      );
}

class MissionProgress {
  final String missionId;
  final String title;
  final int target;
  final int current;
  final String unit;
  final bool completed;
  final int xpEarned;
  final int totalXp;

  const MissionProgress({
    required this.missionId,
    required this.title,
    required this.target,
    required this.current,
    required this.unit,
    required this.completed,
    required this.xpEarned,
    required this.totalXp,
  });

  double get percent => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);

  factory MissionProgress.fromJson(Map<String, dynamic> j) => MissionProgress(
        missionId: j['mission_id'] as String,
        title: j['title'] as String,
        target: (j['target'] as num).toInt(),
        current: (j['current'] as num).toInt(),
        unit: (j['unit'] as String?) ?? 'steps',
        completed: j['completed'] as bool,
        xpEarned: (j['xp_earned'] as num).toInt(),
        totalXp: (j['total_xp'] as num).toInt(),
      );
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int current;
  final int xpEarned;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.current,
    required this.xpEarned,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: (j['rank'] as num).toInt(),
        userId: j['user_id'] as String,
        displayName: (j['display_name'] as String?) ?? 'Athlete',
        avatarUrl: j['avatar_url'] as String?,
        current: (j['current'] as num).toInt(),
        xpEarned: (j['xp_earned'] as num).toInt(),
      );
}

class ChallengeLeaderboard {
  final int? yourRank;
  final int total;
  final String updatedAt;
  final List<LeaderboardEntry> participants;

  const ChallengeLeaderboard({
    this.yourRank,
    required this.total,
    required this.updatedAt,
    required this.participants,
  });

  factory ChallengeLeaderboard.fromJson(Map<String, dynamic> j) => ChallengeLeaderboard(
        yourRank: (j['your_rank'] as num?)?.toInt(),
        total: (j['total'] as num).toInt(),
        updatedAt: j['updated_at'] as String,
        participants: (j['participants'] as List)
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
