import 'package:flutter/material.dart';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/gradient.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 350,
            left: 0,
            right: 40,
            bottom: 0,
            child: Transform.scale(
              scale: 2,
              child: Opacity(
                opacity: 1.0,
                child: Image.asset(
                  'images/pattern.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}