import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangerMotDePassePage extends StatefulWidget {
  const ChangerMotDePassePage({super.key});

  @override
  State<ChangerMotDePassePage> createState() => _ChangerMotDePassePageState();
}

class _ChangerMotDePassePageState extends State<ChangerMotDePassePage> {
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _changerMotDePasse() async {
    final newPassword = _passwordController.text.trim();
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le mot de passe doit contenir au moins 6 caractères")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mot de passe mis à jour")),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Changer le mot de passe")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nouveau mot de passe"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changerMotDePasse,
              child: const Text("Changer"),
            )
          ],
        ),
      ),
    );
  }
}
