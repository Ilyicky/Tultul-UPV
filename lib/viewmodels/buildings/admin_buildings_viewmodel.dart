import 'package:flutter/material.dart';
import 'package:tultul_upv/models/building.dart';
import 'package:tultul_upv/models/room.dart';
import 'package:tultul_upv/services/building_service.dart';

class AdminBuildingsViewModel extends ChangeNotifier {
  final BuildingService _buildingService;
  String _searchQuery = '';
  String _filter = 'Buildings';
  List<String> _filters = ['Buildings', 'Rooms'];
  bool _isLoading = false;
  String? _error;

  AdminBuildingsViewModel(this._buildingService);

  // Getters
  String get searchQuery => _searchQuery;
  String get filter => _filter;
  List<String> get filters => _filters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Stream<List<Building>> get buildings => _buildingService.buildings;
  Stream<List<Room>> get rooms => _buildingService.getRoomsForSearch();

  // Methods
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void updateFilter(String newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  Future<String> createBuilding(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final buildingId = await _buildingService.createBuilding(data);
      
      _isLoading = false;
      notifyListeners();
      return buildingId;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBuilding(String buildingId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: Implement delete building logic
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBuilding(String buildingId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _buildingService.updateBuilding(buildingId, data);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  List<Building> filterBuildings(List<Building> buildings) {
    return buildings.where((building) {
      final name = building.name.toLowerCase();
      final popularNames = building.popularNames?.join(' ').toLowerCase() ?? '';
      final college = building.college.toLowerCase();
      return name.contains(_searchQuery) ||
          popularNames.contains(_searchQuery) ||
          college.contains(_searchQuery);
    }).toList();
  }

  List<Room> filterRooms(List<Room> rooms) {
    return rooms.where((room) {
      final name = room.name.toLowerCase();
      final type = room.type.toLowerCase();
      return name.contains(_searchQuery) || type.contains(_searchQuery);
    }).toList();
  }
} 