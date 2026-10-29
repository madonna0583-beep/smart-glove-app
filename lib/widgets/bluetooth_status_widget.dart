import 'package:flutter/material.dart';

class BluetoothStatusWidget extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onRetry;

  const BluetoothStatusWidget({
    Key? key,
    required this.isConnected,
    required this.isConnecting,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected
        ? Colors.green
        : (isConnecting ? Colors.orange : Colors.red);

    final statusText = isConnected
        ? "Connected to HC-05"
        : (isConnecting ? "Connecting / Retrying..." : "Disconnected");

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(
              Icons.bluetooth,
              color: statusColor,
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 15),
            if (!isConnected && !isConnecting)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry Now"),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF660643),
                ),
              ),
          ],
        ),
      ),
    );
  }
}