class RoomInstruction {
  final String id;
  final String text;
  final List<String> imageUrls;
  final int order;  // For ordering multiple instructions

  RoomInstruction({
    required this.id,
    required this.text,
    required this.imageUrls,
    required this.order,
  });

  factory RoomInstruction.fromFirestore(Map<String, dynamic> data, String id) {
    return RoomInstruction(
      id: id,
      text: data['text'] ?? '',
      imageUrls: List<String>.from(data['image_urls'] ?? []),
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'image_urls': imageUrls,
      'order': order,
    };
  }
} 