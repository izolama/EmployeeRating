import 'package:flutter/material.dart';

/// Shared gradient background with subtle bubbles.
class AppBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeTop;
  final bool safeBottom;

  const AppBackground({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.safeTop = true,
    this.safeBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF5B4CFF);
    const midPurple = Color(0xFF6E5DFF);
    const lightCircle = Color(0xFF8C7DFF);
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  deepPurple,
                  midPurple,
                  Colors.white,
                ],
                stops: const [0.0, 0.55, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -90,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lightCircle.withOpacity(0.20),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -60,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            top: safeTop,
            bottom: safeBottom,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable card styling that matches the login form surface.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const cardTint = Color(0xFFF2EEFF);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            cardTint.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
