import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'diet_screen.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'run_screen.dart';
import 'workouts_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const home = 0, workouts = 1, run = 2, diet = 3, progress = 4;

  /// Permite que outras telas troquem de aba (ex.: atalho "Correr" na Home).
  static void goTo(BuildContext context, int index) {
    context.findAncestorStateOfType<_MainShellState>()?._select(index);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          WorkoutsScreen(),
          RunScreen(),
          DietScreen(),
          ProgressScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início'),
          NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: 'Treinos'),
          NavigationDestination(
              icon: Icon(Icons.directions_run_outlined),
              selectedIcon: Icon(Icons.directions_run_rounded),
              label: 'Corrida'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded),
              label: 'Dieta'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Progresso'),
        ],
      ),
    );
  }
}
