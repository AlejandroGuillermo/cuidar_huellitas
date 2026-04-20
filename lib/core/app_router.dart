import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/adopcion_screen.dart';
import '../screens/home_screen.dart';
import '../screens/alimentar_screen.dart';
import '../screens/jugar_screen.dart';
import '../screens/dormir_screen.dart';
import '../screens/banar_screen.dart';

// ── Nombres de rutas como constantes ──────────────────────
// Siempre usa estas constantes en lugar de strings sueltos.
// Si renombras una ruta, solo cambias aquí y funciona en toda la app.
class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const adopcion = '/adopcion';
  static const home = '/home';
  static const tienda = '/home/tienda';
  static const retos = '/home/retos';
  static const logros = '/home/logros';
  static const ar = '/home/mascota/ar';

  static const alimentar = '/home/alimentar';
  static const jugar = '/home/jugar';
  static const dormir = '/home/dormir';
  static const banar = '/home/banar';
}

// ── Router principal ───────────────────────────────────────
final appRouter = GoRouter(
  initialLocation: AppRoutes.login,

  // ── Redirect global ──────────────────────────────────────
  // Aquí decides a dónde va el usuario según su estado.
  // Por ahora siempre va al login.
  // Cuando integres Firebase Auth, reemplaza la lógica aquí.
  redirect: (context, state) {
    // revisar si el usuario está logueado
    // final logueado = FirebaseAuth.instance.currentUser != null;
    // if (!logueado) return AppRoutes.login;

    // revisar si ya tiene mascota
    // if (logueado && !tieneMascota) return AppRoutes.adopcion;

    return null; // null = sin redirección, sigue normal
  },

  routes: [
    // ── Rutas sin nav bar ──────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.adopcion,
      name: 'adopcion',
      builder: (context, state) => const AdopcionScreen(),
    ),

    // ── ShellRoute — pantallas con nav bar ─────────────────
    // El ShellRoute envuelve las 3 tabs con la barra inferior.
    // Cada tab es una subruta. La nav bar siempre está visible.
    ShellRoute(
      builder: (context, state, child) =>
          _NavBarShell(state: state, child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'mascota/ar',
              name: 'ar',
              builder: (context, state) => const Placeholder(), // ArScreen
            ),
            GoRoute(
              path: 'alimentar',
              name: 'alimentar',
              // Esta ruta se activa al pulsar el botón de alimentar en HomeScreen.
              pageBuilder: (context, state) {
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: const AlimentarScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        // Animación de deslizamiento desde la derecha
                        const begin = Offset(
                          -1.0,
                          0.0,
                        ); // Empieza fuera de la pantalla a la derecha
                        const end = Offset.zero; // Termina en el centro
                        const curve = Curves.easeInOut;

                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                );
              },
            ),
            GoRoute(
              path: 'dormir',
              name: 'dormir',
              pageBuilder: (context, state) {
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: const DormirScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        // La deslizamos desde la izquierda para variar, o desde donde quieras
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                );
              },
            ),
            GoRoute(
              path: 'banar',
              name: 'banar',
              pageBuilder: (context, state) {
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: const BanarScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        final tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.tienda,
          name: 'tienda',
          builder: (context, state) => const Placeholder(), // TiendaScreen
        ),
        GoRoute(
          path: AppRoutes.retos,
          name: 'retos',
          builder: (context, state) => const Placeholder(), // RetosScreen
        ),
        GoRoute(
          path: AppRoutes.jugar,
          name: 'jugar',
          builder: (context, state) => const JugarScreen(),
        ),
        GoRoute(
          path: AppRoutes.logros,
          name: 'logros',
          builder: (context, state) => const Placeholder(), // LogrosScreen
        ),
      ],
    ),
  ],
);

// ── Nav bar shell ──────────────────────────────────────────
// Widget que envuelve el contenido de cada tab con la barra inferior.
// Cuando agregas una nueva pantalla al ShellRoute, solo añades
// un BottomNavigationBarItem aquí — nada más cambia.
class _NavBarShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const _NavBarShell({required this.child, required this.state});

  // Determina cuál tab está activa según la ruta actual
  int _indexActual() {
    final location = state.uri.toString();
    if (location.startsWith(AppRoutes.tienda)) return 0;
    if (location.startsWith(AppRoutes.retos)) return 1;
    if (location.startsWith(AppRoutes.jugar)) return 3;
    if (location.startsWith(AppRoutes.logros)) return 4;
    return 2; // home/mascota por defecto
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexActual(),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.verdePrincipal,
        unselectedItemColor: AppColors.azulClaro,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.tienda);
              break;
            case 1:
              context.go(AppRoutes.retos);
              break;
            case 2:
              context.go(AppRoutes.home);
              break;
            case 3:
              context.go(AppRoutes.jugar);
              break;
            case 4:
              context.go(AppRoutes.logros);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined, size: 32),
            label: 'Tienda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined, size: 32),
            label: 'Retos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets, size: 32),
            label: 'Mascota',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.toys_outlined, size: 32),
            label: 'Jugar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events, size: 32),
            label: 'Logros',
          ),
        ],
      ),
    );
  }
}
