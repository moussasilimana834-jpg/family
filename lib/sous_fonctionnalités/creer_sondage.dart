import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class CreerSondagePage extends StatefulWidget {
  const CreerSondagePage({super.key});

  @override
  State<CreerSondagePage> createState() => _CreerSondagePageState();
}

class _CreerSondagePageState extends State<CreerSondagePage> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _options = [TextEditingController()];
  bool _loading = false;

  void _ajouterOption() {
    setState(() {
      _options.add(TextEditingController());
    });
  }

  Future<void> _publierSondage() async {
    if (_questionController.text.isEmpty ||
        _options.any((o) => o.text.isEmpty)) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final sondageId = const Uuid().v4();

      await FirebaseFirestore.instance.collection('sondages').doc(sondageId).set({
        'uid': user.uid,
        'question': _questionController.text,
        'options': _options.map((e) => e.text).toList(),
        'votes': List.generate(_options.length, (_) => 0),
        'timestamp': Timestamp.now(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un sondage"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: "Question du sondage",
                filled: true,

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            Column(
              children: List.generate(_options.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: TextField(
                    controller: _options[index],
                    decoration: InputDecoration(
                      labelText: "Option ${index + 1}",
                      filled: true,

                      border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _ajouterOption,
              icon: const Icon(Icons.add),
              label: const Text("Ajouter une option"),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _publierSondage,
              icon: const Icon(Icons.send),
              label: const Text("Publier le sondage"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
