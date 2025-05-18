import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, user }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final List<String> bookmarkedBuildings;
  final List<String> bookmarkedRooms;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.bookmarkedBuildings = const [],
    this.bookmarkedRooms = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] == 'admin' ? UserRole.admin : UserRole.user,
      bookmarkedBuildings: List<String>.from(data['bookmarkedBuildings'] ?? []),
      bookmarkedRooms: List<String>.from(data['bookmarkedRooms'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role == UserRole.admin ? 'admin' : 'user',
      'bookmarkedBuildings': bookmarkedBuildings,
      'bookmarkedRooms': bookmarkedRooms,
    };
  }

  bool isAdmin() => role == UserRole.admin;
} 