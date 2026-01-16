import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreerReunionPage extends StatefulWidget {
  const CreerReunionPage({super.key});

  @override
  State<CreerReunionPage> createState() => _CreerReunionPageState();
}

class _CreerReunionPageState extends State<CreerReunionPage> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _heure;
  bool _loading = false;

  Future<void> _choisirDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _choisirHeure() async {
    final heure = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (heure != null) setState(() => _heure = heure);
  }

  Future<void> _creerReunion() async {
    if (_titreController.text.isEmpty || _date == null || _heure == null) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('reunions').add({
        'uid': user.uid,
        'titre': _titreController.text,
        'description': _descriptionController.text,
        'participants':
        _participantsController.text.split(',').map((e) => e.trim()).toList(),
        'date': _date,
        'heure': _heure!.format(context),
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
        title: const Text("Planifier une réunion"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titreController,
              decoration: InputDecoration(
                labelText: "Titre de la réunion",
                filled: true,

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                filled: true,

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _participantsController,
              decoration: InputDecoration(
                labelText: "Participants (emails séparés par des virgules)",
                filled: true,

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _date == null
                        ? "Date non choisie"
                        : "📅 ${_date!.toLocal().toString().split(' ')[0]}",
                  ),
                ),
                TextButton.icon(
                  onPressed: _choisirDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Choisir date"),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _heure == null
                        ? "Heure non choisie"
                        : "🕒 ${_heure!.format(context)}",
                  ),
                ),
                TextButton.icon(
                  onPressed: _choisirHeure,
                  icon: const Icon(Icons.access_time),
                  label: const Text("Choisir heure"),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _creerReunion,
              icon: const Icon(Icons.people),
              label: const Text("Créer la réunion"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
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
