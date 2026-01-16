
import 'package:flutter/material.dart';

class BarrePage extends StatefulWidget{
  @override
  _BarrePageState createState() => _BarrePageState();
}

class _BarrePageState extends State<BarrePage>{
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    AccueilPages(),
    livePages(),
    MoiPages(),
    messagesPages(),
  ];
  void _onItemTapped(int index){
    setState((){
    _selectedIndex = index;
    });
  }
  @override
  Widget build (BuildContext context ){
    return Scaffold(
      body: _pages[_selectedIndex],
   bottomNavigationBar: BottomNavigationBar(
     currentIndex: _selectedIndex,
     onTap: _onItemTapped,
     selectedItemColor: Colors.blue,
     unselectedItemColor: Colors.grey,
     items:const [
       BottomNavigationBarItem(
         icon: Icon(Icons.home),
         label: 'Accueil',
       ),
       BottomNavigationBarItem(
         icon: Icon(Icons.live_tv),
         label: 'Live',
       ),
       BottomNavigationBarItem(
         icon: Icon(Icons.message),
         label: 'messages',
       ),
       BottomNavigationBarItem(
         icon: Icon(Icons.person),
         label: 'Moi',
       ),
     ],
   ),
    );
    }
}
class AccueilPages extends StatelessWidget{
  @override
  Widget build (BuildContext context){
    return Center(
      child: Text('Accueil'),
    );

  }
}
class livePages extends StatelessWidget{
  @override
  Widget build (BuildContext context){
    return Center(
      child: Text('voici votre page live'),
    );

  }
}
class messagesPages extends StatelessWidget{
  @override
  Widget build (BuildContext context){
    return Center();
  }
}
class MoiPages extends StatelessWidget{
  @override
  Widget build (BuildContext context){
    return Center(
      child: Text('bienvenue sur la page de profil '),
    );
  }
}