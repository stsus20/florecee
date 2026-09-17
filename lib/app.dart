import 'package:flutter/material.dart';

import 'services/app_store.dart';
import 'screens/inicio_screen.dart';
import 'screens/calendario_screen.dart';
import 'screens/diagnostico_screen.dart';
import 'screens/catalogo_screen.dart';
import 'widgets/planta_card.dart';
import 'widgets/entrada_suave.dart';

class FloreceApp extends StatelessWidget {
  const FloreceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Florece',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: crema,
      colorScheme: ColorScheme.fromSeed(seedColor: verde, surface: crema)
          .copyWith(
            primary: verde,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFD6EDB9),
            secondary: const Color(0xFFAC573B),
            secondaryContainer: const Color(0xFFFFE1C4),
          ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFDFA),
        indicatorColor: const Color(0xFFD6EDB9),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: verde,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: crema,
        foregroundColor: verde,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFDFA),
        elevation: 0.5,
        shadowColor: const Color(0x15365F45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE9E5DC)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFEFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD7E1CB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: verde, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF183B2C),
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF183B2C),
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF183B2C),
        ),
      ),
    ),
    home: const InicioApp(),
  );
}

class InicioApp extends StatefulWidget {
  const InicioApp({super.key});
  @override
  State<InicioApp> createState() => _InicioAppState();
}

class _InicioAppState extends State<InicioApp> with WidgetsBindingObserver {
  final store = AppStore();
  int index = 0;
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  Future<void> init() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await Future.wait([
        store.initialize(),
        if (!WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations)
          Future<void>.delayed(const Duration(milliseconds: 700)),
      ]);
    } catch (e) {
      error = 'No pudimos abrir los datos locales. Comprueba el espacio disponible y vuelve a intentar. Esta versión requiere Android o iOS.';
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !loading && error == null) {
      store.reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const FloreceSplash();
    }
    if (error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: init,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: EntradaSuave(
                key: ValueKey(index),
                child: [
                  InicioScreen(store: store),
                  CalendarioScreen(store: store),
                  DiagnosticoScreen(store: store),
                  CatalogoScreen(store: store),
                ][index],
              ),
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (v) => setState(() => index = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Calendario',
            ),
            NavigationDestination(
              icon: Icon(Icons.eco_outlined),
              label: 'Diagnóstico',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Catálogo',
            ),
          ],
        ),
      ),
    );
  }
}
