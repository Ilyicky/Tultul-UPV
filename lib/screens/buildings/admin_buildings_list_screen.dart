import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/models/room.dart';
import 'package:tultul_upv/services/building_service.dart';
import 'package:tultul_upv/viewmodels/buildings/admin_buildings_viewmodel.dart';
import 'package:tultul_upv/widgets/buildings/building_form.dart';
import 'package:tultul_upv/screens/buildings/details/building_details_screen.dart';
import 'package:tultul_upv/screens/rooms/room_instructions_screen.dart';

class AdminBuildingsListScreen extends StatelessWidget {
  const AdminBuildingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminBuildingsViewModel(BuildingService()),
      child: const _AdminBuildingsListScreenContent(),
    );
  }
}

class _AdminBuildingsListScreenContent extends StatelessWidget {
  const _AdminBuildingsListScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminBuildingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateBuildingDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(context),
          _buildSearchField(context),
          Expanded(
            child: viewModel.filter == 'Buildings'
                ? _buildBuildingsList(context)
                : _buildRoomsList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBuildingDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final viewModel = context.watch<AdminBuildingsViewModel>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: viewModel.filters.map((f) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ChoiceChip(
            label: Text(f),
            selected: viewModel.filter == f,
            onSelected: (selected) => viewModel.updateFilter(f),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final viewModel = context.watch<AdminBuildingsViewModel>();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: viewModel.filter == 'Buildings' 
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
        onChanged: viewModel.updateSearchQuery,
      ),
    );
  }

  Widget _buildBuildingsList(BuildContext context) {
    final viewModel = context.watch<AdminBuildingsViewModel>();

    return StreamBuilder<List<Building>>(
      stream: viewModel.buildings,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final buildings = viewModel.filterBuildings(snapshot.data ?? []);

        if (buildings.isEmpty) {
          return const Center(child: Text('No buildings found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final building = buildings[index];
            return _BuildingListItem(building: building);
          },
        );
      },
    );
  }

  Widget _buildRoomsList(BuildContext context) {
    final viewModel = context.watch<AdminBuildingsViewModel>();

    return StreamBuilder<List<Room>>(
      stream: viewModel.rooms,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = viewModel.filterRooms(snapshot.data ?? []);

        if (rooms.isEmpty) {
          return const Center(child: Text('No rooms found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _RoomListItem(room: room);
          },
        );
      },
    );
  }

  void _showCreateBuildingDialog(BuildContext context) {
    final viewModel = context.read<AdminBuildingsViewModel>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Building'),
        content: BuildingForm(
          onSubmit: (data) async {
            try {
              await viewModel.createBuilding(data);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Building created successfully')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating building: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _BuildingListItem extends StatelessWidget {
  final Building building;

  const _BuildingListItem({required this.building});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: ListTile(
        leading: building.imageUrl != null && building.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  building.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.business, size: 50),
                ),
              )
            : const Icon(Icons.business, size: 50),
        title: Text(
          building.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(building.college),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editBuilding(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteBuilding(context),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BuildingDetailsScreen(
                building: building,
              ),
            ),
          );
        },
      ),
    );
  }

  void _editBuilding(BuildContext context) {
    // TODO: Implement building editing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Building'),
        content: Text('Edit form for ${building.name} will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement building editing logic
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteBuilding(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Building'),
        content: Text('Are you sure you want to delete ${building.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement building deletion logic
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RoomListItem extends StatelessWidget {
  final Room room;

  const _RoomListItem({required this.room});

  @override
  Widget build(BuildContext context) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editRoom(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteRoom(context),
            ),
            const Icon(Icons.chevron_right),
          ],
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

  void _editRoom(BuildContext context) {
    // TODO: Implement room editing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Room'),
        content: Text('Edit form for ${room.name} will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement room editing logic
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteRoom(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete ${room.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement room deletion logic
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 