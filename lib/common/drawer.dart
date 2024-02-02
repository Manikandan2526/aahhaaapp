import 'package:flutter/material.dart';
import 'package:aahhaaapp/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aahhaaapp/config.dart';
import 'dart:math';
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    getPref();
  }

  getPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 300,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'AAHHAA',
            ),
            backgroundColor: Theme.of(context).primaryColorDark,
          ),
          body: Drawer(
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,

              children: <Widget>[
                ListTile(
                  leading: const Icon(
                    Icons.home,
                  ),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                  ),
                  title: const Text('Logout'),
                  onTap: () {
                    prefs.remove("Ref");

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const LoginPage(title: '')));
                    // Navigator.pop(context);
                  },
                ),
                // Wrap(
                //   children: getColorsWidgets().toList(),
                // )
              ],
            ),
          ),
        ));
  }



Iterable<Widget> getColorsWidgets() sync* {
  for (var index = 0; index <= 3; index += 1) {
    // final children = source[index].map((value) => Icon(value)).toList();
    // final isSelected = values[index];

    yield ElevatedButton(
      //isSelected: isSelected,
      onPressed: () {
        log(index);
       
         setState(() { themeSelectedColor=index; });
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(55, 40),
        backgroundColor: themeColors[index],
        shape: const CircleBorder(),
      ),
      child: const Text("", style: TextStyle(color: Colors.white)),
    );
  }
}

}

