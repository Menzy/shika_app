import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kukuo/common/top_section_title.dart';

class TTopSectionContainer extends StatelessWidget {
  final Widget child;
  final Widget? title;
  final Widget? subtitle;
  final Widget? fixedContent;
  final Widget? customHeader;
  final double imageHeight;
  final bool isHeaderOnTop;

  const TTopSectionContainer({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.fixedContent,
    this.customHeader,
    this.imageHeight = 160,
    this.isHeaderOnTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final headerWidget = Positioned(
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
            ],
          ),
    );

    final contentWidget = SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // Transparent spacer
          IgnorePointer(
            child: SizedBox(height: imageHeight - 40),
          ),
          // Green container
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
                      title: title!,
                    ),
                  ),
                if (title != null) const SizedBox(height: 35),
                if (fixedContent != null) ...[
                  fixedContent!,
                  const SizedBox(height: 16),
                ],
                child,
              ],
            ),
          ),
        ],
      ),
    );

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
        // Conditionally order Header and Content
        if (!isHeaderOnTop) headerWidget,
        contentWidget,
        if (isHeaderOnTop) headerWidget,
      ],
    );
  }
}
