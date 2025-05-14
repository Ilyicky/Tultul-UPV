import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'map_screen.dart';
import 'building_list_screen.dart';
import 'bookmarks_screen.dart';
import 'profile_screen.dart';
import 'admin/dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isAdmin = userProvider.user?.isAdmin() ?? false;

    final List<Widget> adminScreens = [
      const MapScreen(),
      const BuildingListScreen(),
      const DashboardScreen(),
      const ProfileScreen(),
    ];

    final List<Widget> userScreens = [
      const MapScreen(),
      const BuildingListScreen(),
      const BookmarksScreen(),
      const ProfileScreen(),
    ];

    final screens = isAdmin ? adminScreens : userScreens;

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.business),
            label: 'Buildings',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            )
          else
            const NavigationDestination(
              icon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
