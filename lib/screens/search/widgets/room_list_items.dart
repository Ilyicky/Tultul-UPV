import 'package:flutter/material.dart';
import 'package:tultul_upv/models/room.dart';
import 'package:tultul_upv/screens/rooms/room_instructions_screen.dart';

class AdminRoomListItem extends StatelessWidget {
  final Room room;

  const AdminRoomListItem({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.room),
        title: Text(room.name),
        subtitle: const Text('Room'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editRoom(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteRoom(context),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomInstructionsScreen(room: room),
            ),
          );
        },
      ),
    );
  }

  void _editRoom(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Room'),
            content: Text(
              'Edit form for ${room.name} will be implemented here.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement room editing logic
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _deleteRoom(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Room'),
            content: Text('Are you sure you want to delete ${room.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement room deletion logic
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

class UserRoomListItem extends StatelessWidget {
  final Room room;

  const UserRoomListItem({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.room),
        title: Text(room.name),
        subtitle: const Text('Room'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomInstructionsScreen(room: room),
            ),
          );
        },
      ),
    );
  }
}
