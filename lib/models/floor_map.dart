
class FloorMap {
  final String floorId;
  final String buildingId;
  final int floorLevel;
  final String image;

  FloorMap({
    required this.floorId,
    required this.buildingId,
    required this.floorLevel,
    required this.image,
  });

  factory FloorMap.fromFirestore(Map<String, dynamic> data, String id) {
    return FloorMap(
      floorId: id,
      buildingId: data['building_id'] ?? '',
      floorLevel: data['floor_level'] ?? 1,
      image: data['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'building_id': buildingId,
      'floor_level': floorLevel,
      'image_url': image,
    };
  }
}
