import 'package:flutter/material.dart';
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/screens/buildings/details/building_details_screen.dart';
import 'package:tultul_upv/widgets/building_form.dart';

class AdminBuildingListItem extends StatelessWidget {
  final Building building;

  const AdminBuildingListItem({super.key, required this.building});

  @override
  Widget build(BuildContext context) {
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
              builder: (context) => BuildingDetailsScreen(building: building),
            ),
          );
        },
      ),
    );
  }

  void _editBuilding(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Building'),
            content: BuildingForm(
              initialData: building.toMap(),
              onSubmit: (data) async {
                try {
                  // TODO: Implement building update logic
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Building updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating building: $e'),
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

  void _deleteBuilding(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Building'),
            content: Text('Are you sure you want to delete ${building.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // TODO: Implement building deletion logic
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Building deleted successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting building: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

class UserBuildingListItem extends StatelessWidget {
  final Building building;

  const UserBuildingListItem({super.key, required this.building});

  @override
  Widget build(BuildContext context) {
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
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BuildingDetailsScreen(building: building),
            ),
          );
        },
      ),
    );
  }
}
