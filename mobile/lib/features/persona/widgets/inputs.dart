import 'package:flutter/material.dart';
import '../../../shared/colors.dart';

class GenderRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const GenderRow({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String val) => ChoiceChip(
      label: Text(label),
      selected: value == val,
      onSelected: (_) => onChanged(val),
      selectedColor: AppColors.neon,
      labelStyle: TextStyle(
        color: value == val ? Colors.black : Colors.white,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color(0xFF242424),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip('Male', 'male'),
        chip('Female', 'female'),
        chip('Other', 'other'),
      ],
    );
  }
}

class NeonDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const NeonDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _decor(label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E1E),
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text('$e')))
              .toList(),
        ),
      ),
    );
  }

  InputDecoration _decor(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textMuted),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.neon.withOpacity(0.35)),
      borderRadius: BorderRadius.circular(14),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.neon, width: 1.6),
      borderRadius: BorderRadius.circular(14),
    ),
    filled: true,
    fillColor: const Color(0xFF222222),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  );
}
