import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../screens/subscription/subscription_plans_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/main/main_navigation.dart';
import '../services/navigation_service.dart';
import '../providers/note_provider.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';

class SharedTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;

  const SharedTopBar({super.key, required this.currentIndex});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget leading;
    String title;

    switch (currentIndex) {
      case 1:
        leading = Icon(Icons.analytics_outlined, color: theme.colorScheme.primary, size: 28);
        title = 'Analysis';
        break;
      case 2:
        leading = Icon(Icons.mood_outlined, color: theme.colorScheme.primary, size: 28);
        title = 'Mood';
        break;
      case 3:
        leading = Icon(Icons.note_outlined, color: theme.colorScheme.primary, size: 28);
        title = 'Notes';
        break;
      default:
        leading = SizedBox(
          height: 40,
          width: 40,
          child: Lottie.asset(
            'assets/animations/Flame animation(1).json',
            repeat: true,
            fit: BoxFit.contain,
          ),
        );
        title = 'Streakly';
    }

    return AppBar(
      backgroundColor: theme.colorScheme.surface.withAlpha((0.95 * 255).round()),
      elevation: 0,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const SizedBox(width: 16),
          leading,
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        if (currentIndex == 0)
          IconButton(
            icon: const Icon(Icons.view_module),
            onPressed: () => _showViewOptionsBottomSheet(context),
          ),
        if (currentIndex == 3)
          Builder(builder: (ctx) {
            return IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search notes',
              onPressed: () {
                // Toggle Notes search UI via provider so the search field appears
                // below the shared top bar (Notes screen renders the field).
                final noteProvider = Provider.of<NoteProvider>(ctx, listen: false);
                noteProvider.toggleShowSearch();
              },
            );
          }),
        IconButton(
          icon: Icon(
            Icons.workspace_premium,
            color: theme.colorScheme.secondary,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SubscriptionPlansScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings, size: 24),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  // Search bottom sheet removed — Notes screen will show search field below
  // the shared top bar when `NoteProvider.showSearch` is true.

  void _showViewOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.list_alt,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text('List View'),
                subtitle: const Text('View habits as cards'),
                trailing: Icon(
                  !NavigationService.isGridViewMode ? Icons.check_circle : Icons.chevron_right,
                  color: !NavigationService.isGridViewMode ? theme.colorScheme.primary : null,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await NavigationService.setGridViewMode(false);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => MainNavigation(initialIndex: NavigationService.currentTabIndex)),
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view,
                    color: Colors.orange,
                  ),
                ),
                title: const Text('Grid View'),
                subtitle: const Text('View habits with yearly progress'),
                trailing: Icon(
                  NavigationService.isGridViewMode ? Icons.check_circle : Icons.chevron_right,
                  color: NavigationService.isGridViewMode ? theme.colorScheme.primary : null,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await NavigationService.setGridViewMode(true);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => MainNavigationScreen(initialIndex: NavigationService.currentTabIndex)),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
