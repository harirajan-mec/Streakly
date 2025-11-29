import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // This is still needed for sharing
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';
import '../../widgets/modern_button.dart';
import '../auth/login_screen.dart';
import 'analysis_screen.dart';
import '../subscription/subscription_plans_screen.dart';
import 'leaderboard_screen.dart';
import '../../widgets/hero_stats_card.dart';
import '../reminders/test_notification_screen.dart';
import '../shop/shop_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.workspace_premium,
                color: Color(0xFFFFD700), // Gold color
                size: 28,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionPlansScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 100, // Added more bottom padding
        ),
        child: Column(
          children: [
            _buildHeroStatsCard(context),
            const SizedBox(height: 20),
            _buildMenuSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatsCard(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        // Calculate current streak
        int currentStreak = _calculateCurrentAllHabitsStreak(habitProvider);

        // Calculate weekly completion percentage
        int weeklyCompletionPercentage =
            _calculateWeeklyCompletionPercentage(habitProvider);

        return HeroStatsCard(
          currentStreak: currentStreak,
          weeklyCompletionPercentage: weeklyCompletionPercentage,
          habitProvider: habitProvider,
        );
      },
    );
  }

  int _calculateWeeklyCompletionPercentage(HabitProvider habitProvider) {
    final activeHabits = habitProvider.activeHabits;
    if (activeHabits.isEmpty) return 0;

    final today = DateTime.now();
    int totalPossibleCompletions = 0;
    int actualCompletions = 0;

    // Check last 7 days
    for (int daysBack = 0; daysBack < 7; daysBack++) {
      final checkDate = today.subtract(Duration(days: daysBack));

      // Get habits that existed on this date
      List<Habit> habitsOnDate = activeHabits
          .where((habit) => !habit.createdAt.isAfter(checkDate))
          .toList();

      totalPossibleCompletions += habitsOnDate.length;

      // Count completions on this date
      for (var habit in habitsOnDate) {
        bool habitCompleted = habit.completedDates.any((date) =>
            date.year == checkDate.year &&
            date.month == checkDate.month &&
            date.day == checkDate.day);

        if (habitCompleted) {
          actualCompletions++;
        }
      }
    }

    if (totalPossibleCompletions == 0) return 0;
    return ((actualCompletions / totalPossibleCompletions) * 100).round();
  }

  Widget _buildNewStatsSection(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        // Ensure we have a valid habit provider
        int currentAllHabitsStreak =
            _calculateCurrentAllHabitsStreak(habitProvider);

        // Calculate best all-habits streak in history
        int bestAllHabitsStreak = _calculateBestAllHabitsStreak(habitProvider);

        // Calculate score: +50 points for each day ALL habits were completed
        int score = _calculateTotalScore(habitProvider);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Current Streaks',
                  value: '$currentAllHabitsStreak',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Best Streak',
                  value: '$bestAllHabitsStreak',
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Score',
                  value: '$score',
                  icon: Icons.star,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Active Habits',
                value: '${habitProvider.activeHabits.length}',
                icon: Icons.track_changes,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total Streaks',
                value: '${habitProvider.totalStreaks}',
                icon: Icons.local_fire_department,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Completed Today',
                value: '${habitProvider.completedTodayCount}',
                icon: Icons.check_circle,
                color: Colors.greenAccent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Analysis',
              subtitle: 'View your habit statistics and progress',
              icon: Icons.analytics,
              iconColor: Colors.purpleAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Leaderboard',
              subtitle: 'See how you rank against other users',
              icon: Icons.leaderboard,
              iconColor: Colors.amberAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer<HabitProvider>(
          builder: (context, habitProvider, child) {
            final totalScore = _calculateCompletionScore(habitProvider);
            final totalCompletions = totalScore ~/ 10;

            return Column(
              children: [
                _buildMenuCard(
                  context,
                  [
                    _buildMenuItem(
                      context,
                      title: 'Scoreboard',
                      subtitle: 'See points earned from completions',
                      icon: Icons.emoji_events,
                      iconColor: Colors.orangeAccent,
                      onTap: () => _showScoreboardDialog(
                        context,
                        totalScore,
                        totalCompletions,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$totalScore pts',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Notification Settings',
              subtitle: 'Test and manage your habit reminders',
              icon: Icons.notifications_active,
              iconColor: Colors.blueAccent,
              onTap: () {
                _showNotificationSettingsDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Streakly Shop',
              subtitle: 'Unlock themes, boosters, and extras',
              icon: Icons.shopping_bag,
              iconColor: Colors.pinkAccent,
              onTap: () => _showShopDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Modified "Share App" Menu Item
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Share App',
              subtitle: 'Invite friends to join Streakly',
              icon: Icons.share, // Changed icon
              iconColor: Colors.lightGreen,
              onTap: () {
                _showShareDialog(context); // Changed method name for clarity
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              icon: Icons.help_outline,
              iconColor: Colors.cyanAccent,
              onTap: () {
                _showSupportDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'About',
              subtitle: 'Learn more about Streakly',
              icon: Icons.info_outline,
              iconColor: Colors.tealAccent,
              onTap: () {
                _showAboutDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy and data usage',
              icon: Icons.privacy_tip_outlined,
              iconColor: Colors.indigo,
              onTap: () {
                _showPrivacyPolicy(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Terms of Service',
              subtitle: 'View terms and conditions of use',
              icon: Icons.description_outlined,
              iconColor: Colors.deepPurple,
              onTap: () {
                _showTermsOfService(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              icon: Icons.logout,
              iconColor: Colors.redAccent,
              onTap: () {
                _showSignOutDialog(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color iconColor,
      required VoidCallback onTap,
      Widget? trailing}) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  void _showShopDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_bag, color: Colors.pinkAccent),
            ),
            const SizedBox(width: 12),
            const Text('Streakly Shop'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upgrade your experience with premium themes, streak boosts, and fun avatar items.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: const [
                _ShopHighlight(
                  icon: Icons.palette_outlined,
                  color: Colors.deepPurple,
                  title: 'Exclusive Themes',
                  subtitle: 'Personalize your streak dashboard',
                ),
                SizedBox(height: 12),
                _ShopHighlight(
                  icon: Icons.bolt,
                  color: Colors.orange,
                  title: 'Boosters & Power-ups',
                  subtitle: 'Keep your streak alive even on busy days',
                ),
                SizedBox(height: 12),
                _ShopHighlight(
                  icon: Icons.emoji_emotions,
                  color: Colors.green,
                  title: 'Avatar Goodies',
                  subtitle: 'Unlock badges, frames, and more fun flair',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Go to Shop'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // MODIFIED DIALOG FOR SHARING THE APP
  void _showShareDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.share, color: Colors.lightGreen),
            const SizedBox(width: 8),
            const Text('Share Streakly'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department,
                color: Colors.orange, size: 40),
            const SizedBox(height: 16),
            Text(
              'Enjoying Streakly? Share it with your friends and help them build great habits too!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Share App Link'),
              onPressed: () {
                // IMPORTANT: Replace with your actual package name
                const appPackageName = 'your.package.name';
                const appLink =
                    'https://play.google.com/store/apps/details?id=$appPackageName';

                final shareText =
                    'Check out Streakly, a great app for building habits! You can download it here: $appLink';
                Share.share(shareText);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: Colors.indigo),
            const SizedBox(width: 8),
            const Text('Privacy Policy'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Data Collection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We collect minimal data necessary to provide our habit tracking services:\n'
                  '• Account information (email, username)\n'
                  '• Habit data and completion records\n'
                  '• App usage analytics for improvement',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Usage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your data is used to:\n'
                  '• Sync your habits across devices\n'
                  '• Provide personalized insights\n'
                  '• Improve app functionality',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Security',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We use industry-standard encryption and security measures to protect your data. Your habit data is stored securely and is never shared with third parties.',
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.description_outlined, color: Colors.deepPurple),
            const SizedBox(width: 8),
            const Text('Terms of Service'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Acceptance of Terms',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By using Streakly, you agree to these terms of service. If you do not agree, please discontinue use of the app.',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'User Responsibilities',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Use the app for personal habit tracking only\n'
                  '• Provide accurate information\n'
                  '• Respect other users in community features\n'
                  '• Do not attempt to hack or misuse the service',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Service Availability',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We strive to provide reliable service but cannot guarantee 100% uptime. We reserve the right to modify or discontinue features with notice.',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Limitation of Liability',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Streakly is provided "as is" without warranties. We are not liable for any damages arising from app usage.',
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  int _calculateCurrentAllHabitsStreak(HabitProvider habitProvider) {
    final activeHabits = habitProvider.activeHabits;
    if (activeHabits.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    bool streakStarted = false;

    // Check each day going backwards from today
    for (int daysBack = 0; daysBack < 365; daysBack++) {
      final checkDate = today.subtract(Duration(days: daysBack));
      bool allHabitsCompleted = true;

      // Get habits that existed on this date
      List<Habit> habitsOnDate = activeHabits
          .where((habit) => !habit.createdAt.isAfter(checkDate))
          .toList();

      if (habitsOnDate.isEmpty) {
        // No habits existed on this date, skip
        continue;
      }

      // Check if ALL habits that existed were completed on this date
      for (var habit in habitsOnDate) {
        bool habitCompleted = habit.completedDates.any((date) =>
            date.year == checkDate.year &&
            date.month == checkDate.month &&
            date.day == checkDate.day);

        if (!habitCompleted) {
          allHabitsCompleted = false;
          break;
        }
      }

      if (allHabitsCompleted) {
        streak++;
        streakStarted = true;
      } else {
        // If we haven't started counting yet (today/yesterday not completed)
        if (!streakStarted && daysBack <= 1) {
          continue; // Allow today or yesterday to be incomplete
        }
        break; // Streak is broken
      }
    }

    return streak;
  }

  int _calculateBestAllHabitsStreak(HabitProvider habitProvider) {
    final activeHabits = habitProvider.activeHabits;
    if (activeHabits.isEmpty) return 0;

    int bestStreak = 0;
    int currentStreak = 0;
    final today = DateTime.now();

    // Find the earliest habit creation date
    DateTime earliestDate = today;
    for (var habit in activeHabits) {
      if (habit.createdAt.isBefore(earliestDate)) {
        earliestDate = habit.createdAt;
      }
    }

    // Check every day from earliest habit creation to today
    for (int daysFromStart = 0;
        daysFromStart <= today.difference(earliestDate).inDays;
        daysFromStart++) {
      final checkDate = earliestDate.add(Duration(days: daysFromStart));
      bool allHabitsCompleted = true;

      // Get habits that existed on this date
      List<Habit> habitsOnDate = activeHabits
          .where((habit) => !habit.createdAt.isAfter(checkDate))
          .toList();

      if (habitsOnDate.isEmpty) {
        currentStreak = 0;
        continue;
      }

      // Check if ALL habits that existed were completed on this date
      for (var habit in habitsOnDate) {
        bool habitCompleted = habit.completedDates.any((date) =>
            date.year == checkDate.year &&
            date.month == checkDate.month &&
            date.day == checkDate.day);

        if (!habitCompleted) {
          allHabitsCompleted = false;
          break;
        }
      }

      if (allHabitsCompleted) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    return bestStreak;
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'About Streakly',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            const Text(
                'Streakly helps you build better habits and maintain consistency in your daily routines.'),
            const SizedBox(height: 12),
            const Text(
                'Built with Flutter and designed for habit enthusiasts.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.help_outline,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Your Email',
                  hintText: 'Enter your email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  hintText: 'How can we help you?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          FilledButton(
            onPressed: () {
              final email = emailController.text.trim();
              final message = messageController.text.trim();

              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid email address')),
                );
                return;
              }

              if (message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your message')),
                );
                return;
              }

              // Launch email client with pre-filled content
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'habitmakerc@gmail.com',
                query:
                    'subject=Streakly Support Request&body=${Uri.encodeComponent(message)}\n\nFrom: $email',
              );

              launchUrl(emailUri).then((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening email client...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }).catchError((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Could not open email client. Please send your message to habitmakerc@gmail.com'),
                    duration: Duration(seconds: 4),
                  ),
                );
              });
            },
            child: const Text('Send'),
          ),
        ],
      ),
    ).then((_) {
      // Clean up controllers
      emailController.dispose();
      messageController.dispose();
    });
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ModernButton(
                    text: 'Cancel',
                    type: ModernButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: ModernButton(
                    text: 'Sign Out',
                    type: ModernButtonType.destructive,
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false)
                          .logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScoreboardDialog(
    BuildContext context,
    int totalScore,
    int totalCompletions,
  ) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Scoreboard'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total Score',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$totalScore pts',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habit Completions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalCompletions total',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.add, size: 16, color: Colors.orangeAccent),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Every completion adds 10 points to your score.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Going'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Notification Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bug_report, color: Colors.blue),
              ),
              title: const Text('Test Notifications'),
              subtitle: const Text('Debug and test notification system'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestNotificationScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.schedule, color: Colors.orange),
              ),
              title: const Text('Scheduled Reminders'),
              subtitle: Consumer<HabitProvider>(
                builder: (context, habitProvider, child) {
                  final habitsWithReminders = habitProvider.activeHabits
                      .where((h) => h.reminderTime != null)
                      .length;
                  return Text(
                      '$habitsWithReminders habit(s) have reminders set');
                },
              ),
              trailing: const Icon(Icons.info_outline, size: 16),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'You can set reminders when creating or editing habits. Each habit can have its own custom reminder time.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  int _calculateTotalScore(HabitProvider habitProvider) {
    final activeHabits = habitProvider.activeHabits;
    if (activeHabits.isEmpty) return 0;

    int totalScore = 0;
    final today = DateTime.now();

    // Find the earliest habit creation date
    DateTime earliestDate = today;
    for (var habit in activeHabits) {
      if (habit.createdAt.isBefore(earliestDate)) {
        earliestDate = habit.createdAt;
      }
    }

    // Check every day from earliest habit creation to today
    for (int daysFromStart = 0;
        daysFromStart <= today.difference(earliestDate).inDays;
        daysFromStart++) {
      final checkDate = earliestDate.add(Duration(days: daysFromStart));
      bool allHabitsCompleted = true;

      // Get habits that existed on this date
      List<Habit> habitsOnDate = activeHabits
          .where((habit) => !habit.createdAt.isAfter(checkDate))
          .toList();

      if (habitsOnDate.isEmpty) {
        continue;
      }

      // Check if ALL habits that existed were completed on this date
      for (var habit in habitsOnDate) {
        bool habitCompleted = habit.completedDates.any((date) =>
            date.year == checkDate.year &&
            date.month == checkDate.month &&
            date.day == checkDate.day);

        if (!habitCompleted) {
          allHabitsCompleted = false;
          break;
        }
      }

      // Award 50 points for each day ALL habits were completed
      if (allHabitsCompleted) {
        totalScore += 50;
      }
    }

    return totalScore;
  }

  int _calculateCompletionScore(HabitProvider habitProvider) {
    final habits = habitProvider.habits;
    if (habits.isEmpty) return 0;

    int totalCompletions = 0;
    for (final habit in habits) {
      if (habit.dailyCompletions.isNotEmpty) {
        totalCompletions +=
            habit.dailyCompletions.values.fold(0, (sum, count) => sum + count);
      } else {
        totalCompletions += habit.completedDates.length;
      }
    }

    return totalCompletions * 10;
  }
}

class _ShopHighlight extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ShopHighlight({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
