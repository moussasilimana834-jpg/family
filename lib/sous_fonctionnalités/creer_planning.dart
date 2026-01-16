import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreerPlanningPage extends StatefulWidget {
  const CreerPlanningPage({super.key});

  @override
  State<CreerPlanningPage> createState() => _CreerPlanningPageState();
}

class _CreerPlanningPageState extends State<CreerPlanningPage> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;

  Future<void> _sauvegarderPlanning() async {
    if (_titreController.text.isEmpty || _selectedDate == null) return;

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('plannings').add({
        'uid': user.uid,
        'titre': _titreController.text,
        'description': _descriptionController.text,
        'date': _selectedDate,
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

  Future<void> _choisirDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: now,
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un planning"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titreController,
              decoration: InputDecoration(
                labelText: "Titre",
                filled: true,

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: "Description",
                filled: true,

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? "Aucune date sélectionnée"
                        : "Date : ${_selectedDate!.toLocal().toString().split(' ')[0]}",
                  ),
                ),
                TextButton.icon(
                  onPressed: _choisirDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("Choisir une date"),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _sauvegarderPlanning,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
