import 'package:flutter/material.dart';

/// Wraps content with the custom cursor overlay (web only).
class MouseInteractionWrapper extends StatelessWidget {
  const MouseInteractionWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
