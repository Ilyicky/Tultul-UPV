import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/building.dart';

class BuildingsProvider extends ChangeNotifier {
  // Stream for fetching buildings
  late Stream<List<Building>> _buildingsStream;
  Stream<List<Building>> get buildingsStream => _buildingsStream;

  // Constructor
  BuildingsProvider() {
    fetchBuildings();
  }

  // Method to fetch buildings from Firestore
  void fetchBuildings() {
    _buildingsStream = FirebaseFirestore.instance
        .collection('buildings')
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
}
