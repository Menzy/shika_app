import 'package:flutter/material.dart';
import 'package:kukuo/common/top_section_container.dart';

class PaperTrailScreen extends StatelessWidget {
  const PaperTrailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TTopSectionContainer(
        title: const Text(
          'PaperTrail',
          style: TextStyle(
            fontFamily: 'Gazpacho',
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD8FE00),
          ),
        ),
        child: Container());
  }
}
