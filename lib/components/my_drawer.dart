import 'package:family/sous_page/formation.dart';
import 'package:flutter/material.dart';
import 'package:family/sous_page/settings_page.dart';
import 'package:family/services/auth/auth_service.dart';
import 'package:family/sous_page/solde_page.dart';



class MyDrawer extends StatelessWidget{
  const MyDrawer ({super.key});
  void logout(){
    // get auth service
    final auth = AuthService();
    auth.signOut();
  }
  @override
  Widget build(BuildContext context){
    return Drawer(
      child:Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [  // logo
            DrawerHeader(
              child: Center(
                child:  Icon(Icons.manage_search,color:Theme.of(context).colorScheme.primary,
                  size: 64,

                ),
              ),
            ),
            //home list tile
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child:ListTile(
                title:const  Text(
                    "F O R M A T I O N ",
                  style: TextStyle(color: Colors.orange),
                ),
                leading:const Icon(Icons.school),
                onTap: (){
                  // pop the drawer
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context)=> const FormationPage()
                      ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child:ListTile(
                title: Text("C O M M U N A U T E S ",
                  style: TextStyle(color: Colors.orange),
                ),
                leading: const Icon(Icons.group),
                onTap: (){
                  // pop the drawer
                  Navigator.pop(context);
                  // navigate to settings page
                  Navigator.push(
                      context, MaterialPageRoute(
                      builder: (context)=>const  SoldePage(),
                  ));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child:ListTile(
                title: Text(" S E T T I N G S ",
                  style: TextStyle(color: Colors.orange),),
                leading: const Icon(Icons.settings),
                onTap: (){
                  Navigator.push(
                      context, MaterialPageRoute(
                    builder: (context)=>const  SettingsPage(),
                  ));

                },
              ),
            ),
          ],
          ),

          //logout list tile
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25.0), // Added bottom padding for spacing
            child:ListTile(
              title: Text("L O G O U T " ,
                style: TextStyle(color:Colors.orange),),
              leading: const Icon(Icons.logout),
              onTap: (){
                logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}