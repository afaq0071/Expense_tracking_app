import 'package:flutter/material.dart';

/// Custom page route with a smooth fade + slight slide transition.
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlideRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Push a new page with the fade-slide transition.
void pushPage(BuildContext context, Widget page) {
  Navigator.push(context, FadeSlideRoute(page: page));
}

/// Replace current page with the fade-slide transition.
void pushReplacementPage(BuildContext context, Widget page) {
  Navigator.pushReplacement(context, FadeSlideRoute(page: page));
}
