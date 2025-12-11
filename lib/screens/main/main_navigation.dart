import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../habits/habits_screen.dart';
import '../habits/add_habit_screen.dart';
import '../profile/analysis_screen.dart';
import '../mood/mood_tracker_screen.dart';
import '../notes/notes_screen.dart';
import '../../providers/habit_provider.dart';
import '../../providers/note_provider.dart';
import '../../widgets/shared_top_bar.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _previousIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = [
    HabitsScreen(showAppBar: false), // Home
    AnalysisScreen(showAppBar: false), // Analysis
    MoodTrackerScreen(showAppBar: false), // Mood tracker (empty)
    NotesScreen(showAppBar: false), // Notes
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      appBar: SharedTopBar(currentIndex: _currentIndex),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          final previousIndex = _currentIndex;
          setState(() {
            _previousIndex = previousIndex;
            _currentIndex = index;
          });
          _refreshTab(previousIndex, index, context);
        },
        children: _screens,
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
                    Theme.of(context).colorScheme.primary.withAlpha((0.8 * 255).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).toInt()),
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
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 8,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: SizedBox(
          height: 66, // Slightly reduced height
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
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        // Do not update _currentIndex here — wait for PageView.onPageChanged
        final previousIndex = _currentIndex;
        // If jumping more than one page, jump instantly to avoid showing intermediate pages
        if ((previousIndex - index).abs() > 1) {
          _pageController.jumpToPage(index);
        } else {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
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
                  : Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
                      : Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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

  void _refreshTab(int previousIndex, int newIndex, BuildContext context) {
    if (previousIndex == newIndex) return;
    if (newIndex == 0 || newIndex == 1) {
      // Refresh habits when navigating to Home or Analysis (uses habits)
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      habitProvider.loadHabits();
    } else if (newIndex == 3) {
      // Refresh notes when navigating to notes tab
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      noteProvider.loadNotes();
    }
  }
}