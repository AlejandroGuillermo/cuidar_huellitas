import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/app_colors.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../widgets/pet_avatar_rive.dart';

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeFuture;
  Offset _petOffset = const Offset(0, 20);
  double _petScale = 1.0;

  bool get _cameraSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    if (_cameraSupported) {
      _initializeFuture = _setupCamera();
    }
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No se encontró una cámara disponible.');
    }

    final selectedCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _cameraController = controller;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _resetPetTransform() {
    setState(() {
      _petOffset = const Offset(0, 20);
      _petScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, petState) {
        final mascota = petState.mascota;
        final petEmoji = mascota?.tipoMascota.toLowerCase() ?? 'dog';
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: _cameraSupported
                    ? _buildCameraPreview()
                    : const _CameraUnavailableView(),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _CircleGlassButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Modo AR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Arrastra tu mascota y ajusta el tamano abajo.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _petOffset += details.delta;
                              });
                            },
                            child: Transform.translate(
                              offset: _petOffset,
                              child: Transform.scale(
                                scale: _petScale,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Container(
                                      width: 165,
                                      height: 30,
                                      margin: const EdgeInsets.only(top: 188),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.22,
                                        ),
                                        borderRadius: BorderRadius.circular(60),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 220,
                                      height: 220,
                                      child: PetAvatarRive(
                                        tipoMascota: petEmoji,
                                        width: 220,
                                        height: 220,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.open_with_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Mueve a tu mascota para acomodarla en la escena.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _resetPetTransform,
                                  child: const Text('Reiniciar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.zoom_out_map_rounded,
                                  color: Colors.white70,
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _petScale,
                                    min: 0.65,
                                    max: 1.65,
                                    activeColor: AppColors.verdePrincipal,
                                    inactiveColor: Colors.white24,
                                    onChanged: (value) {
                                      setState(() {
                                        _petScale = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraPreview() {
    final initializeFuture = _initializeFuture;
    if (initializeFuture == null) {
      return const _CameraUnavailableView();
    }

    return FutureBuilder<void>(
      future: initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.verdePrincipal),
            ),
          );
        }

        if (snapshot.hasError || _cameraController == null) {
          return _CameraErrorView(message: _cameraErrorMessage(snapshot.error));
        }

        return CameraPreview(_cameraController!);
      },
    );
  }

  String _cameraErrorMessage(Object? error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
          return 'Se negó el permiso de cámara.';
        case 'CameraAccessRestricted':
          return 'La cámara está restringida en este dispositivo.';
        default:
          return error.description ?? 'No se pudo iniciar la cámara.';
      }
    }
    return 'No se pudo iniciar la cámara.';
  }
}

class _CircleGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleGlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _CameraUnavailableView extends StatelessWidget {
  const _CameraUnavailableView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF10151B),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'La cámara AR simple está disponible en Android y iPhone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  final String message;

  const _CameraErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF10151B),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                color: Colors.white70,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
