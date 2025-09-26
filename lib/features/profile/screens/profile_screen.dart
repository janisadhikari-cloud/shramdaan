import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../auth/screens/auth_gate.dart';
import '../../auth/services/auth_service.dart';
import '../../events/screens/event_details_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isUploading = false;

  // --- LOGIC METHODS FOR IMAGE UPLOADING ---

  Future<void> _showImageSourceDialog(User currentUser) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Profile Picture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Upload from Gallery"),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(currentUser);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text("Use Image URL"),
              onTap: () {
                Navigator.of(context).pop();
                _showUrlInputDialog(currentUser);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUrlInputDialog(User currentUser) async {
    final TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Image URL"),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(hintText: "https://..."),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Save"),
            onPressed: () async {
              if (mounted) Navigator.of(context).pop();
              if (urlController.text.trim().isNotEmpty) {
                await _updateProfileUrl(currentUser, urlController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(User currentUser) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile == null) return;
    if (mounted) setState(() => _isUploading = true);
    final imageBytes = await pickedFile.readAsBytes();
    final imageUrl = await _firestoreService.uploadProfilePicture(
      imageBytes: imageBytes,
      userId: currentUser.uid,
    );
    if (imageUrl != null) {
      await _updateProfileUrl(currentUser, imageUrl);
    }
    if (mounted) setState(() => _isUploading = false);
  }

  Future<void> _updateProfileUrl(User currentUser, String photoUrl) async {
    if (mounted) setState(() => _isUploading = true);
    await _firestoreService.updateUserPhotoUrl(currentUser.uid, photoUrl);
    await _authService.updateUserAuthProfile(photoUrl);
    if (mounted) setState(() => _isUploading = false);
  }

  // --- BUILD METHOD AND UI HELPERS ---

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Account')),
            body: const Center(child: Text("No user is logged in.")),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Account')),
          body: StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.getUserStream(currentUser.uid),
            builder: (context, userDocSnapshot) {
              if (!userDocSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final userData =
                  userDocSnapshot.data!.data() as Map<String, dynamic>;
              final String userRole = userData['role'] ?? 'volunteer';

              return ListView(
                children: [
                  _buildProfileHeader(currentUser),
                  const SizedBox(height: 16),
                  _buildSettingsCard(context, userRole),
                  const SizedBox(height: 16),
                  _buildJoinedEvents(context, currentUser),
                  _buildSignOutButton(context),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(User currentUser) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    currentUser.photoURL != null &&
                        currentUser.photoURL!.isNotEmpty
                    ? NetworkImage(currentUser.photoURL!)
                    : null,
                child:
                    currentUser.photoURL == null ||
                        currentUser.photoURL!.isEmpty
                    ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.edit, size: 20, color: Colors.white),
                    onPressed: _isUploading
                        ? null
                        : () => _showImageSourceDialog(currentUser),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentUser.displayName ?? 'Anonymous User',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            currentUser.email ?? 'No email provided',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, String userRole) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Column(
          children: [
            if (userRole == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Dashboard'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen(),
                  ),
                ),
              ),
            if (userRole == 'admin') const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinedEvents(BuildContext context, User currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8, left: 4),
            child: Text(
              'Joined Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<List<Event>>(
            stream: _firestoreService.getJoinedEventsStream(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Card(
                  child: ListTile(
                    title: Text('You haven\'t joined any events yet.'),
                  ),
                );
              }
              final joinedEvents = snapshot.data!;
              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: joinedEvents.length,
                  itemBuilder: (context, index) {
                    final event = joinedEvents[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: event.imageUrl.isNotEmpty
                            ? NetworkImage(event.imageUrl)
                            : null,
                        child: event.imageUrl.isEmpty
                            ? const Icon(Icons.event)
                            : null,
                      ),
                      title: Text(event.title),
                      subtitle: Text(event.category),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventDetailsScreen(eventId: event.id),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          onPressed: () async {
            await _authService.signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthGate()),
                (route) => false,
              );
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: BorderSide(color: Colors.red.shade200),
          ),
        ),
      ),
    );
  }
}
