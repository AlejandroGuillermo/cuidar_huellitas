import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MangueraToolWidget extends StatefulWidget {
  final bool enabled;
  final double size;

  const MangueraToolWidget({
    super.key,
    required this.enabled,
    this.size = 48,
  });

  @override
  State<MangueraToolWidget> createState() => _MangueraToolWidgetState();
}

class _MangueraToolWidgetState extends State<MangueraToolWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: 0, end: -3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.55;

    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: SvgPicture.asset(
          'assets/images/banar/shower_header_vectorized.svg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
