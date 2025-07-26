import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kukuo/common/top_section_title.dart';

class TTopSectionContainer extends StatelessWidget {
  final Widget child;
  final Widget title; // Title as a widget
  final Widget? subtitle; // Optional subtitle as a widget
  final Widget? fixedContent; // New: Fixed content that doesn't scroll
  final double imageHeight;

  const TTopSectionContainer({
    super.key,
    required this.child,
    required this.title, // Title as a widget
    this.subtitle, // Optional subtitle as a widget
    this.fixedContent, // New: Fixed content that doesn't scroll
    this.imageHeight = 160, // Default height for the image
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: imageHeight,
            child: Image.asset(
              'assets/images/home_image.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Positioned widget for logo and text
        Positioned(
          top: 50,
          left: 40,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/logo.svg',
                width: 35,
                height: 35,
              ),
              const SizedBox(width: 10),
              const Text(
                'Kukuo.',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Gazpacho',
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: imageHeight - 40,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFF001817),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TopSectionTitle(
                  title: title, // Title passed as a widget
                ),
                const SizedBox(height: 35), // Spacing before content
                // Fixed content that doesn't scroll (if provided)
                if (fixedContent != null) ...[
                  fixedContent!,
                  const SizedBox(height: 16),
                ],
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
