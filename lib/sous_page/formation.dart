import 'package:flutter/material.dart';

class FormationPage extends StatefulWidget{
  const FormationPage({super.key});
  @override
  State<FormationPage> createState() => _FormationPageState();
}
class _FormationPageState extends State<FormationPage>{
  final TextEditingController _nomController = TextEditingController();
   final TextEditingController _prenomController = TextEditingController();
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("Formation",
        style: TextStyle(color: Colors.orange),
      ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _nomController,
            decoration: InputDecoration(
              labelText: "Entrez votre nom",
              hintText: "Nom",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              )
            ),
          ),
          const SizedBox(height:20),
          TextFormField(
            controller: _prenomController,
            decoration: InputDecoration(
                labelText: "Entrez votre prénom",
                hintText: "Prénom",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                )
            ),
          ),
        ],
      ),
    );
  }
}