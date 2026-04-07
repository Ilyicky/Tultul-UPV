class Room {
  final String roomId;
  final String buildingId;
  final String floorId;
  final String name;

  Room({
    required this.roomId,
    required this.buildingId,
    required this.floorId,
    required this.name,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'room_id': roomId,
      'building_id': buildingId,
      'floor_id': floorId,
      'name': name,
    };
  }
}
