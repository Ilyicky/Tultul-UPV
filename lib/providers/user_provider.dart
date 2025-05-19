import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? get user => _user;
  bool get loading => _loading;

  Future<void> setUser(User firebaseUser) async {
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (doc.exists) {
        _user = UserModel.fromFirestore(doc);
      } else {
        _user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          role: UserRole.user,
        );
        await _firestore.collection('users').doc(firebaseUser.uid).set(_user!.toMap());
      }
      notifyListeners();
    } catch (e) {
      _user = null;
      notifyListeners();
    }
  }

  Future<void> setupUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    await setUser(firebaseUser!);
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
