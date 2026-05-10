import 'package:flutter/material.dart';

class EventMapMarker extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;

  const EventMapMarker({
    super.key,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.event,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
