import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../auth/screens/auth_gate.dart';
import '../../auth/services/auth_service.dart';
import '../../events/screens/event_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isUploading = false;

  // Show options to upload image
  Future<void> _showImageSourceDialog() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

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

  // Dialog to enter image URL
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

  // Pick image from gallery and upload
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

  // Update profile URL in Firestore and Auth
  Future<void> _updateProfileUrl(User currentUser, String photoUrl) async {
    if (mounted) setState(() => _isUploading = true);
    await _firestoreService.updateUserPhotoUrl(currentUser.uid, photoUrl);
    await _authService.updateUserAuthProfile(photoUrl);
    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen for profile updates
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: currentUser == null
              ? const Center(child: Text("No user is logged in."))
              : Column(
                  children: [
                    // PROFILE HEADER
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage:
                                    currentUser.photoURL != null &&
                                        currentUser.photoURL!.isNotEmpty
                                    ? NetworkImage(currentUser.photoURL!)
                                    : null,
                                child:
                                    currentUser.photoURL == null ||
                                        currentUser.photoURL!.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.green,
                                  child: IconButton(
                                    icon: _isUploading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                    onPressed: _isUploading
                                        ? null
                                        : _showImageSourceDialog,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentUser.displayName ?? 'Anonymous User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentUser.email ?? 'No email provided',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // JOINED EVENTS LIST
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              'Joined Events',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: StreamBuilder<List<Event>>(
                              stream: _firestoreService.getJoinedEventsStream(
                                currentUser.uid,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'You haven\'t joined any events yet.',
                                    ),
                                  );
                                }

                                final joinedEvents = snapshot.data!;
                                return ListView.builder(
                                  itemCount: joinedEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = joinedEvents[index];
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.event_available,
                                      ),
                                      title: Text(event.title),
                                      subtitle: Text(event.category),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EventDetailsScreen(
                                                  eventId: event.id,
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // SIGN OUT BUTTON
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _authService.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AuthGate(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
