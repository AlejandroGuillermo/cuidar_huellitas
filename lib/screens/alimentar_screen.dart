import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../application/cubits/pet_world_cubit.dart';
import '../core/app_colors.dart';
import '../core/cosmetic_catalog.dart';
import '../core/disaster_system.dart';
import '../core/food_catalog.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../domain/enums/pet_activity.dart';
import '../domain/enums/pet_location.dart';
import '../screens/alimentar/alimentar_cubit.dart';
import '../screens/alimentar/alimentar_controller.dart';
import '../screens/alimentar/alimentar_state.dart';
import '../widgets/action_screen_header.dart';
import '../widgets/paw_map_widget.dart';
import '../widgets/pet_avatar_rive.dart';

class AlimentarScreen extends StatefulWidget {
  const AlimentarScreen({super.key});

  @override
  State<AlimentarScreen> createState() => _AlimentarScreenState();
}

class _AlimentarScreenState extends State<AlimentarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _petAnimationController;
  late final AlimentarCubit _alimentarCubit;
  final LayerLink _cupboardLayerLink = LayerLink();
  final GlobalKey _plateVisualKey = GlobalKey();
  bool cupboardOpen = false;
  double _swipeDx = 0.0;

  AlimentarState get _feedingState => _alimentarCubit.state;
  FoodCatalogItem? get _activeBag => _feedingState.activeBag;
  double get _plateLevel => _feedingState.plateLevel;
  bool get _loadingData => _feedingState.loading;
  int get _coins => _feedingState.coins;
  String? get _plateFoodId => _feedingState.plateFoodId;
  String get _plateEmoji => _feedingState.plateEmoji;
  List<String> get _foodInPlate => _feedingState.foodInPlate;
  Map<String, double> get _inventoryUnits => _feedingState.inventoryUnits;
  bool get _isEating =>
      context.read<PetCubit>().state.mascota?.platoComiendo ?? false;

  @override
  void initState() {
    super.initState();
    _petAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _alimentarCubit = AlimentarCubit();
    _alimentarCubit.initialize(pet: context.read<PetCubit>().state.mascota);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AlimentarController.syncWorldEntry(
        petCubit: context.read<PetCubit>(),
        worldCubit: context.read<PetWorldCubit>(),
        disasterCubit: context.read<DisasterCubit>(),
        isEating: _isEating,
      );
      if (!mounted) return;
      await AlimentarController.ensureLockedEatingState(
        petCubit: context.read<PetCubit>(),
        worldCubit: context.read<PetWorldCubit>(),
      );
    });
  }

  @override
  void dispose() {
    _alimentarCubit.close();
    _petAnimationController.dispose();
    super.dispose();
  }

  void _showFoodInfo(FoodCatalogItem food) {
    final units = _inventoryUnits[food.id] ?? 0.0;
    final bags = (units / FoodCatalog.bagUnits).toStringAsFixed(1);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${food.emoji} ${food.name}'),
        content: Text(
          'Sube hambre: +${food.hungerPoints}\n'
          'Cantidad disponible: $bags bolsas',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void handleSelectFood(FoodCatalogItem food) {
    final message = _alimentarCubit.selectFood(food, eating: _isEating);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    setState(() => cupboardOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _alimentarCubit,
      child: BlocListener<PetCubit, PetState>(
        listenWhen: (previous, current) {
          return previous.mascota?.nivelPlato != current.mascota?.nivelPlato ||
              previous.mascota?.platoComiendo !=
                  current.mascota?.platoComiendo ||
              previous.mascota?.platoAlimentoId !=
                  current.mascota?.platoAlimentoId ||
              previous.mascota?.platoEmoji != current.mascota?.platoEmoji;
        },
        listener: (context, state) async {
          final mascota = state.mascota;
          if (mascota == null) return;
          _alimentarCubit.syncFromPet(mascota);
          await AlimentarController.syncEatingAnchor(
            petCubit: context.read<PetCubit>(),
            worldCubit: context.read<PetWorldCubit>(),
            isEatingNow: mascota.platoComiendo && mascota.nivelPlato > 0,
            plateFoodId: _plateFoodId,
          );
        },
        child: BlocBuilder<AlimentarCubit, AlimentarState>(
          builder: (context, alimentarState) {
            return Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () => mostrarMapaHuella(context),
                backgroundColor: AppColors.verdeFondo,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.pets,
                  color: AppColors.azulPrincipal,
                  size: 28,
                ),
              ),
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) {
                  _swipeDx = 0.0;
                },
                onHorizontalDragUpdate: (details) {
                  _swipeDx += details.delta.dx;
                },
                onHorizontalDragEnd: (details) {
                  const minDistance = 90.0;
                  const minVelocity = 700.0;
                  final velocityX = details.primaryVelocity ?? 0.0;
                  final isIntentionalLeftSwipe =
                      _swipeDx <= -minDistance && velocityX <= -minVelocity;
                  final isIntentionalRightSwipe =
                      _swipeDx >= minDistance && velocityX >= minVelocity;

                  if (isIntentionalLeftSwipe) {
                    context.goNamed('home', extra: 'alimentar');
                  } else if (isIntentionalRightSwipe) {
                    context.goNamed('curar', extra: 'alimentar');
                  }
                  _swipeDx = 0.0;
                },
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE8D5C4),
                        Color(0xFFF0E6D2),
                        Color(0xFFD4C4B0),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: CustomPaint(painter: TilePainter()),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            ActionScreenHeader(
                              icon: Icons.kitchen,
                              title: 'Comedor',
                              subtitlePrefix: 'Hora de comer',
                              statLabel: 'Hambre:',
                              statSelector: (mascota) => mascota.nivelHambre,
                              barColors: const [
                                Color(0xFFF0C77A),
                                Color(0xFFFFD166),
                              ],
                            ),
                            if (_loadingData)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: CircularProgressIndicator(),
                              ),
                            if (!_loadingData)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.doradoSuave,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.doradoBorde,
                                    ),
                                  ),
                                  child: Text(
                                    '🪙 $_coins',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.doradoTexto,
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 150,
                                          height: 120,
                                          child: _buildCupboard(),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildTable()),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Expanded(child: _buildPet()),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cupboardOpen) _buildCupboardOverlay(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCupboard() {
    const double cupboardWidth = 150;
    const double closedHeight = 120;

    return CompositedTransformTarget(
      link: _cupboardLayerLink,
      child: GestureDetector(
        onTap: () => setState(() => cupboardOpen = !cupboardOpen),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: cupboardWidth,
          height: closedHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6D4C3D), Color(0xFF4A3428)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cupboardOpen
                  ? const Color(0xFFF0D79D)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF3E291E),
                            width: 2,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF3E291E),
                            width: 2,
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E291E).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B6F47),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Alacena',
                    style: TextStyle(
                      color: Color(0xFFF0E6D2),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              if (cupboardOpen)
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: Color(0xFFF0D79D),
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupboardOverlay() {
    const double cupboardWidth = 150;
    const double openHeight = 330;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => cupboardOpen = false),
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _cupboardLayerLink,
              showWhenUnlinked: false,
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {},
                  child: Container(
                    width: cupboardWidth,
                    height: openHeight,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF6D4C3D), Color(0xFF4A3428)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.38),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Header de la alacena abierta
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Alimentos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    setState(() => cupboardOpen = false),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                splashRadius: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.78,
                                  ),
                              itemCount: FoodCatalog.items.length,
                              itemBuilder: (context, index) {
                                final food = FoodCatalog.items[index];
                                final isUnlocked = _alimentarCubit
                                    .isFoodUnlocked(food.id);
                                final hasStock =
                                    (_inventoryUnits[food.id] ?? 0.0) > 0.0;
                                return GestureDetector(
                                  onTap: () => handleSelectFood(food),
                                  onLongPress: () => _showFoodInfo(food),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                (_plateFoodId == food.id &&
                                                    _plateLevel > 0)
                                                ? AppColors.azulPrincipal
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              food.emoji,
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              food.name,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              _alimentarCubit.stockLabel(
                                                food.id,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 8,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isUnlocked || !hasStock)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                !isUnlocked
                                                    ? 'Bloqueado'
                                                    : 'Sin bolsas',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mesa de madera
  Widget _buildTable() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8B6F47), Color(0xFF6D5736)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A3428), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Textura de madera
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(painter: WoodGrainPainter()),
            ),
          ),

          // BotÃ³n X si hay bolsa activa
          if (_activeBag != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _alimentarCubit.removeBag,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '✕',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_activeBag != null)
            Center(child: _buildDraggableBag(context))
          else
            const Center(
              child: Text(
                'Selecciona comida\nde la alacena',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  /// Mascota animada
  Widget _buildPet() {
    final worldState = context.watch<PetWorldCubit>().state;
    final canShowPet =
        !worldState.isLocationLocked ||
        worldState.location == PetLocation.alimentar;
    final isPlaying = worldState.activity == PetActivity.playing;

    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final petEmoji = (state.mascota?.tipoMascota ?? 'perro').toLowerCase();
        final headItemEmoji = CosmeticCatalog.headEmojiFor(
          state.mascota?.itemCabezaId,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final estaDescansando = context.read<PetCubit>().estaDescansando(
              state.mascota,
            );
            final compact = constraints.maxHeight < 220;
            final veryCompact = constraints.maxHeight < 180;
            final petSize = compact ? 68.0 : 80.0;
            final hatSize = compact ? 24.0 : 28.0;
            final gap = compact ? 8.0 : 16.0;
            final isCat = _isCatType(petEmoji);
            final isDog = _isDogType(petEmoji);
            final bubbleText = !canShowPet
                ? 'Estoy ${_locationLabel(worldState.location)}'
                : (_isEating ? 'Estoy comiendo' : 'Tengo hambre');

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!veryCompact)
                      _bubbleText(
                        bubbleText,
                        fontSize: compact ? 14 : 16,
                        horizontalPadding: compact ? 16 : 24,
                        verticalPadding: compact ? 6 : 8,
                      ),
                    if (!veryCompact) SizedBox(height: gap),
                    _buildFeedingScene(
                      compact: compact,
                      canShowPet: canShowPet,
                      isCat: isCat,
                      isDog: isDog,
                      petEmoji: petEmoji,
                      petSize: petSize,
                      hatSize: hatSize,
                      headItemEmoji: headItemEmoji,
                    ),
                    SizedBox(height: compact ? 12 : 14),
                    _buildFeedButton(
                      compact: compact,
                      estaDescansando: estaDescansando,
                      isPlaying: isPlaying,
                    ),
                    if (_activeBag != null) SizedBox(height: compact ? 10 : 12),
                    if (_activeBag != null)
                      _buildBagHintText(
                        compact: compact,
                        bagName: _activeBag!.name,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bubbleText(
    String text, {
    double fontSize = 16,
    double horizontalPadding = 24,
    double verticalPadding = 8,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize, color: Colors.black87),
      ),
    );
  }

  String _locationLabel(PetLocation location) {
    switch (location) {
      case PetLocation.home:
        return 'en casa';
      case PetLocation.alimentar:
        return 'Aqui';
      case PetLocation.jugar:
        return 'Jugando';
      case PetLocation.dormir:
        return 'durmiendo';
      case PetLocation.curar:
        return 'en el veterianario';
      case PetLocation.banar:
        return 'en el baño';
    }
  }

  bool _isCatType(String petType) {
    final normalized = petType.toLowerCase().trim();
    return normalized == 'gato' || normalized == 'cat';
  }

  bool _isDogType(String petType) {
    final normalized = petType.toLowerCase().trim();
    return normalized == 'perro' || normalized == 'dog';
  }

  Widget _buildPlateSvg({
    required double width,
    required double height,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      'assets/images/plato_vectorized.svg',
      width: width,
      height: height,
      fit: fit,
    );
  }

  Widget _buildFeedingScene({
    required bool compact,
    required bool canShowPet,
    required bool isCat,
    required bool isDog,
    required String petEmoji,
    required double petSize,
    required double hatSize,
    required String? headItemEmoji,
  }) {
    final sceneWidth = compact ? 180.0 : 220.0;
    final sceneHeight = compact ? 175.0 : 215.0;
    final avatarWidth = compact ? petSize + 74 : petSize + 92;
    final avatarHeight = compact ? petSize + 74 : petSize + 92;
    final avatarTopOffset = compact ? -10.0 : -14.0;
    final plateTopOffset = compact ? 96.0 : 118.0;
    final eatingCatWidth = compact ? 96.0 : 112.0;
    final eatingCatHeight = compact ? 96.0 : 112.0;
    final eatingCatBottom = compact ? 12.0 : 14.0;
    final eatingCatRightOffset = compact ? 1.0 : 5.0;
    final eatingDogBottom = compact ? 6.0 : 8.0;
    final eatingDogRightOffset = compact ? 11.0 : 21.0;
    final canShowEatingPet = _isEating && (isCat || isDog);
    final eatingPetAsset = isCat
        ? 'assets/images/gato_comiendo_vectorized.svg'
        : 'assets/images/perro_comiendo_vectorized.svg';
    final eatingPetKey = isCat ? 'pet-eating-cat' : 'pet-eating-dog';
    final eatingPetBottom = isCat ? eatingCatBottom : eatingDogBottom;
    final eatingPetRightOffset = isCat
        ? eatingCatRightOffset
        : eatingDogRightOffset;

    return SizedBox(
      width: sceneWidth,
      height: sceneHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedBuilder(
                animation: _petAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      _isEating ? 0 : _petAnimationController.value * 8,
                    ),
                    child: Transform.rotate(
                      angle: _isEating
                          ? _petAnimationController.value * 0.04
                          : 0,
                      child: child,
                    ),
                  );
                },
                child: Transform.translate(
                  offset: Offset(0, avatarTopOffset),
                  child: SizedBox(
                    width: avatarWidth,
                    height: avatarHeight,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.92,
                              end: 1,
                            ).animate(animation),
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: !canShowPet
                          ? SizedBox(
                              key: const ValueKey('pet-hidden'),
                              width: avatarWidth,
                              height: avatarHeight,
                            )
                          : canShowEatingPet
                          ? Stack(
                              key: ValueKey(eatingPetKey),
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned(
                                  right: eatingPetRightOffset,
                                  bottom: eatingPetBottom,
                                  child: Transform.translate(
                                    // El SVG viene unido, así que simulamos el
                                    // cabeceo de comer con un rebote vertical corto.
                                    offset: Offset(
                                      0,
                                      _petAnimationController.value * 6,
                                    ),
                                    child: SvgPicture.asset(
                                      eatingPetAsset,
                                      width: eatingCatWidth,
                                      height: eatingCatHeight,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              key: const ValueKey('pet-base'),
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                PetAvatarRive(
                                  tipoMascota: petEmoji,
                                  width: avatarWidth,
                                  height: avatarHeight,
                                ),
                                if (headItemEmoji != null)
                                  Positioned(
                                    top: compact ? -8 : -10,
                                    child: Text(
                                      headItemEmoji,
                                      style: TextStyle(fontSize: hatSize),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: plateTopOffset,
            child: _buildPlateVisual(compact: compact),
          ),
        ],
      ),
    );
  }

  Widget _buildPlateVisual({bool compact = false}) {
    final plateWidth = compact ? 136.0 : 162.0;
    final plateHeight = compact ? 88.0 : 104.0;
    final liquidLeftRight = compact ? 28.0 : 34.0;
    final liquidBottom = compact ? 41.0 : 45.0;
    final foodLeftRight = compact ? 18.0 : 22.0;
    final foodBottom = compact ? 42.0 : 46.0;
    final foodHeight = compact ? 38.0 : 44.0;
    final foodEmojiSize = compact ? 17.0 : 20.0;
    final levelBottom = compact ? -1.0 : -2.0;
    final liquidHeight = compact ? 34.0 : 42.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: _plateVisualKey,
          width: plateWidth,
          height: plateHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: _buildPlateSvg(width: plateWidth, height: plateHeight),
              ),
              Positioned(
                left: liquidLeftRight,
                right: liquidLeftRight,
                bottom: liquidBottom,
                child: ClipOval(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: (_plateLevel / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: liquidHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF8AE670).withValues(alpha: 0.55),
                            const Color(0xFFB8F3A7).withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: foodLeftRight,
                right: foodLeftRight,
                bottom: foodBottom,
                child: SizedBox(
                  height: foodHeight,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: -10,
                      alignment: WrapAlignment.center,
                      children: _foodInPlate
                          .map(
                            (emoji) => Text(
                              emoji,
                              style: TextStyle(fontSize: foodEmojiSize),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: levelBottom,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_plateLevel.toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedButton({
    bool compact = false,
    required bool estaDescansando,
    required bool isPlaying,
  }) {
    if (_plateLevel <= 0 || estaDescansando) {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: isPlaying
          ? null
          : () async {
              final petCubit = context.read<PetCubit>();
              final worldCubit = context.read<PetWorldCubit>();
              if (_isEating) {
                await AlimentarController.detenerComidaManual(
                  petCubit: petCubit,
                  worldCubit: worldCubit,
                  plateFoodId: _plateFoodId,
                );
                return;
              }

              await AlimentarController.handleFeedPet(
                alimentarCubit: _alimentarCubit,
                petCubit: petCubit,
                worldCubit: worldCubit,
                plateLevel: _plateLevel,
                plateFoodId: _plateFoodId,
                plateEmoji: _plateEmoji,
              );
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isPlaying
            ? const Color(0xFFD6D6D6)
            : _isEating
            ? const Color(0xFFF07A94)
            : const Color(0xFFA3FF88),
        disabledBackgroundColor: const Color(0xFFD6D6D6),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 24,
          vertical: compact ? 10 : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        _isEating ? 'Detener comida' : 'Que coma',
        style: TextStyle(
          fontSize: compact ? 14 : 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBagHintText({required bool compact, required String bagName}) {
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 180 : 220),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Desliza la bolsa de $bagName sobre el plato para llenarlo',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// Bolsa arrastrable
  Widget _buildDraggableBag(BuildContext context) {
    final bag = _activeBag;
    if (bag == null) return const SizedBox.shrink();
    return Draggable(
      feedback: Material(
        color: Colors.transparent,
        child: _buildBagWidget(context, bag, isDragging: true),
      ),
      childWhenDragging: Container(),
      onDragUpdate: (details) {
        if (AlimentarController.isPointerOverPlate(
          plateVisualKey: _plateVisualKey,
          globalPosition: details.globalPosition,
        )) {
          _alimentarCubit.startPouring(eating: _isEating);
        } else {
          AlimentarController.persistPlateAfterPour(
            alimentarCubit: _alimentarCubit,
            petCubit: context.read<PetCubit>(),
            isEating: _isEating,
          );
        }
      },
      onDragEnd: (_) => AlimentarController.persistPlateAfterPour(
        alimentarCubit: _alimentarCubit,
        petCubit: context.read<PetCubit>(),
        isEating: _isEating,
      ),
      child: _buildBagWidget(context, bag),
    );
  }

  Widget _buildBagWidget(
    BuildContext context,
    FoodCatalogItem food, {
    bool isDragging = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double bagWidth = (screenWidth * 0.28).clamp(80.0, 110.0);
    final double bagHeight = (screenHeight * 0.16).clamp(100.0, 140.0);

    return Container(
      width: bagWidth,
      height: bagHeight,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [food.color, food.color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: food.color, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: isDragging ? 20 : 10,
            offset: Offset(0, isDragging ? 10 : 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Expanded y FittedBox aseguran que el emoji se encoja si la caja es muy pequeÃ±a
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(food.emoji, style: const TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 4),
          // FittedBox para que el nombre de la comida nunca desborde horizontalmente
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              food.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter para textura de azulejos
class TilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const tileSize = 50.0;

    // LÃ­neas verticales
    for (double x = 0; x < size.width; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // LÃ­neas horizontales
    for (double y = 0; y < size.height; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter para textura de madera
class WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // LÃ­neas verticales simulando vetas de madera
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
