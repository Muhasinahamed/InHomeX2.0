import 'package:flutter/material.dart';

class DeviceControlCard extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final String label;
  final VoidCallback onPressed;

  const DeviceControlCard({
    super.key,
    required this.icon,
    required this.isActive,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: isActive ? Colors.white : null,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 60, color: isActive ? Colors.deepPurple : Colors.grey),
            const SizedBox(height: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.deepPurple : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
