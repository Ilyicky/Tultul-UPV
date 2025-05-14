import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/building.dart';
import '../models/floor_map.dart';
import '../models/room.dart';
import '../models/room_instruction.dart';

class BuildingService {
  final CollectionReference buildingsCollection = FirebaseFirestore.instance
      .collection('buildings');

  Stream<List<Building>> get buildings {
    return buildingsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          if (doc.id.isEmpty) {
            print('Warning: Empty document ID encountered');
            return null;
          }
          return Building.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        } catch (e) {
          print('Error creating Building from document ${doc.id}: $e');
          return null;
        }
      }).whereType<Building>().toList();
    });
  }

  Stream<List<Building>> getBookmarkedBuildings(List<String> buildingIds) {
    if (buildingIds.isEmpty) {
      return Stream.value([]);
    }
    
    return buildingsCollection
        .where(FieldPath.documentId, whereIn: buildingIds)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Building.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Future<List<Building>> getBuildings() async {
    final snapshot = await buildingsCollection.get();
    return snapshot.docs.map((doc) {
      return Building.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Stream<List<FloorMap>> getFloorMaps(String buildingId) {
    return buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FloorMap.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Stream<List<Room>> getRooms(String buildingId, String floorId) {
    if (buildingId.isEmpty || floorId.isEmpty) {
      return Stream.value([]);
    }
    
    return buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .collection('rooms')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Room.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Future<void> updateBuildingImage(String buildingId, String imageUrl) async {
    await buildingsCollection.doc(buildingId).update({
      'image_url': imageUrl,
    });
  }

  Future<void> updateBuilding(String buildingId, Map<String, dynamic> data) async {
    if (buildingId.isEmpty) {
      throw ArgumentError('Building ID cannot be empty');
    }
    await buildingsCollection.doc(buildingId).update(data);
  }

  Future<void> updateFloorMap(String buildingId, String floorId, Map<String, dynamic> data) async {
    await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .update(data);
  }

  Future<void> updateFloorMapImage(String buildingId, String floorId, String imageUrl) async {
    await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .update({'image_url': imageUrl});
  }

  Future<void> updateRoom(String buildingId, String floorId, String roomId, Map<String, dynamic> data) async {
    if (buildingId.isEmpty || floorId.isEmpty || roomId.isEmpty) {
      throw ArgumentError('Building ID, Floor ID, and Room ID cannot be empty');
    }
    
    await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .collection('rooms')
        .doc(roomId)
        .update(data);
  }

  Stream<List<RoomInstruction>> getRoomInstructions(String buildingId, String floorId, String roomId) {
    if (buildingId.isEmpty || floorId.isEmpty || roomId.isEmpty) {
      return Stream.value([]);
    }
    
    return buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .collection('rooms')
        .doc(roomId)
        .collection('instructions')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return RoomInstruction.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Future<String> createBuilding(Map<String, dynamic> data) async {
    final docRef = await buildingsCollection.add({
      'name': data['name'] ?? '',
      'popular_names': data['popular_names'] ?? [],
      'description': data['description'] ?? '',
      'college': data['college'] ?? '',
      'address': data['address'] ?? '',
      'latitude': data['latitude'],
      'longitude': data['longitude'],
      'status': data['status'] ?? 'Active',
      'image_url': data['image_url'] ?? '',
    });
    return docRef.id;
  }

  Future<String> createFloorMap(String buildingId, Map<String, dynamic> data) async {
    final docRef = await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .add({
          'building_id': buildingId,
          'floor_level': data['floor_level'] ?? 1,
          'image_url': data['image_url'] ?? '',
          'description': data['description'] ?? '',
        });
    return docRef.id;
  }

  Future<String> createRoom(String buildingId, String floorId, Map<String, dynamic> data) async {
    if (buildingId.isEmpty || floorId.isEmpty) {
      throw ArgumentError('Building ID and Floor ID cannot be empty');
    }
    
    final docRef = await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .collection('rooms')
        .add({
          'building_id': buildingId,
          'floor_id': floorId,
          'name': data['name'] ?? '',
          'description': data['description'] ?? '',
          'type': data['type'] ?? '',
          'status': data['status'] ?? 'Active',
        });
    return docRef.id;
  }

  Future<String> createRoomInstruction(
    String buildingId,
    String floorId,
    String roomId,
    Map<String, dynamic> data,
  ) async {
    final docRef = await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .collection('rooms')
        .doc(roomId)
        .collection('instructions')
        .add(data);
    return docRef.id;
  }

  Future<void> updateRoomInstruction(
    String buildingId,
    String floorId,
    String roomId,
    String instructionId,
    Map<String, dynamic> data,
  ) async {
    await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .collection('rooms')
        .doc(roomId)
        .collection('instructions')
        .doc(instructionId)
        .update(data);
  }

  Future<void> deleteRoomInstruction(
    String buildingId,
    String floorId,
    String roomId,
    String instructionId,
  ) async {
    await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .collection('rooms')
        .doc(roomId)
        .collection('instructions')
        .doc(instructionId)
        .delete();
  }

  Future<void> initializeDefaultBuildings() async {
    final snapshot = await buildingsCollection.get();
    if (snapshot.docs.isEmpty) {
      // Add default buildings
      final defaultBuildings = [
        {
          'name': 'College of Engineering',
          'popular_names': ['Engineering Building', 'COE'],
          'description': 'Main building for engineering courses',
          'college': 'College of Engineering',
          'address': 'CPU Campus',
          'latitude': 10.7275,
          'longitude': 122.5453,
          'status': 'Active',
          'image_url': '',
        },
        {
          'name': 'College of Nursing',
          'popular_names': ['Nursing Building', 'CON'],
          'description': 'Main building for nursing courses',
          'college': 'College of Nursing',
          'address': 'CPU Campus',
          'latitude': 10.7280,
          'longitude': 122.5460,
          'status': 'Active',
          'image_url': '',
        },
      ];

      // Add buildings to Firestore
      for (final building in defaultBuildings) {
        await buildingsCollection.add(building);
      }
    }
  }

  Future<void> deleteFloorMap(String buildingId, String floorId) async {
    // Get reference to the floor map document
    final floorMapRef = buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId);

    // Get all rooms in this floor
    final roomsSnapshot = await floorMapRef.collection('rooms').get();

    // Delete all rooms and their instructions
    for (var roomDoc in roomsSnapshot.docs) {
      // Delete all instructions for this room
      final instructionsSnapshot = await roomDoc.reference.collection('instructions').get();
      for (var instructionDoc in instructionsSnapshot.docs) {
        await instructionDoc.reference.delete();
      }
      // Delete the room
      await roomDoc.reference.delete();
    }

    // Finally delete the floor map itself
    await floorMapRef.delete();
  }

  Future<void> deleteRoom(String buildingId, String floorId, String roomId) async {
    // Get reference to the room document
    final roomRef = buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .collection('rooms')
        .doc(roomId);

    // Delete all instructions for this room
    final instructionsSnapshot = await roomRef.collection('instructions').get();
    for (var instructionDoc in instructionsSnapshot.docs) {
      await instructionDoc.reference.delete();
    }

    // Delete the room itself
    await roomRef.delete();
  }

  Future<bool> isFloorLevelExists(String buildingId, int floorLevel) async {
    final querySnapshot = await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .where('floor_level', isEqualTo: floorLevel)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> isRoomNameExists(String buildingId, String floorId, String roomName, String roomType, {String? excludeRoomId}) async {
    // Get all rooms in the floor
    final querySnapshot = await buildingsCollection
        .doc(buildingId)
        .collection('floormaps')
        .doc(floorId)
        .collection('rooms')
        .get();

    // Check if any existing room has the same name (case-insensitive) AND type, excluding the current room if editing
    return querySnapshot.docs.any((doc) {
      if (excludeRoomId != null && doc.id == excludeRoomId) {
        return false; // Skip the current room when editing
      }
      final data = doc.data() as Map<String, dynamic>;
      final existingName = (data['name'] as String?)?.toUpperCase() ?? '';
      final existingType = (data['type'] as String?)?.toLowerCase() ?? '';
      return existingName == roomName.toUpperCase() && existingType == roomType.toLowerCase();
    });
  }

  Stream<Building> getBuildingStream(String buildingId) {
    return buildingsCollection
        .doc(buildingId)
        .snapshots()
        .map((doc) => Building.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ));
  }
}
