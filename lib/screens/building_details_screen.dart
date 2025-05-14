import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/building.dart';
import '../models/floor_map.dart';
import '../services/building_service.dart';
import '../providers/user_provider.dart';
import 'rooms_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class BuildingDetailsScreen extends StatefulWidget {
  final Building building;

  const BuildingDetailsScreen({super.key, required this.building});

  @override
  State<BuildingDetailsScreen> createState() => _BuildingDetailsScreenState();
}

class _BuildingDetailsScreenState extends State<BuildingDetailsScreen> {
  final BuildingService _buildingService = BuildingService();
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic('dq0tsf6xm', 'ml_default', cache: false);

  Future<void> _editField(BuildContext context, String title, String currentValue, Function(String) onSave) async {
    final controller = TextEditingController(text: currentValue);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter new $title'),
          maxLines: title == 'Description' ? 3 : 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              
              // Don't update if the value hasn't changed
              if (newValue == currentValue) {
                Navigator.pop(context);
                return;
              }

              // Check for duplicate name if editing building name
              if (title == 'Name') {
                final buildings = await _buildingService.getBuildings();
                final exists = buildings.any((b) => 
                  b.buildingId != widget.building.buildingId && 
                  b.name.toLowerCase() == newValue.toLowerCase()
                );
                
                if (exists) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('A building with the name "$newValue" already exists'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }

              await onSave(newValue);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title updated from "$currentValue" to "$newValue"'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editBuildingImage(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading building image...')),
          );
        }

        final file = File(image.path);
        
        // Upload to Cloudinary
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            folder: 'buildings/${widget.building.buildingId}',
          ),
        );

        final oldImageUrl = widget.building.imageUrl;
        await _buildingService.updateBuilding(
          widget.building.buildingId,
          {'image_url': response.secureUrl},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(oldImageUrl == null || oldImageUrl.isEmpty
                ? 'Building image added successfully'
                : 'Building image updated successfully'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading building image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error uploading building image: $e');
    }
  }

  Future<void> _editFloorMapImage(BuildContext context, FloorMap floorMap) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading floor map image...')),
          );
        }

        final file = File(image.path);
        
        // Upload to Cloudinary
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            folder: 'buildings/${widget.building.buildingId}/floors/${floorMap.floorId}',
          ),
        );

        final hadExistingImage = floorMap.image.isNotEmpty;
        await _buildingService.updateFloorMapImage(
          widget.building.buildingId, 
          floorMap.floorId, 
          response.secureUrl
        );

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(hadExistingImage
                ? 'Floor ${floorMap.floorLevel} image updated successfully'
                : 'Floor ${floorMap.floorLevel} image added successfully'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading floor map image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error uploading floor map image: $e');
    }
  }

  Future<void> _deleteFloorMapImage(FloorMap floorMap) async {
    try {
      if (floorMap.image.isNotEmpty) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleting floor map image...')),
          );
        }

        // For Cloudinary, we just need to update the database
        // The old image will be automatically cleaned up by Cloudinary's admin settings
        await _buildingService.updateFloorMapImage(widget.building.buildingId, floorMap.floorId, '');

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Floor ${floorMap.floorLevel} image deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting floor ${floorMap.floorLevel} image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error deleting floor map image: $e');
    }
  }

  Future<void> _createFloorMap(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    int floorLevel = 1;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Floor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Floor Level *'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => floorLevel = int.tryParse(value ?? '1') ?? 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        formKey.currentState?.save();
                        
                        // Check if floor level already exists
                        final exists = await _buildingService.isFloorLevelExists(
                          widget.building.buildingId,
                          floorLevel,
                        );
                        
                        if (exists) {
                          if (mounted) {
                            // Show error dialog above the current dialog
                            await showDialog(
                              context: context,
                              barrierColor: Colors.black54,
                              builder: (context) => Dialog(
                                child: Container(
                                  width: 300,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.error, color: Colors.white, size: 20),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Error', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Floor level $floorLevel already exists',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        final floorId = await _buildingService.createFloorMap(
                          widget.building.buildingId,
                          {
                            'floor_level': floorLevel,
                            'image_url': '',
                          },
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Floor $floorLevel successfully created!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required BuildContext context,
    required String label,
    required String value,
    required Function(String) onEdit,
    bool multiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                  maxLines: multiLine ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editField(context, label, value, onEdit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<UserProvider>().user?.isAdmin() ?? false;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<Building>(
          stream: _buildingService.getBuildingStream(widget.building.buildingId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final building = snapshot.data ?? widget.building;
            return Text(building.name);
          },
        ),
        actions: isAdmin ? [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editBuildingImage(context),
          ),
        ] : null,
      ),
      body: StreamBuilder<Building>(
        stream: _buildingService.getBuildingStream(widget.building.buildingId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final building = snapshot.data ?? widget.building;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (building.imageUrl != null && building.imageUrl!.isNotEmpty)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.network(
                        building.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 50),
                              ),
                            ),
                      ),
                      if (isAdmin)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Colors.white,
                                onPressed: () => _editBuildingImage(context),
                              ),
                              if (building.imageUrl != null && building.imageUrl!.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.white,
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Image'),
                                        content: const Text('Are you sure you want to delete this image?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await _buildingService.updateBuilding(
                                        building.buildingId,
                                        {'image_url': ''},
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                  )
                else if (isAdmin)
                  InkWell(
                    onTap: () => _editBuildingImage(context),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50),
                            SizedBox(height: 8),
                            Text('Add Building Image'),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAdmin) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Building Information',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                _buildEditableField(
                                  context: context,
                                  label: 'Name',
                                  value: building.name,
                                  onEdit: (value) => _buildingService.updateBuilding(
                                    building.buildingId,
                                    {'name': value},
                                  ),
                                ),
                                _buildEditableField(
                                  context: context,
                                  label: 'Also known as',
                                  value: building.popular_names?.join(', ') ?? '',
                                  onEdit: (value) => _buildingService.updateBuilding(
                                    building.buildingId,
                                    {
                                      'popular_names': value.isEmpty 
                                          ? [] 
                                          : value.split(',').map((e) => e.trim()).toList(),
                                    },
                                  ),
                                ),
                                _buildEditableField(
                                  context: context,
                                  label: 'College',
                                  value: building.college,
                                  onEdit: (value) => _buildingService.updateBuilding(
                                    building.buildingId,
                                    {'college': value},
                                  ),
                                ),
                                _buildEditableField(
                                  context: context,
                                  label: 'Address',
                                  value: building.address,
                                  onEdit: (value) => _buildingService.updateBuilding(
                                    building.buildingId,
                                    {'address': value},
                                  ),
                                ),
                                _buildEditableField(
                                  context: context,
                                  label: 'Description',
                                  value: building.description,
                                  onEdit: (value) => _buildingService.updateBuilding(
                                    building.buildingId,
                                    {'description': value},
                                  ),
                                  multiLine: true,
                                ),
                                _buildEditableField(
                                  context: context,
                                  label: 'Status',
                                  value: building.status,
                                  onEdit: (value) => _buildingService.updateBuilding(
                                    building.buildingId,
                                    {'status': value},
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          building.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (building.popular_names?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Also known as: ${building.popular_names!.join(', ')}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          building.college,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(building.address),
                        const SizedBox(height: 16),
                        Text(
                          building.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              building.status.toLowerCase() == 'active'
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: building.status.toLowerCase() == 'active'
                                  ? Colors.green
                                  : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              building.status,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Floor Maps',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<FloorMap>>(
                        stream: _buildingService.getFloorMaps(widget.building.buildingId),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final floors = snapshot.data ?? [];
                          if (floors.isEmpty) {
                            return const Text('No floor maps available');
                          }

                          floors.sort((a, b) => a.floorLevel.compareTo(b.floorLevel));

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: floors.length,
                            itemBuilder: (context, index) {
                              final floor = floors[index];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.layers),
                                  title: Text('Floor ${floor.floorLevel}'),
                                  trailing: isAdmin
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () async {
                                                final confirmed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Delete Floor'),
                                                    content: const Text('Are you sure you want to delete this floor? This will also delete all rooms and instructions associated with this floor.'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, true),
                                                        child: const Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirmed == true) {
                                                  await _buildingService.deleteFloorMap(
                                                    widget.building.buildingId,
                                                    floor.floorId,
                                                  );
                                                }
                                              },
                                            ),
                                            const Icon(Icons.chevron_right),
                                          ],
                                        )
                                      : const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RoomsScreen(
                                          building: widget.building,
                                          floorMap: floor,
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () => _createFloorMap(context),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
} 