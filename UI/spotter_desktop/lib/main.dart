import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/navigator_key.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/base_provider.dart';
import 'core/providers/city_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/venue_provider.dart';
import 'core/providers/event_provider.dart';
import 'core/providers/ticket_type_provider.dart';
import 'core/providers/order_provider.dart';
import 'core/providers/ticket_provider.dart';
import 'core/providers/review_provider.dart';
import 'core/providers/reservation_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/providers/system_setting_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() {
  runApp(const SpotterAdminApp());
}

class SpotterAdminApp extends StatelessWidget {
  const SpotterAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CityProvider>(
          create: (ctx) =>
              CityProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (ctx) =>
              CategoryProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, VenueProvider>(
          create: (ctx) =>
              VenueProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EventProvider>(
          create: (ctx) =>
              EventProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TicketTypeProvider>(
          create: (ctx) =>
              TicketTypeProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (ctx) =>
              OrderProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TicketProvider>(
          create: (ctx) =>
              TicketProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReviewProvider>(
          create: (ctx) =>
              ReviewProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReservationProvider>(
          create: (ctx) =>
              ReservationProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (ctx) =>
              UserProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (ctx) =>
              DashboardProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SystemSettingProvider>(
          create: (ctx) =>
              SystemSettingProvider(BaseProvider(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Spotter Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
          ),
        ),
        home: const _AuthWrapper(),
      ),
    );
  }
}

class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await context.read<AuthProvider>().tryAutoLogin();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final auth = context.watch<AuthProvider>();
    return auth.isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}
