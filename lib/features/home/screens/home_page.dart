import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../events/screens/events_list_screen.dart';
import '../../events/widgets/small_featured_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // The AppBar is removed from here and is now part of EventsListScreen
      // to allow the header to scroll away nicely.
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // A flexible app bar that can contain our header content
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false, // The app bar will disappear as you scroll down
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              // The content of our header
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Personalized Welcome Header ---
                    if (currentUser != null)
                      _buildWelcomeHeader(context, currentUser),

                    // --- User Stats Card ---
                    if (currentUser != null)
                      _buildStatsCard(context, firestoreService, currentUser.uid),
                    
                    // --- Featured Events Section ---
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Featured Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    _buildFeaturedEventsList(firestoreService),
                    
                    // --- All Events Title ---
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Text('All Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              // Set the total height of the header area
              expandedHeight: 450.0,
            ),
          ];
        },
        // The main scrollable body is our filterable events list
        body: const EventsListScreen(),
      ),
    );
  }

  // Helper widget for the welcome message
  Widget _buildWelcomeHeader(BuildContext context, User currentUser) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Afternoon,', style: TextStyle(color: Colors.grey.shade600)),
                Text(
                  currentUser.displayName ?? 'Volunteer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 25,
            backgroundImage: currentUser.photoURL != null ? NetworkImage(currentUser.photoURL!) : null,
            child: currentUser.photoURL == null ? const Icon(Icons.person) : null,
          ),
        ],
      ),
    );
  }

  // Helper widget for the user stats card
  Widget _buildStatsCard(BuildContext context, FirestoreService service, String userId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FutureBuilder<int>(
                future: service.getUserEventCount(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  return _buildStatItem('Events Joined', snapshot.data?.toString() ?? '0');
                },
              ),
              _buildStatItem('Hours Donated', '0'), // Placeholder
              _buildStatItem('Impact Score', '0'), // Placeholder
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  // Helper widget for the featured events list
  Widget _buildFeaturedEventsList(FirestoreService service) {
    return StreamBuilder<List<Event>>(
      stream: service.getFeaturedEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 190, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 100, child: Center(child: Text('No featured events.')));
        }
        final featuredEvents = snapshot.data!;
        return SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: featuredEvents.length,
            itemBuilder: (context, index) {
              return SmallFeaturedCard(event: featuredEvents[index]);
            },
          ),
        );
      },
    );
  }
}