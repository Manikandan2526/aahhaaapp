library my_prj.globals;



import 'package:flutter/material.dart';



String myApiBaseURL = "http://3.111.41.1:3000";

int themeSelectedColor =0;
List<Color> themeColors = [Colors.green, Colors.blue, Colors.purple, Colors.yellow];

const MaterialColor kPrimaryColor = MaterialColor(
  0xFF0E7AC7,
  <int, Color>{
    0:  Colors.green,
    1:  Colors.blue,
    2:  Colors.purple,
    3:  Colors.yellow,
   
  },
);