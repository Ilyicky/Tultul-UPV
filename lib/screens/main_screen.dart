import 'package:flutter/material.dart';
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/screens/map/map_screen.dart';
import 'package:tultul_upv/screens/user/user_building_list_screen.dart';
import 'package:tultul_upv/screens/user/user_bookmark_screen.dart';
import 'package:tultul_upv/screens/user/user_profile_screen.dart';

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
    final List<NavigationDestination> destinations = [
      const NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
      const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
      const NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
      const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
    ];

    final List<Widget> screens = [
      MapScreen(
        building: widget.selectedBuilding,
        targetRoomId: widget.targetRoomId,
        targetFloorId: widget.targetFloorId,
      ),
      const UserBuildingsListScreen(),
      const UserBookmarkScreen(),
      const UserProfileScreen(),
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
  }
}
