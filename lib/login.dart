import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'globals.dart' as globals;

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.message}) : super(key: key);
  final String message;

  @override
  LoginPageState createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
TextEditingController _usernameController;
TextEditingController _passwordController;
@override
  void initState() {
    _usernameController = TextEditingController(text: globals.username);
    _passwordController = TextEditingController(text: globals.password);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /*setState(() {
      _usernameController.text = globals.username;
      _usernameController.selection =
          TextSelection.collapsed(offset: globals.username.length);

      _passwordController.text = globals.password;
      _passwordController.selection =
          TextSelection.collapsed(offset: globals.password.length);
    });*/
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            Center(
              child: Container(
                child: Text(
                  'the source',
                  style: TextStyle(fontSize: 48.0),
                ),
                padding: EdgeInsets.all(32.0),
              ),
            ),
            Center(
              child: Container(
                child: Text(
                  widget.message ?? '',
                  style: TextStyle(
                      fontSize: 18.0, color: Theme.of(context).accentColor),
                ),
              ),
            ),
            Container(
              child: TextFormField(
                autofocus: false,
                obscureText: false,
                autocorrect: false,
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Username',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0)),
                ),
              ),
              padding: EdgeInsets.all(16.0),
            ),
            Container(
              child: TextFormField(
                autofocus: false,
                obscureText: true,
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0)),
                ),
              ),
              padding: EdgeInsets.all(16.0),
            ),
            Container(
              child: MaterialButton(
                child: Text('Login'),
                color: Theme.of(context).accentColor,
                onPressed: () async {
                  var prefs = await SharedPreferences.getInstance();
                  globals.username = _usernameController.value.text;
                  globals.password = _passwordController.value.text;
                  prefs.setString('a', globals.username);
                  prefs.setString('b', globals.password);
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ),
                    );
                  }
                },
              ),
              padding: EdgeInsets.all(16.0),
            ),
          ],
        ),
      ),
    );
  }
}
