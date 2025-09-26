import 'package:flutter/material.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // We have two tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Approval'),
              Tab(text: 'Approved Events'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Content for the "Pending Approval" tab
            PendingEventsList(),
            // Content for the "Approved Events" tab
            ApprovedEventsList(),
          ],
        ),
      ),
    );
  }
}

// A new widget for the list of pending events
class PendingEventsList extends StatelessWidget {
  const PendingEventsList({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    return StreamBuilder<List<Event>>(
      stream: firestoreService.getPendingEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No events are awaiting approval.'));
        }
        final pendingEvents = snapshot.data!;
        return ListView.builder(
          itemCount: pendingEvents.length,
          itemBuilder: (context, index) {
            final event = pendingEvents[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(event.title),
                subtitle: Text("Organizer: ${event.organizerName}"),
                trailing: ElevatedButton(
                  onPressed: () => firestoreService.approveEvent(event.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// A new widget for the list of approved events
class ApprovedEventsList extends StatelessWidget {
  const ApprovedEventsList({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    return StreamBuilder<List<Event>>(
      stream: firestoreService.getApprovedEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No events have been approved yet.'));
        }
        final approvedEvents = snapshot.data!;
        return ListView.builder(
          itemCount: approvedEvents.length,
          itemBuilder: (context, index) {
            final event = approvedEvents[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(event.title),
                subtitle: Text("Status: ${event.status}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Feature:'),
                    Switch(
                      value: event.isFeatured,
                      onChanged: (bool isFeatured) {
                        firestoreService.setFeaturedStatus(
                          event.id,
                          isFeatured,
                        );
                      },
                      activeThumbColor: Colors.blue,
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
}
