import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/models/room.dart';

// ViewModels
import 'package:tultul_upv/viewmodels/search_viewmodel.dart';

// Services
import 'package:tultul_upv/services/building_service.dart';

// Widgets
import 'package:tultul_upv/screens/search/widgets/building_list_items.dart';
import 'package:tultul_upv/screens/search/widgets/room_list_items.dart';

// Export the list item widgets for use in this file
export 'package:tultul_upv/screens/search/widgets/building_list_items.dart';
export 'package:tultul_upv/screens/search/widgets/room_list_items.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SearchViewModel(BuildingService()),
      child: const _SearchScreenContent(),
    );
  }
}

class _SearchScreenContent extends StatelessWidget {
  const _SearchScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          _buildFilterChips(context),
          _buildSearchField(context),
          Expanded(
            child:
                viewModel.filter == 'Buildings'
                    ? _buildBuildingsList(context)
                    : _buildRoomsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            viewModel.filters
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: viewModel.filter == f,
                      onSelected: (selected) => viewModel.updateFilter(f),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText:
              viewModel.filter == 'Buildings'
                  ? 'Search buildings...'
                  : 'Search rooms...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: viewModel.updateSearchQuery,
      ),
    );
  }

  Widget _buildBuildingsList(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();

    return StreamBuilder<List<Building>>(
      stream: viewModel.buildings,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    viewModel.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading buildings...'),
              ],
            ),
          );
        }

        final buildings = viewModel.filterBuildings(snapshot.data ?? []);

        if (buildings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  viewModel.searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.business,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  viewModel.searchQuery.isNotEmpty
                      ? 'No buildings found matching your criteria'
                      : 'No buildings available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (viewModel.searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      viewModel.updateSearchQuery('');
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear search'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final building = buildings[index];
            return UserBuildingListItem(building: building);
          },
        );
      },
    );
  }

  Widget _buildRoomsList(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();

    return StreamBuilder<List<Room>>(
      stream: viewModel.rooms,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    viewModel.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading rooms...'),
              ],
            ),
          );
        }

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  viewModel.searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.room,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  viewModel.searchQuery.isNotEmpty
                      ? 'No rooms found matching your criteria'
                      : 'No rooms available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (viewModel.searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      viewModel.updateSearchQuery('');
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear search'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return UserRoomListItem(room: room);
          },
        );
      },
    );
  }
}
