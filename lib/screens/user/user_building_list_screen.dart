import 'package:flutter/material.dart';

//App Screens
import 'package:tultul_upv/screens/rooms/room_instructions_screen.dart';
import 'package:tultul_upv/screens/buildings/details/building_details_screen.dart';

//Services
import 'package:tultul_upv/services/building_service.dart';

//Models
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/models/room.dart';

//Widgets
import 'package:tultul_upv/widgets/search_bar.dart';

class UserBuildingsListScreen extends StatefulWidget {
  const UserBuildingsListScreen({super.key});

  @override
  State<UserBuildingsListScreen> createState() =>
      _UserBuildingsListScreenState();
}

class _UserBuildingsListScreenState extends State<UserBuildingsListScreen> {
  final BuildingService _buildingService = BuildingService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'Buildings';
  final List<String> _filters = ['Buildings', 'Rooms'];
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  _filters
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _filter == f,
                            onSelected: (selected) {
                              if (!mounted) return;
                              setState(() => _filter = f);
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          // Search Bar
          CustomSearchBar(
            controller: _searchController,
            hintText:
                _filter == 'Buildings'
                    ? 'Search buildings...'
                    : 'Search rooms...',
            onChanged: (value) {
              if (!mounted) return;
              setState(() => _searchQuery = value.toLowerCase());
            },
            onClear: () {
              if (!mounted) return;
              setState(() => _searchQuery = '');
            },
          ),

          // Results List
          Expanded(
            child:
                _filter == 'Buildings'
                    ? _buildBuildingsList(context)
                    : _buildRoomsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingsList(BuildContext context) {
    return StreamBuilder<List<Building>>(
      stream: _buildingService.buildings,
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
                    setState(() {}); // Retry loading
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

        final buildings = snapshot.data ?? [];
        final filteredBuildings =
            buildings.where((building) {
              final name = building.name.toLowerCase();
              final popularNames =
                  building.popularNames?.join(' ').toLowerCase() ?? '';
              final description = building.description.toLowerCase();

              // Apply search query filter with improved matching
              final matchesSearch =
                  _searchQuery.isEmpty ||
                  name.contains(_searchQuery) ||
                  popularNames.contains(_searchQuery) ||
                  description.contains(_searchQuery);

              return matchesSearch;
            }).toList();

        if (filteredBuildings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off : Icons.business,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No buildings found matching your criteria'
                      : 'No buildings available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear all filters'),
                  ),
                ],
              ],
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
            key: ValueKey<int>(filteredBuildings.length),
            padding: const EdgeInsets.all(8),
            itemCount: filteredBuildings.length,
            itemBuilder: (context, index) {
              final building = filteredBuildings[index];
              return Card(
                key: ValueKey<String>(building.buildingId),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Building Image
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image
                            building.imageUrl != null &&
                                    building.imageUrl!.isNotEmpty
                                ? Image.network(
                                  building.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                      'Error loading image for building: ${building.name}',
                                    );
                                    return Container(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.business,
                                        size: 48,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.business,
                                    size: 48,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                          ],
                        ),
                      ),
                      // Building Info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    building.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (building.popularNames?.isNotEmpty ?? false)
                                  Tooltip(
                                    message:
                                        'Also known as: ${building.popularNames?.join(", ")}',
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                            if (building.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                building.description,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip(
                                  context,
                                  icon: Icons.info_outline,
                                  label: 'Building',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(BuildContext context) {
    return StreamBuilder<List<Room>>(
      stream: _buildingService.getRoomsForSearch(),
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
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snapshot.data ?? [];

        // Get all buildings for room-to-building name mapping
        return StreamBuilder<List<Building>>(
          stream: _buildingService.buildings,
          builder: (context, buildingSnapshot) {
            if (buildingSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${buildingSnapshot.error}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (buildingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final buildings = buildingSnapshot.data ?? [];
            final buildingMap = {
              for (var building in buildings) building.buildingId: building,
            };

            final filteredRooms =
                rooms.where((room) {
                  final name = room.name.toLowerCase();

                  // Apply search query filter
                  final matchesSearch = name.contains(_searchQuery);

                  return matchesSearch;
                }).toList();

            if (filteredRooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No rooms found matching your criteria'
                          : 'No rooms available',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                final room = filteredRooms[index];
                final building = buildingMap[room.buildingId];
                final floorLevel = _formatFloorLevel(room.floorId);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.room,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(room.name),
                    subtitle: Text(
                      '${building?.name ?? 'Unknown Building'} - Floor Level: $floorLevel',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RoomInstructionsScreen(room: room),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatFloorLevel(String floorId) {
    final direct = int.tryParse(floorId);
    if (direct != null) {
      return direct.toString();
    }

    final match = RegExp(r'\d+').firstMatch(floorId);
    if (match != null) {
      return match.group(0)!;
    }

    return floorId.isNotEmpty ? floorId : 'Unknown';
  }
}
