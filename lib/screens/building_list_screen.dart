import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/building.dart';
import '../services/building_service.dart';
import '../providers/user_provider.dart';
import 'package:tultul_upv/screens/buildings/details/building_details_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class BuildingListScreen extends StatefulWidget {
  const BuildingListScreen({super.key});

  @override
  State<BuildingListScreen> createState() => _BuildingListScreenState();
}

class _BuildingListScreenState extends State<BuildingListScreen> {
  final BuildingService _buildingService = BuildingService();
  String _searchQuery = '';
  final ImagePicker _picker = ImagePicker();
  // Initialize Cloudinary with the standard ml_default preset
  final cloudinary = CloudinaryPublic('dq0tsf6xm', 'ml_default', cache: false);

  Future<void> _editField(
    BuildContext context,
    String title,
    String currentValue,
    Function(String) onSave,
  ) async {
    final controller = TextEditingController(text: currentValue);
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                onPressed: () {
                  onSave(controller.text);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _editImage(BuildContext context, Building building) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        final file = File(image.path);

        // Show loading indicator
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Uploading image...')));

        try {
          // Upload to Cloudinary
          final response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(file.path, folder: 'buildings'),
          );

          // Update building with new image URL
          await _buildingService.updateBuildingImage(
            building.buildingId,
            response.secureUrl,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image updated successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            String errorMessage = 'Failed to upload image';

            // Get more detailed error information
            if (e.toString().contains('400')) {
              errorMessage +=
                  ': Invalid upload preset. Please check Cloudinary configuration.';
            } else if (e.toString().contains('401')) {
              errorMessage +=
                  ': Unauthorized. Please check Cloudinary credentials.';
            } else if (e.toString().contains('413')) {
              errorMessage += ': Image file too large.';
            } else {
              errorMessage += ': ${e.toString()}';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          print('Error uploading image: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error picking image: $e');
    }
  }

  Future<void> _deleteImage(Building building) async {
    if (building.imageUrl != null && building.imageUrl!.isNotEmpty) {
      try {
        // For Cloudinary, we just need to update the building record
        // The old image will be automatically cleaned up by Cloudinary's admin settings
        await _buildingService.updateBuildingImage(building.buildingId, '');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image removed successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove image: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('Error removing image: $e');
      }
    }
  }

  Future<void> _createBuilding(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String popularNames = '';
    String college = '';
    String address = '';
    String description = '';
    double? latitude;
    double? longitude;
    String? imageUrl;

    Future<void> pickImage() async {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024, // Optimize image size
          imageQuality: 85, // Maintain good quality while reducing size
        );
        if (image != null) {
          final file = File(image.path);

          // Show loading indicator
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Uploading image...')));

          try {
            // Upload to Cloudinary
            final response = await cloudinary.uploadFile(
              CloudinaryFile.fromFile(
                file.path,
                folder: 'buildings', // Store in a specific folder
              ),
            );

            // Get the secure URL
            imageUrl = response.secureUrl;

            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image uploaded successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              String errorMessage = 'Failed to upload image';

              // Get more detailed error information
              if (e.toString().contains('400')) {
                errorMessage +=
                    ': Invalid upload preset. Please check Cloudinary configuration.';
              } else if (e.toString().contains('401')) {
                errorMessage +=
                    ': Unauthorized. Please check Cloudinary credentials.';
              } else if (e.toString().contains('413')) {
                errorMessage += ': Image file too large.';
              } else {
                errorMessage += ': ${e.toString()}';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            print('Error uploading image: $e');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error picking image: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('Error picking image: $e');
      }
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Building'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator:
                          (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => name = value ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Popular Names',
                        helperText: 'Comma-separated names',
                      ),
                      onSaved: (value) => popularNames = value ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'College *'),
                      validator:
                          (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => college = value ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Address *'),
                      validator:
                          (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => address = value ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                      onSaved: (value) => description = value ?? '',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                            ),
                            keyboardType: TextInputType.number,
                            onSaved:
                                (value) =>
                                    latitude = double.tryParse(value ?? ''),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                            ),
                            keyboardType: TextInputType.number,
                            onSaved:
                                (value) =>
                                    longitude = double.tryParse(value ?? ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Upload Image'),
                    ),
                    if (imageUrl != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Image uploaded',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    formKey.currentState?.save();
                    final buildingId = await _buildingService.createBuilding({
                      'name': name,
                      'popular_names':
                          popularNames.isEmpty
                              ? []
                              : popularNames
                                  .split(',')
                                  .map((e) => e.trim())
                                  .toList(),
                      'college': college,
                      'address': address,
                      'description': description,
                      'latitude': latitude,
                      'longitude': longitude,
                      'status': 'Active',
                      'image_url': imageUrl ?? '',
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Building created successfully'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required Function(String) onEdit,
    bool multiLine = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(height: 1.5),
            maxLines: multiLine ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editField(context, label, value, onEdit),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<UserProvider>().user?.isAdmin() ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Buildings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search buildings...',
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
          Expanded(
            child: StreamBuilder<List<Building>>(
              stream: _buildingService.buildings,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final buildings = snapshot.data ?? [];
                final filteredBuildings =
                    buildings.where((building) {
                      final name = building.name.toLowerCase();
                      final popularNames =
                          building.popular_names?.join(' ').toLowerCase() ?? '';
                      final college = building.college.toLowerCase();
                      return name.contains(_searchQuery) ||
                          popularNames.contains(_searchQuery) ||
                          college.contains(_searchQuery);
                    }).toList();
                if (filteredBuildings.isEmpty) {
                  return const Center(child: Text('No buildings found'));
                }
                final itemCount =
                    isAdmin
                        ? filteredBuildings.length + 1
                        : filteredBuildings.length;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (isAdmin && index == filteredBuildings.length) {
                      // Add button at the end for admins
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
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child:
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
                        ),
                        title: Text(
                          building.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        trailing: const Icon(Icons.chevron_right),
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
            ),
          ),
        ],
      ),
    );
  }
}
