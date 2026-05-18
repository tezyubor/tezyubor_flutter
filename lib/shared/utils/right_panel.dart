import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/services/haptic_service.dart';

/// Pushes [page] as a new route that slides in from the right.
/// On iOS uses [CupertinoPageRoute] to enable the native edge swipe-back gesture.
Future<T?> pushRightPanel<T>(BuildContext context, Widget page) {
  HapticService.light();
  if (Platform.isIOS) {
    return Navigator.of(context).push<T>(
      CupertinoPageRoute<T>(builder: (_) => page),
    );
  }
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: child,
      ),
    ),
  );
}

/// Wraps [child] with an interactive swipe-left gesture that pops the route.
/// On iOS this is a no-op — [CupertinoPageRoute] handles the gesture natively
/// and a GestureDetector here would conflict with it.
class SwipeToDismiss extends StatefulWidget {
  final Widget child;
  const SwipeToDismiss({super.key, required this.child});

  @override
  State<SwipeToDismiss> createState() => _SwipeToDismissState();
}

class _SwipeToDismissState extends State<SwipeToDismiss>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snapCtrl;
  double _dragX = 0.0;
  double _snapFrom = 0.0;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _snapCtrl.addListener(() {
      if (mounted) {
        setState(() {
          _dragX = _snapFrom * (1.0 - Curves.easeOutCubic.transform(_snapCtrl.value));
        });
      }
    });
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) {
    _snapCtrl.stop();
    _snapCtrl.reset();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.delta.dx;
    if (delta < 0 || _dragX < 0) {
      setState(() {
        _dragX = (_dragX + delta)
            .clamp(-MediaQuery.of(context).size.width, 0.0);
      });
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final w = MediaQuery.of(context).size.width;
    final v = d.primaryVelocity ?? 0;
    if (v < -400 || _dragX < -(w * 0.35)) {
      setState(() => _dragX = 0);
      Navigator.of(context).maybePop();
    } else {
      _snapFrom = _dragX;
      _snapCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: widget.child,
      ),
    );
  }
}

/// Standard back button for right-panel pages.
class PanelBackButton extends StatelessWidget {
  const PanelBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      );
}
