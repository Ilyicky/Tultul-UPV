import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/building.dart';
import '../models/floor_map.dart';
import '../models/room.dart';
import '../services/building_service.dart';
import '../providers/user_provider.dart';
import 'room_instructions_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:photo_view/photo_view.dart';

class RoomsScreen extends StatefulWidget {
  final Building building;
  final FloorMap floorMap;

  const RoomsScreen({
    super.key,
    required this.building,
    required this.floorMap,
  });

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
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

  Widget _buildEditableField({
    required BuildContext context,
    required String label,
    required String value,
    required Function(String) onEdit,
    bool multiLine = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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

  Future<void> _editRoom(BuildContext context, Room room) async {
    final formKey = GlobalKey<FormState>();
    String name = room.name;
    String type = room.type.toLowerCase();
    String status = room.status.toLowerCase();

    // Ensure type and status match available dropdown values
    if (!['classroom', 'laboratory', 'office', 'bathroom', 'storage', 'other'].contains(type)) {
      type = 'other';
    }
    if (!['active', 'inactive', 'maintenance'].contains(status)) {
      status = 'active';
    }

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
                'Edit Room',
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
                      initialValue: name,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => name = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type *'),
                      items: const [
                        DropdownMenuItem(value: 'classroom', child: Text('Classroom')),
                        DropdownMenuItem(value: 'laboratory', child: Text('Laboratory')),
                        DropdownMenuItem(value: 'office', child: Text('Office')),
                        DropdownMenuItem(value: 'bathroom', child: Text('Bathroom')),
                        DropdownMenuItem(value: 'storage', child: Text('Storage')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) => type = value ?? type,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status *'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                      ],
                      onChanged: (value) => status = value ?? status,
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

                        // Don't check if the name hasn't changed
                        if (name != room.name) {
                          // Check if room name already exists
                          final exists = await _buildingService.isRoomNameExists(
                            widget.building.buildingId,
                            widget.floorMap.floorId,
                            name,
                            type,
                            excludeRoomId: room.roomId,
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
                                          'A $type with the name "$name" already exists',
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
                        }

                        await _buildingService.updateRoom(
                          widget.building.buildingId,
                          widget.floorMap.floorId,
                          room.roomId,
                          {
                            'name': name,
                            'type': type,
                            'status': status,
                          },
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Room updated successfully')),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createRoom(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String type = 'classroom';
    String status = 'active';

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
                'Create New Room',
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
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => name = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type *'),
                      items: const [
                        DropdownMenuItem(value: 'classroom', child: Text('Classroom')),
                        DropdownMenuItem(value: 'laboratory', child: Text('Laboratory')),
                        DropdownMenuItem(value: 'office', child: Text('Office')),
                        DropdownMenuItem(value: 'bathroom', child: Text('Bathroom')),
                        DropdownMenuItem(value: 'storage', child: Text('Storage')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) => type = value ?? 'classroom',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status *'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                      ],
                      onChanged: (value) => status = value ?? 'active',
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
                        
                        // Check if room name already exists
                        final exists = await _buildingService.isRoomNameExists(
                          widget.building.buildingId,
                          widget.floorMap.floorId,
                          name,
                          type,
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
                                        'A $type with the name "$name" already exists',
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

                        final roomId = await _buildingService.createRoom(
                          widget.building.buildingId,
                          widget.floorMap.floorId,
                          {
                            'name': name,
                            'type': type,
                            'status': status,
                          },
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Room "$name" successfully created!'),
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

  Future<void> _deleteRoom(BuildContext context, Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete "${room.name}"? This will also delete all instructions associated with this room.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _buildingService.deleteRoom(
        widget.building.buildingId,
        widget.floorMap.floorId,
        room.roomId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room "${room.name}" successfully deleted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editFloorMapImage(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading floor map image...')),
          );
        }
        final file = File(image.path);
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            folder: 'buildings/${widget.building.buildingId}/floors/${widget.floorMap.floorId}',
          ),
        );
        final hadExistingImage = widget.floorMap.image.isNotEmpty;
        await _buildingService.updateFloorMapImage(
          widget.building.buildingId,
          widget.floorMap.floorId,
          response.secureUrl,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(hadExistingImage
                  ? 'Floor ${widget.floorMap.floorLevel} image updated successfully'
                  : 'Floor ${widget.floorMap.floorLevel} image added successfully'),
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
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<UserProvider>().user?.isAdmin() ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Floor ${widget.floorMap.floorLevel} Rooms'),
      ),
      body: StreamBuilder<List<Room>>(
        stream: _buildingService.getRooms(
          widget.building.buildingId,
          widget.floorMap.floorId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data ?? [];

          return Column(
            children: [
              if (widget.floorMap.image.isNotEmpty)
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.floorMap.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Eye, Edit, Delete icons at the top right
                    Positioned(
                      top: 24,
                      right: 32,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye, color: Colors.white, size: 28),
                            tooltip: 'View Fullscreen',
                            onPressed: () => _showFullScreenImage(context, widget.floorMap.image),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 28),
                            tooltip: 'Edit Floor Map Image',
                            onPressed: () => _editFloorMapImage(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 28),
                            tooltip: 'Delete Floor Map Image',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Floor Map Image'),
                                  content: const Text('Are you sure you want to delete this floor map image?'),
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
                                await _buildingService.updateFloorMapImage(
                                  widget.building.buildingId,
                                  widget.floorMap.floorId,
                                  '',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Floor map image deleted successfully'), backgroundColor: Colors.green),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else if (isAdmin)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () => _editFloorMapImage(context),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50),
                          SizedBox(height: 8),
                          Text('Add Floor Map'),
                        ],
                      ),
                    ),
                  ),
                ),
              if (rooms.isEmpty)
                const Expanded(
                  child: Center(child: Text('No rooms available')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: isAdmin ? rooms.length + 1 : rooms.length,
                    itemBuilder: (context, index) {
                      if (isAdmin && index == rooms.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _createRoom(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Room'),
                            ),
                          ),
                        );
                      }
                      final room = rooms[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            _getRoomIcon(room.type),
                            color: _getRoomColor(room.status),
                          ),
                          title: Text(room.name),
                          subtitle: Text(room.type),
                          trailing: isAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editRoom(context, room),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteRoom(context, room),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoomInstructionsScreen(
                                  room: room,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 