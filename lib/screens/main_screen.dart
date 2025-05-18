import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tultul_upv/providers/user_provider.dart';
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/screens/map/map_screen.dart';
import 'package:tultul_upv/screens/buildings/buildings_list_screen.dart';
import 'package:tultul_upv/screens/bookmarks/bookmarks_screen.dart';
import 'package:tultul_upv/screens/profile/profile_screen.dart';
import 'package:tultul_upv/screens/admin/dashboard_screen.dart';
import 'package:flutter/foundation.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final Building? selectedBuilding;
  final bool preserveNavigation;
  final String? targetRoomId;
  final String? targetFloorId;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.selectedBuilding,
    this.preserveNavigation = false,
    this.targetRoomId,
    this.targetFloorId,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    if (kDebugMode) {
      print('MainScreen initialized with index: $_selectedIndex');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isAdmin = userProvider.user?.isAdmin() ?? false;

        if (kDebugMode) {
          print(
            'MainScreen rebuild - Current user: ${userProvider.user?.email}',
          );
          print('MainScreen rebuild - Is admin: $isAdmin');
          print('MainScreen rebuild - Selected index: $_selectedIndex');
        }

        // Define navigation items based on user role
        final List<NavigationDestination> destinations =
            isAdmin
                ? [
                  const NavigationDestination(
                    icon: Icon(Icons.map),
                    label: 'Map',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ]
                : [
                  const NavigationDestination(
                    icon: Icon(Icons.map),
                    label: 'Map',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.bookmark),
                    label: 'Saved',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ];

        // Define screens based on user role
        final List<Widget> screens =
            isAdmin
                ? [
                  MapScreen(
                    building: widget.selectedBuilding,
                    targetRoomId: widget.targetRoomId,
                    targetFloorId: widget.targetFloorId,
                  ),
                  const BuildingsListScreen(),
                  const DashboardScreen(),
                  const ProfileScreen(),
                ]
                : [
                  MapScreen(
                    building: widget.selectedBuilding,
                    targetRoomId: widget.targetRoomId,
                    targetFloorId: widget.targetFloorId,
                  ),
                  const BuildingsListScreen(),
                  const BookmarksScreen(),
                  const ProfileScreen(),
                ];

        if (kDebugMode) {
          print('Navigation destinations count: ${destinations.length}');
          print(
            'Navigation items: ${destinations.map((d) => d.label).join(', ')}',
          );
        }

        return Scaffold(
          body: screens[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (kDebugMode) {
                print('Navigation selected: ${destinations[index].label}');
              }
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: destinations,
          ),
        );
      },
    );
  }
}
