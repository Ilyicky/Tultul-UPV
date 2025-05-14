import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/building_service.dart';
import '../models/building.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved Items'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Buildings'),
              Tab(text: 'Rooms'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookmarkedBuildingsList(),
            _BookmarkedRoomsList(),
          ],
        ),
      ),
    );
  }
}

class _BookmarkedBuildingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final buildingService = BuildingService();

    if (userProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userProvider.user == null) {
      return const Center(child: Text('Please log in to view bookmarks'));
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
          return const Center(
            child: Text('No bookmarked buildings yet'),
          );
        }

        return ListView.builder(
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final building = buildings[index];
            return ListTile(
              leading: const Icon(Icons.business),
              title: Text(building.name),
              subtitle: Text(building.college),
              trailing: IconButton(
                icon: const Icon(Icons.bookmark),
                onPressed: () {
                  userProvider.updateBookmarks(buildingId: building.buildingId);
                },
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/building-detail',
                  arguments: building.buildingId,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _BookmarkedRoomsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userProvider.user == null) {
      return const Center(child: Text('Please log in to view bookmarks'));
    }

    // TODO: Implement room bookmarks when room service is ready
    return const Center(child: Text('Room bookmarks coming soon'));
  }
} 