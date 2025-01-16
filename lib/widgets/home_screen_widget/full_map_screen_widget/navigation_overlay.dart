import 'package:flutter/material.dart';
import 'package:major_project/widgets/home_screen_widget/full_map_screen_widget/navigation_instruction.dart';

class NavigationOverlay extends StatelessWidget {
  final NavigationInstruction instruction;
  final VoidCallback? onMuteToggle;
  final bool isMuted;
  final VoidCallback? onClose;

  const NavigationOverlay({
    super.key,
    required this.instruction,
    this.onMuteToggle,
    this.isMuted = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    instruction.instruction,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                  onPressed: onMuteToggle,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distance: ${instruction.formattedDistance}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'ETA: ${instruction.formattedDuration}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}