// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

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

  static const String assetPath = 'assets/rive/cat_dog_toggle.riv';
  static final rive.FileLoader _fileLoader = rive.FileLoader.fromAsset(
    assetPath,
    riveFactory: rive.Factory.flutter,
  );

  @override
  State<PetAvatarRive> createState() => _PetAvatarRiveState();
}

class _PetAvatarRiveState extends State<PetAvatarRive> {
  rive.RiveWidgetController? _controller;

  @override
  void didUpdateWidget(covariant PetAvatarRive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tipoMascota != widget.tipoMascota) {
      _applyPetType();
    }
  }

  void _handleLoaded(rive.RiveLoaded state) {
    _controller = state.controller;
    _applyPetType();
  }

  void _applyPetType() {
    final controller = _controller;
    if (controller == null) return;

    final stateMachine = controller.stateMachine;
    final isCat = widget.tipoMascota.toLowerCase() == 'gato';

    final wroteCat = _setAnyInputValue(stateMachine, ['cat', 'cat9'], isCat);
    final wroteDog = _setAnyInputValue(stateMachine, ['dog', 'dog9'], !isCat);

    if (!wroteCat && isCat) {
      _fireAnyInput(stateMachine, ['cat', 'cat9']);
    }
    if (!wroteDog && !isCat) {
      _fireAnyInput(stateMachine, ['dog', 'dog9']);
    }

    controller.scheduleRepaint();
  }

  bool _setAnyInputValue(
    rive.StateMachine stateMachine,
    List<String> names,
    bool value,
  ) {
    for (final name in names) {
      if (_setInputValue(stateMachine, name, value)) {
        return true;
      }
    }
    return false;
  }

  bool _setInputValue(rive.StateMachine stateMachine, String name, bool value) {
    final booleanInput = stateMachine.boolean(name);
    if (booleanInput != null) {
      booleanInput.value = value;
      return true;
    }

    final numberInput = stateMachine.number(name);
    if (numberInput != null) {
      numberInput.value = value ? 1 : 0;
      return true;
    }

    if (value) {
      final triggerInput = stateMachine.trigger(name);
      if (triggerInput != null) {
        triggerInput.fire();
        return true;
      }
    }

    return false;
  }

  bool _fireInput(rive.StateMachine stateMachine, String name) {
    final triggerInput = stateMachine.trigger(name);
    if (triggerInput == null) return false;
    triggerInput.fire();
    return true;
  }

  bool _fireAnyInput(rive.StateMachine stateMachine, List<String> names) {
    for (final name in names) {
      if (_fireInput(stateMachine, name)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Center(
        child: Icon(Icons.pets_rounded, color: Color(0xFF5B6C95)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: rive.RiveWidgetBuilder(
        fileLoader: PetAvatarRive._fileLoader,
        onLoaded: _handleLoaded,
        builder: (context, state) => switch (state) {
          rive.RiveLoaded() => rive.RiveWidget(
            controller: state.controller,
            fit: rive.Fit.contain,
            alignment: widget.alignment,
          ),
          rive.RiveFailed() => _buildFallback(),
          _ => _buildFallback(),
        },
      ),
    );
  }
}
