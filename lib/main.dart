import 'package:family/services/auth/auth_gate.dart';
import 'package:family/themes/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:family/firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print("Tentative d'initialisation de Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialisé avec succès (nouvelle instance ou déjà existante vérifiée par initializeApp)!");
    //Correction: On enveloppe MyApp avec ChangeNotifierProvider dès le début
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(), // Corrigé en ThemeProvider
        child: const MyApp(),
      ),
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print("Firebase.initializeApp a signalé 'duplicate-app'. L'application est déjà initialisée. On continue.");
      // Si c'est une 'duplicate-app', Firebase est déjà prêt, donc on lance MyApp.
      runApp(
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(), // Corrigé en ThemeProvider
          child: const MyApp(),
        ),
      );
    } else {
      // Pour les autres erreurs Firebase spécifiques, on les affiche.
      print("ERREUR Firebase spécifique lors de l'initialisation: ${e.toString()}");
      runApp(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text("Erreur Firebase: ${e.toString()}"),
          ),
        ),
      ));
    }
  } catch (e) {
    // Pour toute autre exception non-Firebase durant cette phase.
    print("ERREUR générale lors de la configuration de Firebase: ${e.toString()}");
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text("Erreur de configuration Firebase (générale): ${e.toString()}"),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      theme: Provider.of<ThemeProvider>(context).themeData, // Corrigé en ThemeProvider
    );
  }
}
