import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pawController;
  late final AnimationController _phoneController;
  late final AnimationController _textController;

  late final Animation<double> _pawScale;
  late final Animation<Offset> _pawSlide;
  late final Animation<double> _phoneRotation;
  late final Animation<double> _phoneFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  Timer? _pawStartTimer;
  Timer? _phoneStartTimer;
  Timer? _textStartTimer;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _pawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _phoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _pawScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pawController, curve: Curves.elasticOut),
    );
    _pawSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _pawController, curve: Curves.easeOutCubic),
        );

    _phoneRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _phoneController, curve: Curves.elasticOut),
    );
    _phoneFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _phoneController, curve: Curves.easeOut));

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _pawStartTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _pawController.forward();
    });

    _phoneStartTimer = Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      _phoneController.forward();
    });

    _textStartTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _textController.forward();
    });

    _navTimer = Timer(const Duration(milliseconds: 2800), _handleNavigation);
  }

  void _handleNavigation() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    context.go(user == null ? '/login' : '/home');
  }

  @override
  void dispose() {
    _pawStartTimer?.cancel();
    _phoneStartTimer?.cancel();
    _textStartTimer?.cancel();
    _navTimer?.cancel();
    _pawController.dispose();
    _phoneController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _buildBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [
            AppColors.splashDarkBase,
            AppColors.splashDarkMid,
            AppColors.splashDarkAccent,
          ]
        : [AppColors.verdeFondo, AppColors.fondoBlanco, AppColors.azulFondo];

    final bubbleGreen = AppColors.verdePrincipal.withValues(
      alpha: isDark ? 0.10 : 0.22,
    );
    final bubbleBlue = AppColors.azulPrincipal.withValues(
      alpha: isDark ? 0.12 : 0.18,
    );

    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),
          Positioned(
            top: -38,
            right: -24,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: bubbleGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -58,
            bottom: -36,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: bubbleBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final cardSize = (width * 0.46).clamp(145.0, 210.0);
    final phoneColor = AppColors.azulPrincipal;
    final pawColor = AppColors.rosa;

    return Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        color: isDark ? AppColors.splashCardDark : AppColors.fondoBlanco,
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppColors.verdePrincipal.withValues(alpha: 0.22),
            blurRadius: 32,
            spreadRadius: 1,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: cardSize * 0.72,
          height: cardSize * 0.72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FadeTransition(
                opacity: _phoneFade,
                child: RotationTransition(
                  turns: _phoneRotation,
                  child: Image.asset(
                    'assets/images/Celular.png',
                    fit: BoxFit.contain,
                    color: phoneColor,
                    colorBlendMode: BlendMode.srcIn,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.phone_iphone_rounded,
                        color: phoneColor,
                        size: cardSize * 0.48,
                      );
                    },
                  ),
                ),
              ),
              SlideTransition(
                position: _pawSlide,
                child: ScaleTransition(
                  scale: _pawScale,
                  child: Transform.translate(
                    offset: const Offset(-4, 0),
                    child: SizedBox(
                      width: cardSize * 0.40,
                      height: cardSize * 0.40,
                      child: Image.asset(
                        'assets/images/Corazon_Huellitas.png',
                        fit: BoxFit.contain,
                        color: pawColor,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.pets_rounded,
                            color: pawColor,
                            size: cardSize * 0.30,
                          );
                        },
                      ),
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

  Widget _buildText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.splashTitleLight;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.splashSubtitleLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CuidARHuellitas',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Cuidando patitas con amor',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSpinner(BuildContext context) {
    final spinnerColor = AppColors.verdePrincipal;
    return SizedBox(
      width: 26,
      height: 26,
      child: CircularProgressIndicator(strokeWidth: 3.2, color: spinnerColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogoCard(context),
                  const SizedBox(height: 34),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildText(context),
                          const SizedBox(height: 22),
                          _buildSpinner(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
