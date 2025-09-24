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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender's Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              senderName,
              style: const TextStyle(fontSize: 12.0, color: Colors.grey),
            ),
          ),
          // Message Bubble
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.green[200] : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16.0),
                topRight: const Radius.circular(16.0),
                bottomLeft: isCurrentUser
                    ? const Radius.circular(16.0)
                    : const Radius.circular(0),
                bottomRight: isCurrentUser
                    ? const Radius.circular(0)
                    : const Radius.circular(16.0),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 16.0, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}