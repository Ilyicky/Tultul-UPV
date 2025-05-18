import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tultul_upv/services/storage_service.dart';
import 'package:tultul_upv/services/building_service.dart';
import 'package:tultul_upv/models/building.dart';

class BuildingImageScreen extends StatefulWidget {
  final Building building;

  const BuildingImageScreen({super.key, required this.building});

  @override
  State<BuildingImageScreen> createState() => _BuildingImageScreenState();
}

class _BuildingImageScreenState extends State<BuildingImageScreen> {
  final StorageService _storageService = StorageService();
  final BuildingService _buildingService = BuildingService();
  bool _isLoading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _isLoading = true);

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Upload image
      final imageFile = File(image.path);
      final downloadUrl = await _storageService.uploadBuildingImage(
        widget.building.buildingId,
        imageFile,
      );

      // Update building document with new image URL
      await _buildingService.updateBuildingImage(
        widget.building.buildingId,
        downloadUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteImage() async {
    if (widget.building.imageUrl == null || widget.building.imageUrl!.isEmpty) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Delete image from storage
      await _storageService.deleteBuildingImage(widget.building.imageUrl!);

      // Update building document to remove image URL
      await _buildingService.updateBuildingImage(
        widget.building.buildingId,
        '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Building Image')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.building.imageUrl != null &&
                        widget.building.imageUrl!.isNotEmpty)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.building.imageUrl!,
                              fit: BoxFit.cover,
                              height: 300,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
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
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  height: 300,
                                  child: Center(child: Icon(Icons.error)),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _deleteImage,
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Image'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No image available',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(
                        widget.building.imageUrl != null &&
                                widget.building.imageUrl!.isNotEmpty
                            ? 'Change Image'
                            : 'Add Image',
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
