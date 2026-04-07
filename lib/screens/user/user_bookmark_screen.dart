import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tultul_upv/providers/user_provider.dart';
import 'package:tultul_upv/services/building_service.dart';
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/models/room.dart';
import 'package:tultul_upv/screens/buildings/details/building_details_screen.dart';
import 'package:tultul_upv/screens/rooms/room_instructions_screen.dart';

class UserBookmarkScreen extends StatefulWidget {
  const UserBookmarkScreen({super.key});

  @override
  State<UserBookmarkScreen> createState() => _UserBookmarkScreenState();
}

class _UserBookmarkScreenState extends State<UserBookmarkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Items'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Buildings'), Tab(text: 'Rooms')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_BuildingsTab(), _RoomsTab()],
      ),
    );
  }
}

class _BuildingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final buildingService = BuildingService();

    if (userProvider.user == null) {
      return const Center(child: Text('Please log in to view your bookmarks'));
    }

    return StreamBuilder<List<Building>>(
      stream: buildingService.getBookmarkedBuildings(
        userProvider.user!.bookmarkedBuildings,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final buildings = snapshot.data ?? [];

        if (buildings.isEmpty) {
          return const Center(child: Text('No bookmarked buildings'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final building = buildings[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading:
                    building.imageUrl != null && building.imageUrl!.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            building.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.business, size: 50),
                          ),
                        )
                        : const Icon(Icons.business, size: 50),
                title: Text(
                  building.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(building.description),
                trailing: IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.amber),
                  onPressed: () async {
                    try {
                      await userProvider.removeBookmarkedBuilding(
                        building.buildingId,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Building removed from bookmarks'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              BuildingDetailsScreen(building: building),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _RoomsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final buildingService = BuildingService();

    if (userProvider.user == null) {
      return const Center(child: Text('Please log in to view your bookmarks'));
    }

    return StreamBuilder<List<Room>>(
      stream: buildingService.getBookmarkedRooms(
        userProvider.user!.bookmarkedRooms,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return const Center(child: Text('No bookmarked rooms'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.room),
                title: Text(room.name),
                subtitle: const Text('Room'),
                trailing: IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.amber),
                  onPressed: () async {
                    try {
                      await userProvider.removeBookmarkedRoom(room.roomId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Room removed from bookmarks'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomInstructionsScreen(room: room),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
