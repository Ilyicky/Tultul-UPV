import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tultul_upv/providers/user_provider.dart';
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/screens/map/map_screen.dart';
import 'package:tultul_upv/screens/buildings/buildings_list_screen.dart';
import 'package:tultul_upv/screens/bookmarks/bookmarks_screen.dart';
import 'package:tultul_upv/screens/profile/profile_screen.dart';
import 'package:tultul_upv/screens/admin/dashboard_screen.dart';
import 'package:tultul_upv/screens/buildings/admin_buildings_list_screen.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isAdmin = userProvider.user?.isAdmin() ?? false;

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

        // screens to be shown based on user role
        final List<Widget> screens =
            isAdmin
                ? [
                  MapScreen(
                    building: widget.selectedBuilding,
                    targetRoomId: widget.targetRoomId,
                    targetFloorId: widget.targetFloorId,
                  ),
                  const AdminBuildingsListScreen(),
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

        return Scaffold(
          body: screens[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
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
