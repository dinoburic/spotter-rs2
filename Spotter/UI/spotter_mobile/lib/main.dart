import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/constants/app_colors.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/event_provider.dart';
import 'core/providers/ticket_provider.dart';
import 'core/providers/order_provider.dart';
import 'core/providers/reservation_provider.dart';
import 'core/providers/favorite_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/providers/review_provider.dart';
import 'core/providers/payment_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  if (stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
    Stripe.instance.applySettings();
  }

  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => EventProvider(authProvider.baseProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => TicketProvider(authProvider.baseProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(authProvider.baseProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => ReservationProvider(authProvider.baseProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider(authProvider.baseProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(authProvider.baseProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(authProvider.baseProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(authProvider.baseProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(authProvider.baseProvider),
        ),
      ],
      child: const SpotterApp(),
    ),
  );
}

class SpotterApp extends StatelessWidget {
  const SpotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Spotter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
