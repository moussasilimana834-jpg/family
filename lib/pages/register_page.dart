import 'package:flutter/material.dart';
import 'package:family/components/my_button.dart';
import 'package:family/components/my_textfield.dart';
import 'package:family/services/auth/auth_service.dart';

class RegisterPage extends StatelessWidget{
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final void Function()? onTap;


  void register( BuildContext context){
    // get auth service
    final _auth = AuthService();
    // passwords match => create user

    if(_pwController.text == _confirmController.text){
      try{
      _auth.signUpWithEmailAndPassword(
        _emailController.text,
        _pwController.text,
      );
    } catch(e){
        showDialog(context: context, builder: (context)=>AlertDialog(
          title: Text(e.toString()),
        ),
        );
      }
    }
    //passwords don't match
    else{
      showDialog(context: context, builder: (context)=>AlertDialog(
        title: Text("passwords don't match"),
      ),
      );
    }
  }
  RegisterPage({super.key , required this .onTap});
  @override
  Widget build (BuildContext context ){
    return  Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo
              Icon(
                Icons.account_circle,
                size: 90,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 25),
              //welcome back message
              Text(
                "let's create an account ",
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
              //confirm password textfield
              MyTextField(
                hintText: "Password",
                obscureText:true,
                controller:_confirmController ,
              ),
              const SizedBox(height: 10),
              //password textfield
              MyTextField(
                hintText: " Confirm Password",
                obscureText:true,
                controller:_pwController ,
              ),
              const SizedBox(height: 25),
              // login button
              MyButton(
                text:"Register",
                onTap: () => register(context),
              ),
              const SizedBox(height: 25),
              //register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account ? ",
                    style: TextStyle(
                        color:Theme.of(context).colorScheme.secondary),
                  ),

                  GestureDetector(
                    onTap: onTap,
                      child: Text(
                      "login now",
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


