import 'package:flutter/material.dart';

class MoodTrackerScreen extends StatelessWidget {
  final bool showAppBar;
  const MoodTrackerScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Mood Tracker'),
              elevation: 0,
            )
          : null,
      body: Center(
        child: Text(
          'Mood Tracker (empty)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
