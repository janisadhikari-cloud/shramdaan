import 'package:flutter/material.dart';
import '../../../shared/models/event_model.dart';
import '../screens/event_details_screen.dart';

class SmallFeaturedCard extends StatelessWidget {
  final Event event;
  const SmallFeaturedCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220, // Constrain the width to allow for horizontal scrolling
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EventDetailsScreen(eventId: event.id)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                event.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.hide_image_outlined, color: Colors.grey)),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}