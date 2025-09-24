import 'package:flutter/material.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../events/screens/events_list_screen.dart';
import '../../events/widgets/featured_event_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Events'),
        // Note: The action buttons are now in the main HomeScreen shell
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      'Featured Event',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // StreamBuilder for the featured event
                  StreamBuilder<Event?>(
                    stream: firestoreService.getFeaturedEventStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 280,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox(
                          height: 100,
                          child: Center(child: Text('No upcoming featured events.')),
                        );
                      }
                      final featuredEvent = snapshot.data!;
                      return FeaturedEventCard(event: featuredEvent);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'All Events',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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