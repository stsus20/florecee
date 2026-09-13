import 'package:flutter/material.dart';

/// One short transition, no perpetual ticker. Honors reduced motion.
class EntradaSuave extends StatelessWidget {
  final Widget child;
  final Duration duration;
  const EntradaSuave({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 340),
  });
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class FloreceSplash extends StatelessWidget {
  const FloreceSplash({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF7F0),
    body: Center(
      child: EntradaSuave(
        duration: const Duration(milliseconds: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDCDDC9)),
              ),
              child: ClipOval(
                child: Image.asset(
                  'lib/assets/icon/app_icon.png',
                  width: 144,
                  height: 144,
                  cacheWidth: 432,
                  cacheHeight: 432,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Florece',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Color(0xFF365F45),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cada cuidado, un nuevo comienzo.',
              style: TextStyle(color: Color(0xFF76816A)),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 70,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF6F915B),
                backgroundColor: Color(0xFFE8EEDF),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
