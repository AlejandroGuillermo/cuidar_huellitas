import 'package:cuidar_huellitas/core/app_colors.dart';
import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget background;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.gradientColors,
    required this.background,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              background,
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: size.width > 520 ? 460 : double.infinity,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthBackground extends StatelessWidget {
  final List<AuthCircleData> circles;

  const AuthBackground({super.key, required this.circles});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: circles
            .map(
              (circle) => Positioned(
                top: circle.top,
                right: circle.right,
                bottom: circle.bottom,
                left: circle.left,
                child: _SoftCircle(size: circle.size, color: circle.color),
              ),
            )
            .toList(),
      ),
    );
  }
}

class AuthCircleData {
  final double size;
  final Color color;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  const AuthCircleData({
    required this.size,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class AuthHero extends StatelessWidget {
  final String chipText;
  final String title;
  final String subtitle;
  final Duration duration;

  const AuthHero({
    super.key,
    required this.chipText,
    required this.title,
    required this.subtitle,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 174,
                height: 174,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              chipText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: AppColors.textoPrincipal.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double offsetY;

  const AuthCard({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 850),
    this.offsetY = 36,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Transform.translate(
          offset: Offset(0, offsetY * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: animatedChild),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220F2D14),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class AuthInfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color accentColor;

  const AuthInfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.accentColor = AppColors.azulPrincipal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthErrorCard extends StatelessWidget {
  final String message;

  const AuthErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(message),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.nivelSalud.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.nivelSalud),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.nivelSalud,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const AuthFieldLabel({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textoPrincipal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

InputDecoration buildAuthInputDecoration({
  required String hint,
  required IconData prefixIcon,
  required Color accentColor,
  Color fillColor = AppColors.fondoPrincipal,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textoSecundario, fontSize: 14),
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 10, right: 8),
      child: Icon(prefixIcon, color: accentColor, size: 20),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 44),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: accentColor.withValues(alpha: 0.18)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: accentColor, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: AppColors.nivelSalud),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: AppColors.nivelSalud, width: 1.5),
    ),
  );
}
