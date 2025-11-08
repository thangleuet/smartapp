import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class FadeAnimation extends StatelessWidget {
  final double delay;
  final Widget child;

  FadeAnimation(this.delay, this.child);

  @override
  Widget build(BuildContext context) {
    final tween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn));

    return PlayAnimationBuilder(
      delay: Duration(milliseconds: (500 * delay).round()),
      duration: const Duration(seconds: 2),
      tween: tween,
      child: child,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
    );
}
}