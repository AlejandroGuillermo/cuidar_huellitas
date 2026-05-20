import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/cosmetic_catalog.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';

class PetAvatarRive extends StatefulWidget {
  const PetAvatarRive({
    super.key,
    required this.tipoMascota,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String tipoMascota;
  final double? width;
  final double? height;
  final Alignment alignment;

  @override
  State<PetAvatarRive> createState() => _PetAvatarRiveState();
}

class _PetAvatarRiveState extends State<PetAvatarRive>
    with SingleTickerProviderStateMixin {
  static const String _catAssetPath = 'assets/images/gato_vectorized.svg';
  static const String _dogAssetPath = 'assets/images/perro_vectorized.svg';

  late final AnimationController _breathController;

  String get _assetPath {
    final normalizedType = widget.tipoMascota.toLowerCase().trim();
    switch (normalizedType) {
      case 'gato':
      case 'cat':
        return _catAssetPath;
      case 'perro':
      case 'dog':
        return _dogAssetPath;
      default:
        return _catAssetPath;
    }
  }

  bool get _isCat {
    final normalizedType = widget.tipoMascota.toLowerCase().trim();
    return normalizedType == 'gato' || normalizedType == 'cat';
  }

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
      lowerBound: -1,
      upperBound: 1,
    );

    if (_isCat) {
      _breathController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PetAvatarRive oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasCat = oldWidget.tipoMascota.toLowerCase().trim();
    final isCatNow = widget.tipoMascota.toLowerCase().trim();
    final wasCatType = wasCat == 'gato' || wasCat == 'cat';
    final isCatType = isCatNow == 'gato' || isCatNow == 'cat';

    if (wasCatType == isCatType) return;

    if (isCatType) {
      _breathController.repeat(reverse: true);
    } else {
      _breathController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  double get _breathScale => 1 + (_breathController.value * 0.012);

  double get _headAccessoryFontSize {
    final referenceSize =
        (widget.width ?? widget.height ?? 140.0).clamp(96.0, 320.0).toDouble();
    return referenceSize * 0.18;
  }

  double get _headAccessoryTopOffset => -_headAccessoryFontSize * 0.35;

  Widget _buildSvgLayer() {
    return SvgPicture.asset(
      _assetPath,
      fit: BoxFit.contain,
      alignment: widget.alignment,
      semanticsLabel: 'Mascota vectorizada',
      placeholderBuilder: (context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7ED),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Center(
          child: Icon(Icons.pets_rounded, color: Color(0xFF5B6C95)),
        ),
      ),
    );
  }

  Widget _buildAvatarWithAccessory(String? headItemEmoji) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _buildSvgLayer(),
        if (headItemEmoji != null)
          Positioned(
            top: _headAccessoryTopOffset,
            child: Text(
              headItemEmoji,
              style: TextStyle(fontSize: _headAccessoryFontSize),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final headItemEmoji = CosmeticCatalog.headEmojiFor(
          state.mascota?.itemCabezaId,
        );

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: !_isCat
              ? _buildAvatarWithAccessory(headItemEmoji)
              : AnimatedBuilder(
                  animation: _breathController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _breathScale,
                      child: child,
                    );
                  },
                  child: _buildAvatarWithAccessory(headItemEmoji),
                ),
        );
      },
    );
  }
}
