import 'package:flutter/material.dart';

import 'clay_spring.dart';

enum ClayRouteTransitionStyle { page, result }

class ClayPageRoute<T> extends PageRouteBuilder<T> {
  ClayPageRoute({
    required this.builder,
    required RouteSettings super.settings,
    this.style = ClayRouteTransitionStyle.page,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: const Duration(milliseconds: 360),
         reverseTransitionDuration: const Duration(milliseconds: 280),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curved = CurvedAnimation(
             parent: animation,
             curve: const ClaySpringCurve(),
             reverseCurve: Curves.easeOutCubic,
           );
           final beginOffset = style == ClayRouteTransitionStyle.result
               ? const Offset(0, 0.06)
               : const Offset(0.045, 0);

           return FadeTransition(
             opacity: Tween<double>(begin: 0.18, end: 1).animate(curved),
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: beginOffset,
                 end: Offset.zero,
               ).animate(curved),
               child: ScaleTransition(
                 scale: Tween<double>(
                   begin: style == ClayRouteTransitionStyle.result
                       ? 0.96
                       : 0.985,
                   end: 1,
                 ).animate(curved),
                 child: child,
               ),
             ),
           );
         },
       );

  final WidgetBuilder builder;
  final ClayRouteTransitionStyle style;
}
