

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String? senderLabel;
  final Timestamp? timestamp;


  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.senderLabel,
    this.timestamp,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final bg = isCurrentUser ? Colors.green[400] : Colors.white;
    final align = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isCurrentUser
        ? const BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: Radius.circular(12),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomRight: Radius.circular(12),
    );


    String time = '';
    if (timestamp != null) {
      try {
        time = DateFormat('HH:mm').format(timestamp!.toDate());
      } catch (_) {}
    }


    return Column(
      crossAxisAlignment: align,
      children: [
        if (senderLabel != null && !isCurrentUser)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(senderLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(color: bg, borderRadius: radius, boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))
          ]),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black87, fontSize: 16)),
              if (time.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}