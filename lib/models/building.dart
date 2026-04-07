class Building {
  final String buildingId;
  final String name;
  final List<String>? popularNames;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  bool isBookmarked = false;

  Building({
    required this.buildingId,
    required this.name,
    this.popularNames,
    required this.description,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  void markBookmarked() {
    isBookmarked = true;
  }

  void unmarkBookmark() {
    isBookmarked = false;
  }

  // Method to create a Building instance from Firestore data
  factory Building.fromFirestore(Map<String, dynamic> data, String id) {
    if (id.isEmpty) {
      throw ArgumentError('Building ID cannot be empty');
    }

    return Building(
      buildingId: id,
      name: data['name'] ?? '',
      popularNames: List<String>.from(data['popular_names'] ?? []),
      description: data['description'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      imageUrl: data['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'popular_names': popularNames,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
    };
  }
}
