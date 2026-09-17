import 'package:flutter/material.dart';

/// Keeps the child's gestures and semantics; the scale is decorative only.
class PressableScale extends StatefulWidget {
  final Widget child;
  const PressableScale({super.key, required this.child});
  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => pressed = true),
    onPointerUp: (_) => setState(() => pressed = false),
    onPointerCancel: (_) => setState(() => pressed = false),
    child: AnimatedScale(
      scale: pressed ? .985 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}
