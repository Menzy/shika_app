import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kukuo/common/top_section_title.dart';
import 'package:kukuo/screens/settings_screen.dart';
import 'package:iconsax/iconsax.dart';

class TTopSectionContainer extends StatelessWidget {
  final Widget child;
  final Widget? title; // Title as a widget (now optional)
  final Widget? subtitle; // Optional subtitle as a widget
  final Widget? fixedContent; // New: Fixed content that doesn't scroll
  final Widget? customHeader; // New: Custom header to replace logo/settings row
  final double imageHeight;

  const TTopSectionContainer({
    super.key,
    required this.child,
    this.title, // Title as a widget
    this.subtitle, // Optional subtitle as a widget
    this.fixedContent, // New: Fixed content that doesn't scroll
    this.customHeader, // New: Custom header
    this.imageHeight = 160, // Default height for the image
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fixed background image at the top
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
        // Scrollable green container - positioned to scroll over the header
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(), // Prevents bounce/over-scroll
          child: Column(
            children: [
              // Transparent spacer to start the green container at the right position
              SizedBox(height: imageHeight - 40),
              // Green container with rounded corners
              Container(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height - (imageHeight - 40),
                ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: TopSectionTitle(
                          title: title!, // Title passed as a widget
                        ),
                      ),
                    if (title != null)
                      const SizedBox(height: 35), // Spacing before content
                    // Fixed content that doesn't scroll (if provided)
                    if (fixedContent != null) ...[
                      fixedContent!,
                      const SizedBox(height: 16),
                    ],
                    // Content
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
        // Fixed logo and text OR Custom Header
        Positioned(
          top: 50,
          left: 40,
          right: 0,
          child: customHeader ??
              Row(
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
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00312F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00514F),
                        ),
                      ),
                      child: const Icon(
                        Iconsax.setting_2,
                        color: Color(0xFFD8FE00),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
        ),
      ],
    );
  }
}
