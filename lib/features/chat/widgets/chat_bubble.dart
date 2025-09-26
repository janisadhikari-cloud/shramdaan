import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final bool isCurrentUser;

  const ChatBubble({
    super.key,
    required this.text,
    required this.senderName,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      // Align bubbles to the right if it's the current user, otherwise to the left
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Bubbles can take up to 75% of screen width
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isCurrentUser ? Theme.of(context).primaryColorLight : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only show the sender's name if it's not the current user
            if (!isCurrentUser)
              Text(
                senderName,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            if (!isCurrentUser) const SizedBox(height: 4.0),
            Text(
              text,
              style: const TextStyle(fontSize: 16.0, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}