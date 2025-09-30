import 'package:flutter/material.dart';

class TopSectionTitle extends StatelessWidget {
  final Widget title;

  const TopSectionTitle({
    super.key,
    required this.title, // Title as a widget
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title, // Title is passed as a widget
      ],
    );
  }
}
