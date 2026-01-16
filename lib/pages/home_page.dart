import 'package:flutter/material.dart';
import 'package:family/components/my_drawer.dart';
import 'package:family/services/auth/auth_service.dart'; // Gardé pour le titre de l'AppBar

// --- NOUVELLES IMPORTATIONS ---
// Assurez-vous que les chemins d'accès sont corrects par rapport à votre structure de projet.
import 'package:family/barres/accueil.dart'; // Remplace l'ancienne "PublicationsPage"
import 'package:family/barres/live.dart';
import 'package:family/pages/chat_list_page.dart'; // MODIFIÉ
import 'package:family/barres/Profile.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // La liste des pages est maintenant corrigée pour utiliser MoiPage
  static final List<Widget> _pages = <Widget>[
    AccueilPage(),      // 0 - Page depuis accueil.dart
   const  LivePage(),         // 1 - Page depuis live.dart
    const ChatListPage(),     // 2 - Page pour afficher la liste des utilisateurs -> MODIFIÉ
     MoiPage(),     // 3 - Page depuis moi.dart -> CORRIGÉ
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // MODIFIÉ : La méthode renvoie maintenant un Widget complet
        title: _getAppBarTitleWidget(),

        // --- CHANGEMENTS ICI ---
        backgroundColor: Colors.transparent, // ou Colors.white, selon votre design
        // Couleur par défaut pour les icônes (ex: drawer)
        // foregroundColor: Colors.white, // LIGNE SUPPRIMÉE
        elevation: 0,
      ),

      drawer: const MyDrawer(),
      body: _pages[_selectedIndex], // Le corps de la page change en fonction de l'index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'profil',
          ),
        ],
      ),
    );
  }
  Widget _getAppBarTitleWidget() {
    String titleText;
    switch (_selectedIndex) {
      case 0:
        titleText = 'PickMe';
        // Si l'index est 0, on retourne le texte "PickMe" en orange.
        return Text(
          titleText,
          style: const TextStyle(
            color: Colors.orange, // Couleur spécifique pour "PickMe"
            fontWeight: FontWeight.bold, // Optionnel : pour le mettre en gras
          ),
        );
      case 2:
        titleText = 'Messages';
        break; // On utilise le style par défaut pour les autres
      default:
        titleText = '';
        break;
    }

    // Pour tous les autres titres, on retourne un widget Text simple.
    // Il héritera de la couleur définie dans `foregroundColor` de l'AppBar.
    return Text(titleText);
  }

}
