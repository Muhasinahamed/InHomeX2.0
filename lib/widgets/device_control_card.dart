import 'package:flutter/material.dart';

class DeviceControlCard extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final String label;
  final VoidCallback onPressed;

  const DeviceControlCard({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 140,
            height: 100,
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade200 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 15,
                  top: 5,
                  child: Icon(icon, size: 50, color: Colors.black87),
                ),
                Positioned(
                  bottom: 10,
                  left: 15,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.check_circle, color: Colors.green),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
