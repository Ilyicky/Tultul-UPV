import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/room_instruction.dart';
import '../services/building_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class RoomInstructionsScreen extends StatefulWidget {
  final Room room;

  const RoomInstructionsScreen({
    super.key,
    required this.room,
  });

  @override
  State<RoomInstructionsScreen> createState() => _RoomInstructionsScreenState();
}

class _RoomInstructionsScreenState extends State<RoomInstructionsScreen> {
  final BuildingService _buildingService = BuildingService();
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic('dq0tsf6xm', 'ml_default', cache: false);

  Future<void> _addInstruction(BuildContext context) async {
    final textController = TextEditingController();
    List<String> imageUrls = [];

    Future<void> pickImage() async {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          imageQuality: 85,
        );
        if (image != null) {
          final file = File(image.path);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading image...')),
          );

          try {
            final response = await cloudinary.uploadFile(
              CloudinaryFile.fromFile(
                file.path,
                folder: 'room_instructions',
              ),
            );
            imageUrls.add(response.secureUrl);
            
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image uploaded successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload image: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
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
      }
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Instruction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Instruction Text',
                  hintText: 'Enter the instruction...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Image'),
              ),
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${imageUrls.length} image(s) added'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                // Get the current count of instructions for ordering
                final instructions = await _buildingService.getRoomInstructions(
                  widget.room.buildingId,
                  widget.room.floorId,
                  widget.room.roomId,
                ).first;
                
                await _buildingService.createRoomInstruction(
                  widget.room.buildingId,
                  widget.room.floorId,
                  widget.room.roomId,
                  {
                    'text': textController.text,
                    'image_urls': imageUrls,
                    'order': instructions.length,
                  },
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
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
        title: Text('${widget.room.name} Instructions'),
      ),
      body: StreamBuilder<List<RoomInstruction>>(
        stream: _buildingService.getRoomInstructions(
          widget.room.buildingId,
          widget.room.floorId,
          widget.room.roomId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final instructions = snapshot.data ?? [];
          instructions.sort((a, b) => a.order.compareTo(b.order));

          if (instructions.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center(child: Text('No instructions available')),
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _addInstruction(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Instruction'),
                      ),
                    ),
                  ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: isAdmin ? instructions.length + 1 : instructions.length,
            itemBuilder: (context, index) {
              if (isAdmin && index == instructions.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _addInstruction(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Instruction'),
                    ),
                  ),
                );
              }
              final instruction = instructions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (instruction.imageUrls.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: instruction.imageUrls.length,
                          itemBuilder: (context, imageIndex) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  instruction.imageUrls[imageIndex],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        instruction.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (isAdmin)
                      ButtonBar(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            onPressed: () async {
                              // Edit dialog
                              final textController = TextEditingController(text: instruction.text);
                              List<String> imageUrls = List.from(instruction.imageUrls);
                              Future<void> pickImage() async {
                                try {
                                  final XFile? image = await _picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1024,
                                    imageQuality: 85,
                                  );
                                  if (image != null) {
                                    final file = File(image.path);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Uploading image...')),
                                    );
                                    try {
                                      final response = await cloudinary.uploadFile(
                                        CloudinaryFile.fromFile(
                                          file.path,
                                          folder: 'room_instructions',
                                        ),
                                      );
                                      imageUrls.add(response.secureUrl);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Image uploaded successfully')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to upload image: \\${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error picking image: \\${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Instruction'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: textController,
                                          decoration: const InputDecoration(
                                            labelText: 'Instruction Text',
                                            hintText: 'Enter the instruction...',
                                          ),
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: pickImage,
                                          icon: const Icon(Icons.add_photo_alternate),
                                          label: const Text('Add Image'),
                                        ),
                                        if (imageUrls.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 100,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: imageUrls.length,
                                              itemBuilder: (context, idx) {
                                                return SizedBox(
                                                  width: 110,
                                                  child: Stack(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.all(4.0),
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(8),
                                                          child: Image.network(
                                                            imageUrls[idx],
                                                            fit: BoxFit.cover,
                                                            width: 100,
                                                            height: 100,
                                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 0,
                                                        right: 0,
                                                        child: IconButton(
                                                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                                          onPressed: () {
                                                            imageUrls.removeAt(idx);
                                                            setState(() {});
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (textController.text.isNotEmpty) {
                                          await _buildingService.updateRoomInstruction(
                                            widget.room.buildingId,
                                            widget.room.floorId,
                                            widget.room.roomId,
                                            instruction.id,
                                            {
                                              'text': textController.text,
                                              'image_urls': imageUrls,
                                            },
                                          );
                                          if (mounted) Navigator.pop(context);
                                        }
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Instruction'),
                                  content: const Text('Are you sure you want to delete this instruction?'),
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
                                await _buildingService.deleteRoomInstruction(
                                  widget.room.buildingId,
                                  widget.room.floorId,
                                  widget.room.roomId,
                                  instruction.id,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 