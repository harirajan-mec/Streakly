import 'package:flutter/material.dart';
import 'habits/habit_grid_screen.dart';
import 'profile/analysis_screen.dart';
import 'mood/mood_tracker_screen.dart';
import 'notes/notes_screen.dart';
import 'habits/add_habit_screen.dart';
import '../services/navigation_service.dart';
import '../../widgets/shared_top_bar.dart';

/// MainNavigationScreen provides persistent bottom navigation for the grid view mode
/// This ensures all screens maintain the navigation bar when accessed from grid view

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Set grid view mode and current tab in NavigationService
    NavigationService.setGridViewMode(true);
    NavigationService.setCurrentTab(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Don't update _currentIndex here; wait for onPageChanged to update state
    // Avoid showing intermediate pages when jumping far distances
    final current = _pageController.hasClients ? _pageController.page?.round() ?? _currentIndex : _currentIndex;
    if ((current - index).abs() > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      appBar: SharedTopBar(currentIndex: _currentIndex),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          NavigationService.setCurrentTab(index);
        },
        physics: const BouncingScrollPhysics(), // Enable smooth scrolling with bounce effect
        allowImplicitScrolling: false,
        children: const [
          HabitGridScreen(showAppBar: false),
          AnalysisScreen(showAppBar: false),
          MoodTrackerScreen(showAppBar: false),
          NotesScreen(showAppBar: false),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        offset: isKeyboardVisible ? const Offset(0, 2.5) : Offset.zero,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isKeyboardVisible ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: IgnorePointer(
            ignoring: isKeyboardVisible,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddHabitScreen()),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomAppBar(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildNavItem(0, Icons.track_changes_outlined, Icons.track_changes, 'Home')),
                Expanded(child: _buildNavItem(1, Icons.analytics_outlined, Icons.analytics, 'Analysis')),
                const SizedBox(width: 60), // Space for FAB
                Expanded(child: _buildNavItem(2, Icons.mood_outlined, Icons.mood, 'Mood')),
                Expanded(child: _buildNavItem(3, Icons.note_outlined, Icons.note, 'Notes')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = index == _currentIndex;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 22,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
