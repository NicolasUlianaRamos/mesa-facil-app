import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/chat_provider.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/waiter/waiter_home_screen.dart';
import 'screens/kitchen/kitchen_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await StorageService.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MesaFacilApp());
}

class MesaFacilApp extends StatelessWidget {
  const MesaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Mesa Fácil',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        switch (auth.currentUser?.role) {
          case UserRole.waiter:
            return const WaiterHomeScreen();
          case UserRole.kitchen:
            return const KitchenScreen();
          case UserRole.admin:
            return const AdminScreen();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
