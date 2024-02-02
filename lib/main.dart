import 'dart:async';

import 'package:aahhaaapp/home.dart';
import 'package:flutter/material.dart';
import 'package:aahhaaapp/login.dart';
// import 'tableorders.dart';
import 'common/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'config.dart';
void main() {
  runApp(const MyApp());
}

Future<String> checkSettingsExistInPref() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // if (prefs.getString("ApiURL") == null ||
  //     prefs.getString("ApiURL") == "") {
  //   return "Settings";
  // } else {
    if(prefs.getString("Ref") == null){
     return "Login";
    }
    else{
      return "Home";
    } 

  // }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          
   

      primarySwatch: Colors.green
     

  

      ),
        home: FutureBuilder<String>(
      future: checkSettingsExistInPref(),
      builder: (buildContext, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == "Settings") {
            // if settings not configured then go to setting page
            return const Settings(title: 'Settings');
          } else if(snapshot.data == "Login") {
            //if setting configirued go to table orders page
            return const LoginPage(title: 'Login');
          }
          else{
               return const Home(title: 'Home');
          }
          // Return your home here if pref not exist
        } else {
          // Return loading screen while reading preferences
          return const SplashScreen();
        }
      },
    ));
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Timer(const Duration(seconds: 3),
    //       ()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(context) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColorDark,
          title: const Text(
            "Aahhaa App",
            style: TextStyle(fontSize: 15, color: Colors.white),
          ),
        ),
        body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(
                  '          Welcome!!!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const CircularProgressIndicator(),
              ],
            )));
  }
}
