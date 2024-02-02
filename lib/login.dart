import 'package:aahhaaapp/common/messagebox.dart';
import 'package:aahhaaapp/home.dart';
import 'package:flutter/material.dart';

import 'api/database.dart' as database;

final focusqty = FocusNode();
final txtQtyController = TextEditingController();
var txtItemNameController = TextEditingController();
var dbHelper = database.DbHelper();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
  }

  var passwordVisible = true;
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  showSnackBar(message, duration) async {
    final scaffoldState = ScaffoldMessenger.of(context);
    scaffoldState.showSnackBar(SnackBar(
      //backgroundColor: Colors.blue,
      backgroundColor: Theme.of(context).primaryColorDark,
      duration: Duration(seconds: duration),
      content: Row(
        children: <Widget>[const CircularProgressIndicator(), Text(message)],
      ),
    ));
  }

  hideSnackBar() {
    final scaffoldState = ScaffoldMessenger.of(context);
    scaffoldState.hideCurrentSnackBar();
  }

  validateLogin() async {
    final form = formKey.currentState;

    if (form!.validate()) {
      await showSnackBar(" Signing In...", 60);
      var loginresult = await dbHelper.validateLogin(
          emailController.text, passwordController.text);
      if (loginresult == "success") {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const Home(
                      title: 'test',
                    )));
        hideSnackBar();
      } else {
        hideSnackBar();
        // ignore: use_build_context_synchronously
        showMessage(loginresult, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        // backgroundColor: Colors.white,
        appBar: AppBar(
          // backgroundColor: Colors.blue,
          title: const Text("Login Page"),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 60.0),
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
                Padding(
                  //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextFormField(
                    textInputAction: TextInputAction.go,
                    controller: emailController,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration:  InputDecoration(
                      prefixIcon:
                      Icon(
                        Icons.email,
                        color: Theme.of(context).primaryColorDark,
                      ),
                      labelText: 'Email/UserName',
                      hintText: "Enter your email/username",
                      border: const OutlineInputBorder(),
                    ),
                    // validator: (val) {
                    //   if (val == "") {
                    //     return "Enter an email";
                    //   }
                    //   bool emailRule = RegExp(
                    //           r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                    //       .hasMatch(val!);

                    //   if (!emailRule) {
                    //     return "Enter a valid email";
                    //   } else {
                    //     return null;
                    //   }
                    // },
                    onFieldSubmitted: (val) {
                      //ScaffoldMessenger.of(context)?.showSnackBar(SnackBar(content: Text("Enter somethong here to display on snackbar")));

                      validateLogin();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 15.0, right: 15.0, top: 15, bottom: 15),
                  //padding: EdgeInsets.symmetric(horizontal: 15),
                  child: TextFormField(
                    obscureText: passwordVisible,
                    controller: passwordController,
                    textInputAction: TextInputAction.go,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Theme.of(context).primaryColorDark,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          // Based on passwordVisible state choose the icon
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () {
                     
                          // Update the state i.e. toogle the state of passwordVisible variable
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                      ),
                      labelText: 'Password',
                      hintText: "Enter your password",
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == "") {
                        return "Enter a password";
                      } else {
                        return null;
                      }
                    },
                    onFieldSubmitted: (val) {
                      validateLogin();
                    },
                  ),
                ),
                Container(
                  height: 50,
                  width: 250,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20)),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColorDark,
                        ),
                    onPressed: () {
                      validateLogin();
                      // Navigator.push(
                      //     context, MaterialPageRoute(builder: (_) => HomePage()));
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white, fontSize: 25),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 130,
                ),
              ],
            ),
          ),
        ));
  }
}
