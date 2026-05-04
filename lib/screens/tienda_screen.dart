import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Models/inventario_comida_model.dart';
import '../Models/inventario_cosmeticos_model.dart';
import '../core/app_colors.dart';
import '../core/cosmetic_catalog.dart';
import '../core/food_catalog.dart';
import '../cubit/pet_cubit.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/user_repository.dart';

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final UserRepository _userRepository = UserRepository();

  bool _isLoading = true;
  bool _isBuying = false;
  bool _isEquipping = false;
  int _coins = 0;

  Map<String, double> _foodInventory = {};
  Map<String, bool> _foodUnlocked = {};
  Map<String, bool> _cosmeticInventory = {};
  String _equippedHeadItemId = '';

  @override
  void initState() {
    super.initState();
    _loadEconomy();
  }

  Future<void> _loadEconomy() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _inventoryRepository.ensureDefaultInventory(userId);
      await _userRepository.normalizeLegacyUserDoc(userId);
      final foodInventory = await _inventoryRepository.loadFoodInventory(
        userId,
      );
      final cosmetics = await _inventoryRepository.loadCosmeticsInventory(
        userId,
      );
      final coins = await _userRepository.loadCoins(userId);

      if (!mounted) return;
      final equippedHead =
          context.read<PetCubit>().state.mascota?.itemCabezaId ?? '';
      setState(() {
        _coins = coins;
        _foodInventory = foodInventory.cantidades;
        _foodUnlocked = foodInventory.desbloqueados;
        _cosmeticInventory = cosmetics.poseidos;
        _equippedHeadItemId = equippedHead;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buyFood(FoodCatalogItem item) async {
    if (_isBuying) return;
    if (_coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes monedas suficientes')),
      );
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isBuying = true);
    try {
      final nextCoins = (_coins - item.price).clamp(0, 999999).toInt();
      final nextInventory = <String, double>{..._foodInventory};
      final nextUnlocked = <String, bool>{..._foodUnlocked, item.id: true};
      nextInventory[item.id] =
          (nextInventory[item.id] ?? 0.0) + FoodCatalog.bagUnits;

      await _inventoryRepository.saveFoodInventoryAndCoins(
        userId: userId,
        coins: nextCoins,
        inventory: InventarioComidaModel(
          cantidades: nextInventory,
          desbloqueados: nextUnlocked,
        ),
      );

      if (!mounted) return;
      setState(() {
        _coins = nextCoins;
        _foodInventory = nextInventory;
        _foodUnlocked = nextUnlocked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compraste 1 bolsa de ${item.name}')),
      );
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  Future<void> _buyCosmetic(CosmeticCatalogItem item) async {
    if (_isBuying) return;
    if (_coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes monedas suficientes')),
      );
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isBuying = true);
    try {
      final nextCoins = (_coins - item.price).clamp(0, 999999).toInt();
      final nextCosmetics = <String, bool>{
        ..._cosmeticInventory,
        item.id: true,
      };
      final currentCosmetics = await _inventoryRepository
          .loadCosmeticsInventory(userId);

      await _inventoryRepository.saveCosmeticsInventoryAndCoins(
        userId: userId,
        coins: nextCoins,
        inventory: InventarioCosmeticosModel(
          poseidos: nextCosmetics,
          equipadoEn: currentCosmetics.equipadoEn,
        ),
      );

      if (!mounted) return;
      setState(() {
        _coins = nextCoins;
        _cosmeticInventory = nextCosmetics;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Compraste ${item.name}')));
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  Future<void> _equipCosmetic(CosmeticCatalogItem item) async {
    if (_isEquipping) return;
    if (!(_cosmeticInventory[item.id] ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes comprar este cosmetico')),
      );
      return;
    }

    setState(() => _isEquipping = true);
    final ok = await context.read<PetCubit>().equiparItemCabeza(item.id);
    if (!mounted) return;
    setState(() {
      if (ok) _equippedHeadItemId = item.id;
      _isEquipping = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? '${item.name} equipado en cabeza' : 'No se pudo equipar',
        ),
      ),
    );
  }

  Future<void> _removeHeadCosmetic() async {
    if (_isEquipping) return;
    setState(() => _isEquipping = true);
    await context.read<PetCubit>().quitarItemCabeza();
    if (!mounted) return;
    setState(() {
      _equippedHeadItemId = '';
      _isEquipping = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quitaste el item de la cabeza')),
    );
  }

  String _bagText(double units) {
    final bags = units / FoodCatalog.bagUnits;
    return '${bags.toStringAsFixed(1)} bolsas';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.fondoPrincipal,
      child: SafeArea(
        child: Column(
          children: [
            _TopHeader(
              title: 'Tienda',
              subtitle: 'Compra items del usuario y equipa a tu mascota',
              coins: _coins,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        const _SectionHeader(title: 'Comida'),
                        const SizedBox(height: 10),
                        GridView.builder(
                          itemCount: FoodCatalog.items.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.84,
                              ),
                          itemBuilder: (context, index) {
                            final item = FoodCatalog.items[index];
                            final units = _foodInventory[item.id] ?? 0.0;
                            final unlocked = _foodUnlocked[item.id] ?? false;
                            return _ShopItemCard(
                              emoji: item.emoji,
                              name: item.name,
                              price: item.price,
                              stockLabel: _bagText(units),
                              buttonLabel: unlocked
                                  ? 'Comprar +1 bolsa'
                                  : 'Desbloquear',
                              loading: _isBuying,
                              onPressed: () => _buyFood(item),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        const _SectionHeader(title: 'Accesorios'),
                        const SizedBox(height: 10),
                        GridView.builder(
                          itemCount: CosmeticCatalog.items.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.84,
                              ),
                          itemBuilder: (context, index) {
                            final item = CosmeticCatalog.items[index];
                            final owned = _cosmeticInventory[item.id] ?? false;
                            final equipped = _equippedHeadItemId == item.id;
                            final stockLabel = equipped
                                ? 'En cabeza'
                                : (owned ? 'En inventario' : 'No comprado');

                            final label = !owned
                                ? 'Comprar'
                                : (equipped ? 'Quitar' : 'Poner en cabeza');

                            return _ShopItemCard(
                              emoji: item.emoji,
                              name: item.name,
                              price: item.price,
                              stockLabel: stockLabel,
                              buttonLabel: label,
                              loading: _isBuying || _isEquipping,
                              onPressed: !owned
                                  ? () => _buyCosmetic(item)
                                  : (equipped
                                        ? _removeHeadCosmetic
                                        : () => _equipCosmetic(item)),
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int coins;

  const _TopHeader({
    required this.title,
    required this.subtitle,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0x14000000))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.doradoSuave,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.doradoBorde),
            ),
            child: Text(
              '🪙 $coins',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.doradoTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textoPrincipal,
      ),
    );
  }
}

class _EmojiBox extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final double size;

  const _EmojiBox({
    required this.emoji,
    required this.backgroundColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.48)),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final String emoji;
  final String name;
  final int price;
  final String stockLabel;
  final String buttonLabel;
  final bool loading;
  final VoidCallback onPressed;

  const _ShopItemCard({
    required this.emoji,
    required this.name,
    required this.price,
    required this.stockLabel,
    required this.buttonLabel,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EmojiBox(
            emoji: emoji,
            backgroundColor: const Color(0xFFF5F8FF),
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '🪙 $price',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.doradoTexto,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stockLabel,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.azulPrincipal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
