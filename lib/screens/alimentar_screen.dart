import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../Models/inventario_comida_model.dart';
import '../application/cubits/pet_world_cubit.dart';
import '../core/app_colors.dart';
import '../core/cosmetic_catalog.dart';
import '../core/disaster_system.dart';
import '../core/enums/personalidad_tipo.dart';
import '../core/food_catalog.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/user_repository.dart';
import '../domain/enums/pet_activity.dart';
import '../domain/enums/pet_location.dart';
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
  static const int _defaultMissionRewardCoins = 5;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final UserRepository _userRepository = UserRepository();
  final Random _random = Random();

  late AnimationController _petAnimationController;
  final LayerLink _cupboardLayerLink = LayerLink();

  FoodCatalogItem? activeBag;
  double plateLevel = 0;
  bool eating = false;
  bool cupboardOpen = false;
  bool _loadingData = true;
  int _coins = 0;

  String? _plateFoodId;
  String _plateEmoji = 'ðŸ¥©';
  List<String> foodInPlate = [];

  Map<String, double> _inventoryUnits = {};
  Map<String, bool> _unlockedFoods = {};

  Timer? pouringTimer;
  double _swipeDx = 0.0;

  @override
  void initState() {
    super.initState();
    _petAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _cargarDatos();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncWorldEntry();
      await _ensureLockedEatingState();
    });
  }

  Future<void> _syncWorldEntry() async {
    if (!mounted) return;
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;
    final worldCubit = context.read<PetWorldCubit>();
    final disasterCubit = context.read<DisasterCubit>();
    await worldCubit.syncScreenEntry(
      mascota: mascota,
      location: PetLocation.alimentar,
      fallbackActivity: eating ? PetActivity.eating : PetActivity.idle,
    );
    if (!mounted) return;
    await disasterCubit.verificarDesastre(mascota.idMascota);
  }

  Future<void> _ensureLockedEatingState() async {
    if (!mounted) return;
    final world = context.read<PetWorldCubit>().state;
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;
    if (world.isLocationLocked &&
        world.location == PetLocation.alimentar &&
        world.activity == PetActivity.eating &&
        mascota.nivelPlato > 0 &&
        !mascota.platoComiendo) {
      await context.read<PetCubit>().iniciarComidaPlato();
    }
  }

  Future<void> _syncEatingAnchor({required bool isEatingNow}) async {
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;
    final worldCubit = context.read<PetWorldCubit>();

    if (isEatingNow) {
      await worldCubit.updateWorld(
        mascota: mascota,
        next: worldCubit.state.copyWith(
          location: PetLocation.alimentar,
          activity: PetActivity.eating,
          currentFoodId: _plateFoodId ?? worldCubit.state.currentFoodId,
          clearToy: true,
          isLocationLocked: true,
          isNapTime: false,
          simulatedAt: DateTime.now(),
        ),
      );
      return;
    }

    if (worldCubit.state.isLocationLocked &&
        worldCubit.state.location == PetLocation.alimentar) {
      await worldCubit.updateWorld(
        mascota: mascota,
        next: worldCubit.state.copyWith(
          activity: PetActivity.idle,
          clearFood: true,
          isLocationLocked: false,
          isNapTime: false,
          simulatedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  void dispose() {
    pouringTimer?.cancel();
    _petAnimationController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final userId = _auth.currentUser?.uid;
    final pet = context.read<PetCubit>().state.mascota;
    if (pet != null) {
      plateLevel = pet.nivelPlato;
      eating = pet.platoComiendo;
      if (pet.platoAlimentoId.isNotEmpty) {
        _plateFoodId = pet.platoAlimentoId;
        _plateEmoji = pet.platoEmoji.isNotEmpty
            ? pet.platoEmoji
            : (FoodCatalog.byId(pet.platoAlimentoId)?.emoji ?? _plateEmoji);
      }
      _syncFoodInPlate();
    }

    if (userId == null) {
      if (!mounted) return;
      setState(() => _loadingData = false);
      return;
    }

    try {
      await _inventoryRepository.ensureDefaultInventory(userId);
      await _userRepository.normalizeLegacyUserDoc(userId);
      final inventory = await _inventoryRepository.loadFoodInventory(userId);
      final coins = await _userRepository.loadCoins(userId);

      if (!mounted) return;
      setState(() {
        _coins = coins;
        _inventoryUnits = inventory.cantidades;
        _unlockedFoods = inventory.desbloqueados;
        _loadingData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingData = false);
    }
  }

  void _syncFoodInPlate() {
    final pieces = (plateLevel / 20).ceil().clamp(0, 5).toInt();
    foodInPlate = List<String>.generate(pieces, (_) => _plateEmoji);
  }

  bool _isFoodUnlocked(String id) => _unlockedFoods[id] ?? false;

  bool _canUseFood(String id) =>
      _isFoodUnlocked(id) && (_inventoryUnits[id] ?? 0.0) > 0.0;

  Future<void> _persistInventoryAndPlate() async {
    final petCubit = context.read<PetCubit>();
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _inventoryRepository.saveFoodInventoryAndCoins(
        userId: userId,
        coins: _coins,
        inventory: InventarioComidaModel(
          cantidades: _inventoryUnits,
          desbloqueados: _unlockedFoods,
        ),
      );
    }

    await petCubit.actualizarEstadoPlato(
      nivelPlato: plateLevel,
      platoAlimentoId: plateLevel > 0 ? _plateFoodId : null,
      clearPlatoAlimentoId: plateLevel <= 0,
      platoEmoji: plateLevel > 0 ? _plateEmoji : null,
      clearPlatoEmoji: plateLevel <= 0,
      platoComiendo: eating,
      platoActualizado: DateTime.now(),
    );
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
    if (eating) return;

    if (!_isFoodUnlocked(food.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ese alimento estÃ¡ bloqueado. CÃ³mpralo en Tienda.'),
        ),
      );
      return;
    }

    if ((_inventoryUnits[food.id] ?? 0.0) <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No tienes bolsas de ${food.name}.')),
      );
      return;
    }

    if (plateLevel > 0 && _plateFoodId != null && _plateFoodId != food.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero termina el alimento que ya estÃ¡ en el plato.',
          ),
        ),
      );
      return;
    }

    setState(() {
      activeBag = food;
      cupboardOpen = false;
      _plateFoodId ??= food.id;
      _plateEmoji = food.emoji;
    });
  }

  void startPouring() {
    final bag = activeBag;
    if (bag == null || eating || plateLevel >= 100 || pouringTimer != null) {
      return;
    }
    if (!_canUseFood(bag.id)) return;

    if (_plateFoodId != null && _plateFoodId != bag.id && plateLevel > 0) {
      return;
    }

    _plateFoodId = bag.id;
    _plateEmoji = bag.emoji;

    pouringTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final currentUnits = _inventoryUnits[bag.id] ?? 0.0;
      if (currentUnits <= 0.0 || plateLevel >= 100) {
        stopPouring();
        return;
      }

      const plateStep = 2.0;
      final plateAvailable = 100.0 - plateLevel;
      final plateIncrease = min(plateStep, plateAvailable);
      final bagCost = plateIncrease * FoodCatalog.bagUsagePerPlatePercent;

      setState(() {
        if (currentUnits >= bagCost) {
          plateLevel = (plateLevel + plateIncrease).clamp(0, 100);
          _inventoryUnits[bag.id] = (currentUnits - bagCost)
              .clamp(0, 99999)
              .toDouble();
        } else {
          final possibleIncrease =
              currentUnits / FoodCatalog.bagUsagePerPlatePercent;
          plateLevel = (plateLevel + possibleIncrease).clamp(0, 100);
          _inventoryUnits[bag.id] = 0.0;
        }
        _syncFoodInPlate();
      });

      if ((_inventoryUnits[bag.id] ?? 0.0) <= 0.0 || plateLevel >= 100) {
        stopPouring();
      }
    });
  }

  Future<void> stopPouring() async {
    pouringTimer?.cancel();
    pouringTimer = null;
    await _persistInventoryAndPlate();
  }

  void removeBag() {
    setState(() {
      activeBag = null;
    });
  }

  Future<void> handleFeedPet() async {
    if (plateLevel <= 0 || _plateFoodId == null) return;

    final petCubit = context.read<PetCubit>();
    final estadoDescanso =
        petCubit.state.mascota?.estadoDescanso ?? 'despierto';
    final estaDescansando =
        estadoDescanso == 'dormido' ||
        estadoDescanso == 'acostado' ||
        estadoDescanso == 'siesta';
    if (estaDescansando) return;

    final personalidad =
        petCubit.state.mascota?.personalidad ?? PersonalidadTipo.jugueton;
    final isJugueton = personalidad == PersonalidadTipo.jugueton;
    final isTravieso = personalidad == PersonalidadTipo.travieso;
    final throwProbability = isTravieso ? 0.45 : (isJugueton ? 0.30 : 0.0);

    if (throwProbability > 0 && _random.nextDouble() <= throwProbability) {
      await _tirarComida();
      final item = FoodCatalog.byId(_plateFoodId);
      final puntos = ((item?.hungerPoints ?? 15) * 0.2).round();
      await petCubit.alimentar(
        puntos,
        emojiAlimento: _plateEmoji,
        skipDisasterRoll: true,
      );
      await petCubit.detenerComidaPlato();
      return;
    }

    setState(() => eating = true);
    await petCubit.iniciarComidaPlato();
    await _syncEatingAnchor(isEatingNow: true);
  }

  Future<void> _detenerComidaManual() async {
    setState(() => eating = false);
    await context.read<PetCubit>().detenerComidaPlato();
    await _syncEatingAnchor(isEatingNow: false);
  }

  Future<void> _tirarComida() async {
    final cantidad = 5 + _random.nextInt(4);
    final petCubit = context.read<PetCubit>();
    final disasterCubit = context.read<DisasterCubit>();
    final mascotaId = petCubit.state.mascota?.idMascota;
    if (mascotaId == null) return;

    setState(() {
      plateLevel = 0;
      _plateFoodId = null;
      foodInPlate.clear();
      eating = false;
    });

    await _crearMisionRecoger();
    if (!mounted) return;
    await disasterCubit.generarDesastre(
      mascotaId: mascotaId,
      tipo: DisasterType.comida,
      emoji: _plateEmoji,
      cantidad: cantidad,
      pantalla: disasterScreenAlimentar,
    );
    if (!mounted) return;
    petCubit.actualizarEstadoPlato(
      nivelPlato: 0,
      clearPlatoAlimentoId: true,
      clearPlatoEmoji: true,
      platoComiendo: false,
      platoActualizado: DateTime.now(),
    );
  }

  Future<void> _crearMisionRecoger() async {
    final userId = _auth.currentUser?.uid;
    final mascotaId = context.read<PetCubit>().state.mascota?.idMascota;
    if (userId == null || mascotaId == null) return;

    await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(mascotaId)
        .collection('misiones_activas')
        .doc('recoger_comida')
        .set({
          'tipo': 'recoger_comida',
          'reward_coins': _defaultMissionRewardCoins,
          'estado': 'pendiente',
          'emoji': _plateEmoji,
          'fecha_asignada': Timestamp.now(),
          'fecha_completada': null,
          'streak': 0,
        }, SetOptions(merge: true));
  }

  String _stockLabel(String foodId) {
    final units = _inventoryUnits[foodId] ?? 0.0;
    final bags = (units / FoodCatalog.bagUnits).toStringAsFixed(1);
    return '$bags bolsas';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PetCubit, PetState>(
      listenWhen: (previous, current) {
        return previous.mascota?.nivelPlato != current.mascota?.nivelPlato ||
            previous.mascota?.platoComiendo != current.mascota?.platoComiendo ||
            previous.mascota?.platoAlimentoId !=
                current.mascota?.platoAlimentoId ||
            previous.mascota?.platoEmoji != current.mascota?.platoEmoji;
      },
      listener: (context, state) async {
        if (pouringTimer != null) return;
        final mascota = state.mascota;
        if (mascota == null) return;
        if (!mounted) return;
        setState(() {
          plateLevel = mascota.nivelPlato;
          eating = mascota.platoComiendo;
          _plateFoodId = mascota.platoAlimentoId.isEmpty
              ? null
              : mascota.platoAlimentoId;
          if (mascota.platoEmoji.isNotEmpty) {
            _plateEmoji = mascota.platoEmoji;
          } else if (_plateFoodId != null) {
            _plateEmoji = FoodCatalog.byId(_plateFoodId)?.emoji ?? _plateEmoji;
          }
          _syncFoodInPlate();
        });
        await _syncEatingAnchor(
          isEatingNow: mascota.platoComiendo && mascota.nivelPlato > 0,
        );
      },
      child: Scaffold(
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

            if (isIntentionalLeftSwipe) {
              context.go('/home');
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
                        barColors: const [Color(0xFFF0C77A), Color(0xFFFFD166)],
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
                              border: Border.all(color: AppColors.doradoBorde),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                              _buildPlate(),
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
                                final isUnlocked = _isFoodUnlocked(food.id);
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
                                                    plateLevel > 0)
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
                                              _stockLabel(food.id),
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

          // Botón X si hay bolsa activa
          if (activeBag != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: removeBag,
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
          if (activeBag != null)
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
    if (!canShowPet) return const SizedBox.shrink();

    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final petEmoji = (state.mascota?.tipoMascota ?? 'perro').toLowerCase();
        final headItemEmoji = CosmeticCatalog.headEmojiFor(
          state.mascota?.itemCabezaId,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 220;
            final veryCompact = constraints.maxHeight < 180;
            final petSize = compact ? 68.0 : 80.0;
            final hatSize = compact ? 24.0 : 28.0;
            final gap = compact ? 8.0 : 16.0;
            final bubbleText = eating
                ? 'Estoy comiendo'
                : (plateLevel == 0 ? 'Tengo hambre' : null);

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _petAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            eating ? 0 : _petAnimationController.value * 8,
                          ),
                          child: Transform.rotate(
                            angle: eating
                                ? _petAnimationController.value * 0.1
                                : 0,
                            child: child,
                          ),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          PetAvatarRive(
                            tipoMascota: petEmoji,
                            width: petSize + 46,
                            height: petSize + 46,
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
                    if (bubbleText != null && !veryCompact)
                      SizedBox(height: gap),
                    if (bubbleText != null && !veryCompact)
                      _bubbleText(
                        bubbleText,
                        fontSize: compact ? 14 : 16,
                        horizontalPadding: compact ? 16 : 24,
                        verticalPadding: compact ? 6 : 8,
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

  Widget _buildPlate() {
    final estadoDescanso = context.select(
      (PetCubit cubit) => cubit.state.mascota?.estadoDescanso ?? 'despierto',
    );
    final estaDescansando =
        estadoDescanso == 'dormido' ||
        estadoDescanso == 'acostado' ||
        estadoDescanso == 'siesta';

    return Column(
      children: [
        if (plateLevel > 0 && !estaDescansando)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: eating ? _detenerComidaManual : handleFeedPet,
              style: ElevatedButton.styleFrom(
                backgroundColor: eating
                    ? const Color(0xFFF07A94)
                    : const Color(0xFFA3FF88),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                eating ? 'Detener comida' : 'Que coma',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        Container(
          width: 180,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF5F5F5)],
            ),
            borderRadius: const BorderRadius.all(Radius.elliptical(90, 45)),
            border: Border.all(color: Colors.grey[400]!, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(90, 45),
                  ),
                  child: Container(
                    height: 90 * (plateLevel / 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF8AE670).withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 20,
                      right: 20,
                    ),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: -10,
                      alignment: WrapAlignment.center,
                      children: foodInPlate
                          .map(
                            (emoji) => Text(
                              emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Indicador de nivel
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${plateLevel.toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// Bolsa arrastrable
  Widget _buildDraggableBag(BuildContext context) {
    final bag = activeBag;
    if (bag == null) return const SizedBox.shrink();
    return Draggable(
      feedback: Material(
        color: Colors.transparent,
        child: _buildBagWidget(context, bag, isDragging: true),
      ),
      childWhenDragging: Container(),
      onDragUpdate: (details) {
        final screenHeight = MediaQuery.of(context).size.height;
        final plateAreaY = screenHeight * 0.75;
        if (details.globalPosition.dy > plateAreaY - 50) {
          startPouring();
        } else {
          stopPouring();
        }
      },
      onDragEnd: (_) => stopPouring(),
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
          // Expanded y FittedBox aseguran que el emoji se encoja si la caja es muy pequeña
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

    // Líneas verticales
    for (double x = 0; x < size.width; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Líneas horizontales
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

    // Líneas verticales simulando vetas de madera
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
