import 'package:family/components/my_button.dart';
import 'package:family/components/my_textfield.dart';
import 'package:family/services/auth/auth_service.dart';
import'package:flutter/material.dart';




class LoginPage extends StatelessWidget{
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  // tap to go to register page
  final  void Function()? onTap;
  LoginPage({super.key , required this.onTap});


  // login method
  void login(BuildContext context) async {
    // auth service
    final authService = AuthService();
    //try sign in
    try{
      await authService.signInWithEmailAndPassword(
        _emailController.text, _pwController.text,);
    }
    // catch any errors
    catch(e){
      showDialog(context: context, builder: (context)=>AlertDialog(
        title: Text(e.toString()),
      )
      );
    }
  }
  //
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo
              Icon(
                Icons.account_circle,
                size: 95,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 25),
              //welcome back message
              Text(
                "Welcome to PickMe",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 25),
              //email textfield
              MyTextField(
                hintText: "Email",
                obscureText:false,
                controller:_emailController ,
              ),
              const SizedBox(height: 10),
              //password textfield
              MyTextField(
                hintText: "Password",
                obscureText:true,
                controller:_pwController ,
              ),
              const SizedBox(height: 25),
              // login button
              MyButton(
                text:("login"),
                onTap: () => login(context),
              ),
              const SizedBox(height: 25),
              //register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Not a member ? ",
                    style: TextStyle(
                        color:Theme.of(context).colorScheme.secondary),
                  ),

                  GestureDetector(
                      onTap: onTap,
                      child: Text(
                          "register now",
                          style:TextStyle(
                            color:Theme.of(context).colorScheme.tertiary,
                            fontWeight:FontWeight.bold,
                          )
                      )
                  ),
                ],
              )
            ],
          )
      ),
    );
  }
}