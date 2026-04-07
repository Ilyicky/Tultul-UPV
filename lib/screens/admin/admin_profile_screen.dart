import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tultul_upv/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tultul_upv/models/user_model.dart';
import 'package:tultul_upv/screens/user/user_profile_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Debug information
    print('AdminProfileScreen - Loading: ${userProvider.loading}');
    print('AdminProfileScreen - User: ${userProvider.user?.toMap()}');
    print('AdminProfileScreen - Is Admin: ${userProvider.user?.isAdmin()}');

    if (userProvider.loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (userProvider.user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Please log in to view your profile',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (!userProvider.user!.isAdmin()) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Access denied. Admin privileges required.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Current role: ${userProvider.user!.role == UserRole.admin ? 'Admin' : 'User'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfileScreen(),
                    ),
                  );
                },
                child: const Text('Go to User Profile'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to admin settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin settings coming soon')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.admin_panel_settings,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userProvider.user!.name,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            userProvider.user!.email,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Administrator',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 32),
          _buildAdminSection(context),
          const Divider(height: 32),
          _buildAccountSection(context, userProvider),
        ],
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Admin Controls',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('Manage Buildings'),
          subtitle: const Text('Add, edit, or remove buildings'),
          onTap: () {
            // TODO: Navigate to building management
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Building management coming soon')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.room),
          title: const Text('Manage Rooms'),
          subtitle: const Text('Add, edit, or remove rooms'),
          onTap: () {
            // TODO: Navigate to room management
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Room management coming soon')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('User Management'),
          subtitle: const Text('Manage user accounts and permissions'),
          onTap: () {
            // TODO: Navigate to user management
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User management coming soon')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.analytics),
          title: const Text('Analytics'),
          subtitle: const Text('View usage statistics and reports'),
          onTap: () {
            // TODO: Navigate to analytics
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Analytics coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Account Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Profile'),
          onTap: () {
            // TODO: Implement edit profile
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit profile coming soon')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.password),
          title: const Text('Change Password'),
          onTap: () {
            // TODO: Implement change password
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Change password coming soon')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            userProvider.clearUser();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }
}
