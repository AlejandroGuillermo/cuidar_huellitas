import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/adopcion_screen.dart';


// ── Nombres de rutas como constantes ──────────────────────
// Siempre usa estas constantes en lugar de strings sueltos.
// Si renombras una ruta, solo cambias aquí y funciona en toda la app.
class AppRoutes {
  static const login    = '/login';
  static const register = '/register';
  static const adopcion = '/adopcion';
  static const home     = '/home';
  static const aprende  = '/home/aprende';
  static const logros   = '/home/logros';
  static const ar       = '/home/mascota/ar';
}

// ── Router principal ───────────────────────────────────────
final appRouter = GoRouter(
  initialLocation: AppRoutes.login,

  // ── Redirect global ──────────────────────────────────────
  // Aquí decides a dónde va el usuario según su estado.
  // Por ahora siempre va al login.
  // Cuando integres Firebase Auth, reemplaza la lógica aquí.
  redirect: (context, state) {
    // TODO: revisar si el usuario está logueado
    // final logueado = FirebaseAuth.instance.currentUser != null;
    // if (!logueado) return AppRoutes.login;

    // TODO: revisar si ya tiene mascota
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
      builder: (context, state, child) {
        return _NavBarShell(child: child, state: state);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const Placeholder(), // TODO: HomeScreen
          routes: [
            GoRoute(
              path: 'mascota/ar',
              name: 'ar',
              builder: (context, state) => const Placeholder(), // TODO: ArScreen
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.aprende,
          name: 'aprende',
          builder: (context, state) => const Placeholder(), // TODO: EducacionScreen
        ),
        GoRoute(
          path: AppRoutes.logros,
          name: 'logros',
          builder: (context, state) => const Placeholder(), // TODO: LogrosScreen
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
    if (location.startsWith(AppRoutes.aprende)) return 1;
    if (location.startsWith(AppRoutes.logros))  return 2;
    return 0; // home/mascota por defecto
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexActual(),
        selectedItemColor: const Color(0xFF8AE670),
        unselectedItemColor: const Color(0xFF73726C),
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          switch (index) {
            case 0: context.go(AppRoutes.home);    break;
            case 1: context.go(AppRoutes.aprende); break;
            case 2: context.go(AppRoutes.logros);  break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Text('🐾', style: TextStyle(fontSize: 22)),
            label: 'Mascota',
          ),
          BottomNavigationBarItem(
            icon: Text('📚', style: TextStyle(fontSize: 22)),
            label: 'Aprende',
          ),
          BottomNavigationBarItem(
            icon: Text('🏆', style: TextStyle(fontSize: 22)),
            label: 'Logros',
          ),
        ],
      ),
    );
  }
}
