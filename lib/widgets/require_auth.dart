import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class RequireAuth extends StatefulWidget {
  const RequireAuth({super.key, required this.child});

  final Widget child;

  @override
  State<RequireAuth> createState() => _RequireAuthState();
}

class _RequireAuthState extends State<RequireAuth> {
  Future<bool>? _check;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _check ??= context.read<AuthProvider>().checkUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check,
      builder: (context, snapshot) {
        final auth = context.watch<AuthProvider>();

        if (auth.isInitializing || snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        return widget.child;
      },
    );
  }
}
