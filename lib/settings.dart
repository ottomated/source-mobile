import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'login.dart';
import 'globals.dart' as globals;

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.message}) : super(key: key);
  final String message;

  @override
  SettingsPageState createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: ListView(
          children: [
            ListTile(
              title: Text('Logged in as ${globals.username}'),
              subtitle: Text('Change account'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              },
              trailing: Icon(Icons.person_add),
            ),
            Divider(),
            ListTile(
              
            )
          ],
        ),
      ),
    );
  }
}
