import 'package:flutter/material.dart';
import 'theme.dart';
import 'home_screen.dart';
import 'calendario_screen.dart';
import 'fabbrica_screen.dart';
import 'database_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VolleyApp());
}

class VolleyApp extends StatelessWidget {
  const VolleyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volley Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.data,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 2;
  int _homeTick = 0;
  int _calTick = 0;
  int _fabTick = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(refreshToken: _homeTick),
          CalendarioScreen(refreshToken: _calTick),
          FabbricaScreen(refreshToken: _fabTick),
          const DatabaseScreen(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: NavigationBar(
            height: 80,
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.pink.withValues(alpha: 0.35),
            selectedIndex: _currentIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              setState(() {
                _currentIndex = i;
                if (i == 0) _homeTick++;
                if (i == 1) _calTick++;
                if (i == 2) _fabTick++;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.extension_outlined),
                selectedIcon: Icon(Icons.extension_rounded),
                label: 'Fabric',
              ),
              NavigationDestination(
                icon: Icon(Icons.storage_outlined),
                selectedIcon: Icon(Icons.storage_rounded),
                label: 'Database',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
