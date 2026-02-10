import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:momentofiscal/core/models/user.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:momentofiscal/pages/login/auth_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'core/services/billing/in_app_purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Função que retorna a página inicial com base no token armazenado
  Future<Widget> _getInitialPage() async {
    // Recupera o token usando o FlutterSecureStorage
    User? user = await AuthRailsService().loadUserFromCache();

    final configuration = PurchasesConfiguration(ApiConstants.appleKey)
      ..appUserID = user?.id;

    if (!kIsWeb && Platform.isIOS) {
      await Purchases.configure(configuration);
    }

    // InAppPurchase only works on mobile platforms
    if (!kIsWeb) {
      InAppPurchaseService.instance.initialize();
    }

    if (user != null) {
      return const DashboadPage();
    } else {
      return const AuthPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Indicador de carregamento
        } else {
          return MaterialApp(
            title: 'Momento Fiscal',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: colorPrimaty),
              useMaterial3: true,
            ),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'),
            ],
            home: snapshot.data ?? const AuthPage(),
          );
        }
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:momentofiscal/core/utilities/api_constants.dart';
// import 'package:momentofiscal/core/utilities/styles_constants.dart';
// import 'package:momentofiscal/pages/login/auth_page.dart';

// void main() async {
//   await _setup();
//   runApp(const MyApp());
// }

// Future<void> _setup() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   Stripe.publishableKey = ApiConstants.stripePublishableKey;
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Momento Fiscal',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: colorPrimaty),
//         useMaterial3: true,
//       ),
//       localizationsDelegates: const [
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       supportedLocales: const [
//         Locale('pt', 'BR'),
//       ],
//       home: const AuthPage(),
//     );
//   }
// }
