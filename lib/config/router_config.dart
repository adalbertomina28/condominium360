import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/screens.dart';
import '../services/services.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/reservations',
        builder: (context, state) => const ReservationScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Soporte')),
          body: const Center(child: Text('Pantalla de Soporte - En desarrollo')),
        ),
      ),
      GoRoute(
        path: '/community',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Comunidad')),
          body: const Center(child: Text('Pantalla de Comunidad - En desarrollo')),
        ),
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Pagos')),
          body: const Center(child: Text('Pantalla de Pagos - En desarrollo')),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Configuración')),
          body: const Center(child: Text('Pantalla de Configuración - En desarrollo')),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Recuperar Contraseña')),
          body: const Center(child: Text('Pantalla de Recuperación de Contraseña - En desarrollo')),
        ),
      ),
    ],
    redirect: (context, state) async {
      // Verificar si el usuario está autenticado
      final isAuthenticated = SupabaseService.client.auth.currentUser != null;
      
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      
      // Si el usuario no está autenticado y no está en la pantalla de login o registro, redirigir a login
      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
        return '/login';
      }
      
      // Si el usuario está autenticado y está en la pantalla de login o registro, redirigir al dashboard
      if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
        return '/dashboard';
      }
      
      // En cualquier otro caso, no redirigir
      return null;
    },
  );
}
