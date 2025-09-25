import 'package:flutter/material.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../events/screens/events_list_screen.dart';
import '../../events/widgets/small_featured_card.dart'; // UPDATED

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Events'),
        // Note: Action buttons are handled in the main HomeScreen shell
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Featured Events',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // UPDATED: StreamBuilder now handles a List of events
                  StreamBuilder<List<Event>>(
                    stream: firestoreService.getFeaturedEventsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox(
                          height: 100,
                          child: Center(
                            child: Text('No upcoming featured events.'),
                          ),
                        );
                      }
                      final featuredEvents = snapshot.data!;

                      // Horizontal, scrollable list of featured events
                      return SizedBox(
                        height: 190,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemCount: featuredEvents.length,
                          itemBuilder: (context, index) {
                            final event = featuredEvents[index];
                            return SmallFeaturedCard(event: event);
                          },
                        ),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Text(
                      'All Events',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        // The body of the NestedScrollView is our existing events list
        body: const EventsListScreen(),
      ),
    );
  }
}
