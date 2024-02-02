// import 'dart:io';

import 'package:aahhaaapp/login.dart';
import 'package:flutter/material.dart';


import 'package:shared_preferences/shared_preferences.dart';


class Settings extends StatefulWidget {
  const Settings({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  void initState() {
    super.initState();
   
      getControlvalues().then((result) async {
        setState(() {});
      });
 
  }

  final txtApiURLController = TextEditingController();

  Future<String> getControlvalues() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString("ApiURL") == null) {     
      txtApiURLController.text = '';
    } else {      
      txtApiURLController.text = prefs.getString("ApiURL").toString();
    }

    return "success";
  }

  updateValues(context) async {
    final scaffoldState = ScaffoldMessenger.of(context);
    final prefs = await SharedPreferences.getInstance();
   
    prefs.setString("ApiURL", txtApiURLController.text);

    scaffoldState
        .showSnackBar(const SnackBar(content: Text('Settings Updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0), // here the desired height
        child: AppBar(
          backgroundColor: Colors.purple,
          title: const Text(
            "Settings",
            style: TextStyle(fontSize: 15, color: Colors.white),
          ),
          actions: <Widget>[
            IconButton(
              padding: const EdgeInsets.all(0.0),
              icon: const Icon(Icons.home,
                  color: Color.fromARGB(255, 255, 255, 255), size: 20.0),
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const LoginPage(title: '')));
                // Navigator.pop(context);
              },
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Form(
          child: ListView(
            children: <Widget>[
             
              TextFormField(
                style: const TextStyle(fontSize: 15.0),
                //focusNode: focusqty,
                controller: txtApiURLController,
                textInputAction: TextInputAction.go,
                decoration: const InputDecoration(
                  hintText: "Api URL",
                  labelText: "Api URL",
                ),
                maxLines: null,
                validator: (value) {
                  return null;
                },
                onFieldSubmitted: (value) {},
              ),

              ElevatedButton(
                //padding: EdgeInsets.all(20),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () async {
                  updateValues(context);
                },
                child: const Text(
                  "Update",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
