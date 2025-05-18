import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String roomId;
  final String buildingId;
  final String floorId;
  final String name;
  final String type; // classroom, laboratory, office, etc.
  final String status;

  Room({
    required this.roomId,
    required this.buildingId,
    required this.floorId,
    required this.name,
    required this.type,
    required this.status,
  });

  factory Room.fromFirestore(Map<String, dynamic> data, String id) {
    if (id.isEmpty) {
      throw ArgumentError('Room ID cannot be empty');
    }
    
    return Room(
      roomId: id,
      buildingId: data['building_id'] ?? '',
      floorId: data['floor_id'] ?? '',
      name: data['name'] ?? '',
      type: (data['type'] as String?)?.toLowerCase() ?? 'other',
      status: (data['status'] as String?)?.toLowerCase() ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'room_id': roomId,
      'building_id': buildingId,
      'floor_id': floorId,
      'name': name,
      'type': type,
      'status': status,
    };
  }
}
