import 'package:flutter/material.dart';
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/services/building_service.dart';
import 'package:tultul_upv/screens/buildings/details/building_details_screen.dart';
import 'package:tultul_upv/models/room.dart';
import 'package:tultul_upv/screens/rooms/room_instructions_screen.dart';
import 'package:provider/provider.dart';
import 'package:tultul_upv/providers/user_provider.dart';
import 'package:photo_view/photo_view.dart';

class BuildingsListScreen extends StatefulWidget {
  const BuildingsListScreen({super.key});

  @override
  State<BuildingsListScreen> createState() => _BuildingsListScreenState();
}

class _BuildingsListScreenState extends State<BuildingsListScreen> {
  final BuildingService _buildingService = BuildingService();
  String _searchQuery = '';
  String _filter = 'Buildings';
  List<String> _filters = ['Buildings', 'Rooms'];

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<UserProvider>().user?.isAdmin() ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
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
                              setState(() {
                                _filter = f;
                              });
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText:
                    _filter == 'Buildings'
                        ? 'Search buildings...'
                        : 'Search rooms...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          if (_filter == 'Buildings')
            Expanded(
              child: StreamBuilder<List<Building>>(
                stream: _buildingService.buildings,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final buildings = snapshot.data ?? [];
                  final filteredBuildings =
                      buildings.where((building) {
                        final name = building.name.toLowerCase();
                        final popularNames =
                            building.popular_names?.join(' ').toLowerCase() ??
                            '';
                        final college = building.college.toLowerCase();
                        return name.contains(_searchQuery) ||
                            popularNames.contains(_searchQuery) ||
                            college.contains(_searchQuery);
                      }).toList();

                  if (filteredBuildings.isEmpty) {
                    return const Center(child: Text('No buildings found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount:
                        isAdmin
                            ? filteredBuildings.length + 1
                            : filteredBuildings.length,
                    itemBuilder: (context, index) {
                      if (isAdmin && index == filteredBuildings.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _createBuilding(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Building'),
                            ),
                          ),
                        );
                      }

                      final building = filteredBuildings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading:
                              building.imageUrl != null &&
                                      building.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      building.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.business,
                                                size: 50,
                                              ),
                                    ),
                                  )
                                  : const Icon(Icons.business, size: 50),
                          title: Text(
                            building.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [const Icon(Icons.chevron_right)],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BuildingDetailsScreen(
                                      building: building,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            )
          else
            Expanded(
              child: StreamBuilder<List<Room>>(
                stream: _buildingService.getRoomsForSearch(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rooms = snapshot.data ?? [];
                  final filteredRooms =
                      rooms.where((room) {
                        final name = room.name.toLowerCase();
                        final type = room.type.toLowerCase();
                        return name.contains(_searchQuery) ||
                            type.contains(_searchQuery);
                      }).toList();
                  if (filteredRooms.isEmpty) {
                    return const Center(child: Text('No rooms found'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Icon(
                            _getRoomIcon(room.type),
                            color: _getRoomColor(room.status),
                          ),
                          title: Text(room.name),
                          subtitle: Text('${room.type} (${room.status})'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        RoomInstructionsScreen(room: room),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  IconData _getRoomIcon(String type) {
    switch (type.toLowerCase()) {
      case 'classroom':
        return Icons.school;
      case 'laboratory':
        return Icons.science;
      case 'office':
        return Icons.business;
      case 'bathroom':
        return Icons.wc;
      case 'storage':
        return Icons.inventory;
      default:
        return Icons.room;
    }
  }

  Color _getRoomColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _createBuilding(BuildContext context) {
    // Implementation of _createBuilding method
  }

  void _editBuilding(BuildContext context, Building building) {
    // Implementation of _editBuilding method
  }

  void _deleteBuilding(BuildContext context, Building building) {
    // Implementation of _deleteBuilding method
  }
}
