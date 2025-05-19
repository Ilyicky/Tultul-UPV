import 'package:flutter/material.dart';
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/services/building_service.dart';
import 'package:tultul_upv/screens/buildings/details/building_details_screen.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  final BuildingService _buildingService = BuildingService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final buildings = snapshot.data ?? [];
                buildings.sort((a, b) => a.name.compareTo(b.name));

                // Filter buildings based on search query
                final filteredBuildings =
                    buildings.where((building) {
                      final name = building.name.toLowerCase();
                      final popularNames =
                          building.popularNames?.join(' ').toLowerCase() ?? '';
                      final college = building.college.toLowerCase();
                      final description = building.description.toLowerCase();
                      return name.contains(_searchQuery) ||
                          popularNames.contains(_searchQuery) ||
                          college.contains(_searchQuery) ||
                          description.contains(_searchQuery);
                    }).toList();

                if (filteredBuildings.isEmpty) {
                  return const Center(child: Text('No buildings found'));
                }

                return ListView.builder(
                  itemCount: filteredBuildings.length,
                  itemBuilder: (context, index) {
                    final building = filteredBuildings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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
                                            const Icon(Icons.business),
                                  ),
                                )
                                : const Icon(Icons.business),
                        title: Text(building.name),
                        subtitle: Text(
                          building.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
