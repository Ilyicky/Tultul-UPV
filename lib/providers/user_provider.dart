import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = true;

  UserModel? get user => _user;
  bool get loading => _loading;

  Future<void> setUser(User? firebaseUser) async {
    if (firebaseUser == null) {
      clearUser();
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Fetching user data for: ${firebaseUser.uid}');
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get();

      if (doc.exists) {
        if (kDebugMode) {
          print('User document data: ${doc.data()}');
        }
        _user = UserModel.fromFirestore(doc);
        if (kDebugMode) {
          print('User role: ${_user?.role}');
          print('Is admin: ${_user?.isAdmin()}');
        }
      } else {
        if (kDebugMode) {
          print('No user document found, creating new user');
        }
        // Create a new user document if it doesn't exist
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name:
              firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'User',
          role: UserRole.user,
          bookmarkedBuildings: [],
          bookmarkedRooms: [],
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toMap());
        _user = newUser;
        if (kDebugMode) {
          print('Created new user with role: ${_user?.role}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user: $e');
      }
      _user = null;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> setupUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    await setUser(firebaseUser);
  }

  Future<void> updateBookmarks({String? buildingId, String? roomId}) async {
    if (_user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid);

    if (buildingId != null) {
      List<String> updatedBuildings = List.from(_user!.bookmarkedBuildings);
      if (updatedBuildings.contains(buildingId)) {
        updatedBuildings.remove(buildingId);
      } else {
        updatedBuildings.add(buildingId);
      }
      await userDoc.update({'bookmarkedBuildings': updatedBuildings});
    }

    if (roomId != null) {
      List<String> updatedRooms = List.from(_user!.bookmarkedRooms);
      if (updatedRooms.contains(roomId)) {
        updatedRooms.remove(roomId);
      } else {
        updatedRooms.add(roomId);
      }
      await userDoc.update({'bookmarkedRooms': updatedRooms});
    }

    // Refresh user data
    await setupUser();
  }

  void clearUser() {
    _user = null;
    _loading = false;
    notifyListeners();
  }
}
