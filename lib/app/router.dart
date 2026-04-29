import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/debts/presentation/debts_dashboard_screen.dart';
import '../features/farmers/presentation/create_farmer_screen.dart';
import '../features/farmers/presentation/farmers_search_screen.dart';
import '../features/home/home_shell.dart';
import '../features/products/presentation/products_browse_screen.dart';
import '../features/repayments/presentation/repayment_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (!auth.restored) return null;
      final loggingIn = state.matchedLocation == '/login';
      if (!auth.isAuthenticated) return loggingIn ? null : '/login';
      if (loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeShell()),
      GoRoute(
        path: '/farmers',
        builder: (context, state) {
          final picker = state.uri.queryParameters['picker'] == '1';
          return FarmersSearchScreen(picker: picker);
        },
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const CreateFarmerScreen(),
          ),
        ],
      ),
      GoRoute(path: '/catalog', builder: (_, __) => const ProductsBrowseScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(
        path: '/debts',
        builder: (context, state) {
          final fid = state.uri.queryParameters['farmer_id'];
          return DebtsDashboardScreen(farmerId: fid == null ? null : int.tryParse(fid));
        },
      ),
      GoRoute(
        path: '/repayment',
        builder: (context, state) {
          final fid = state.uri.queryParameters['farmer_id'];
          final id = int.tryParse(fid ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('farmer_id requis')),
            );
          }
          return RepaymentScreen(farmerId: id);
        },
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this.ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}
