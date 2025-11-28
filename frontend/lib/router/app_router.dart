import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/chat/chat_page.dart';
import '../features/home/home_page.dart';
import '../features/settings/settings_page.dart';
import '../features/splash/splash_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _fadePage(state, const SplashPage()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _slideUpPage(state, const LoginPage()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const RegisterPage()),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _fadePage(state, const HomePage()),
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chat',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? 'new';
          return _slideRightPage(state, ChatPage(conversationId: id));
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            _fadePage(state, const SettingsPage()),
      ),
    ],
  );
});

CustomTransitionPage _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage _slideUpPage(GoRouterState state, Widget child) {
  final tween = Tween(begin: const Offset(0, 0.1), end: Offset.zero)
      .chain(CurveTween(curve: Curves.easeOutCubic));
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

CustomTransitionPage _slideRightPage(GoRouterState state, Widget child) {
  final tween = Tween(begin: const Offset(0.1, 0), end: Offset.zero)
      .chain(CurveTween(curve: Curves.easeOutCubic));
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}


