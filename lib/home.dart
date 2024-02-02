// import 'dart:io';

import 'package:flutter/material.dart';
import 'monthly_sales.dart';
import 'pos_sales.dart';
// import 'login.dart';
import 'api/database.dart' as database;
 import 'common/drawer.dart';
import 'api/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

var dbHelper = database.DbHelper();

class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {


  int selectedCompanyId = 0;
  Company? selectedCompany;
  List<Company> companyList = [];
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadCountry().then((result) {
      setState(() {
        if(prefs.getString("CompanyId")  != null){
            selectedCompanyId = int.parse(prefs.getString("CompanyId").toString());
              selectedCompany= companyList
                .where((i) =>
                    (i.companyid == selectedCompanyId)).first;
        }
        
        
      });
    });
  }


  _loadCountry() async {
    prefs = await SharedPreferences.getInstance();
    companyList = await dbHelper.getCompanyList();
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0), // here the desired height
        child: AppBar(
          //backgroundColor: Theme.of(context).primaryColorDark,
          title: const Text(
            "Home",
            style: TextStyle(fontSize: 15, color: Colors.white),
          ),
          // actions: <Widget>[
          //   IconButton(
          //     padding: const EdgeInsets.all(0.0),
          //     icon: const Icon(Icons.logout,
          //         color: Color.fromARGB(255, 255, 255, 255), size: 20.0),
          //     onPressed: () {
          //       Navigator.of(context).pushReplacement(MaterialPageRoute(
          //           builder: (context) => const LoginPage(title: '')));
          //       // Navigator.pop(context);
          //     },
          //   )
          // ],
        ),
      ),
       drawer: const AppDrawer(title: 'test'),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Center(
              child: SizedBox(
                  width: 200,
                  height: 150,
                  /*decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(50.0)),*/
                  child: Image.asset('assets/logo-default.png')),
            ),
          ),
          const SizedBox(
            height: 50,
            child: Text(
              'Welcome',
              style: TextStyle(color: Colors.black, fontSize: 25),
            ),
          ),
          Flexible(
          
            child: DropdownButton<Company>(
              isExpanded: true,
              hint: const Text("Select a Company"),
              value:  selectedCompany,
              onChanged: (selectedvalue) {
                setState(() {
                  
                   selectedCompany = selectedvalue!;
                   selectedCompanyId = selectedvalue.companyid;
                   prefs.setString("CompanyId", selectedCompanyId.toString());
                    prefs.setString("POSId", "0");
                    prefs.setString("CounterId", "0");
                });
              },
              items: companyList.map((Company company) {
                return DropdownMenuItem<Company>(
                  value: company,
                  child: Text(
                    company.companyname,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            height: 50,
            width: 250,
            decoration: BoxDecoration(
                //color: Theme.of(context).primaryColorDark,
                 borderRadius: BorderRadius.circular(20)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColorDark,
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const POS(title: '')));
              },
              child: const Text(
                'Daily Sales',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Container(
            height: 50,
            width: 250,
            decoration: BoxDecoration(
                //color: Theme.of(context).primaryColorDark,
                 borderRadius: BorderRadius.circular(20)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColorDark,
              ),
              onPressed: () {
                 Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const MonthlySales(title: '')));
              },
              child: const Text(
                'Monthly Sales',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
