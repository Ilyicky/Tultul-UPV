import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/building.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Building Requests'),
              Tab(text: 'Room Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BuildingRequestsList(),
            _RoomRequestsList(),
          ],
        ),
      ),
    );
  }
}

class _BuildingRequestsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('buildingRequests')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('No pending building requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index].data() as Map<String, dynamic>;
            final requestId = requests[index].id;
            final building = Building.fromFirestore(request, requestId);

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('College: ${building.college}'),
                    Text('Address: ${building.address}'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _rejectRequest(requestId),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _approveRequest(building, requestId),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approveRequest(Building building, String requestId) async {
    try {
      // Add to buildings collection
      await FirebaseFirestore.instance
          .collection('buildings')
          .add(building.toMap());

      // Delete the request
      await FirebaseFirestore.instance
          .collection('buildingRequests')
          .doc(requestId)
          .delete();
    } catch (e) {
      debugPrint('Error approving request: $e');
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('buildingRequests')
          .doc(requestId)
          .delete();
    } catch (e) {
      debugPrint('Error rejecting request: $e');
    }
  }
}

class _RoomRequestsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('roomRequests')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('No pending room requests'));
        }

        // TODO: Implement room requests list when room model is ready
        return const Center(child: Text('Room requests coming soon'));
      },
    );
  }
} 