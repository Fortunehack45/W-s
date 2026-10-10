import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design_system/tokens.dart';
import 'routing/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: WsApp(),
    ),
  );
}

class WsApp extends StatelessWidget {
  const WsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "W's",
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: WsTokens.surfaceBlack,
        colorScheme: const ColorScheme.dark(
          primary: WsTokens.brandGold,
          secondary: WsTokens.brandEmerald,
          surface: WsTokens.surfaceElevated,
          error: WsTokens.brandRose,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: WsTokens.textPrimary,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
        dividerColor: WsTokens.divider,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: WsTokens.surfaceBlack,
          selectedItemColor: WsTokens.brandGold,
          unselectedItemColor: WsTokens.textMuted,
        ),
      ),
    );
  }
}
