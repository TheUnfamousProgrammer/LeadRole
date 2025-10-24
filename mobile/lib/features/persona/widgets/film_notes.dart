import 'package:flutter/material.dart';
import '../../../shared/colors.dart';

class FilmNotes extends StatelessWidget {
  final List<String> points;
  const FilmNotes({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: points.map((p) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎬 ', style: TextStyle(color: AppColors.neon)),
            Expanded(
              child: Text(
                p,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
