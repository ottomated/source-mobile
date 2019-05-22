import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'source.dart';
import 'globals.dart' as globals;
import 'package:dynamic_theme/dynamic_theme.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.classes}) : super(key: key);
  final List<SourceClass> classes;

  @override
  SettingsPageState createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {
  GlobalKey<ScaffoldState> key;

  bool _working = false;

  List<Widget> _topOfSettings(BuildContext pageContext) {
    return [
      ListTile(
        title: Text('Log out'),
        subtitle: Text('Logged in as ${globals.username}'),
        onTap: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dcontext) {
              return AlertDialog(
                title: Text('Log Out'),
                content: Text('Are you sure you want to log out?'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(dcontext).pop();
                    },
                  ),
                  FlatButton(
                    child: Text('Log Out'),
                    onPressed: () async {
                      Navigator.pop(pageContext);
                      globals.username = '';
                      globals.password = '';
                      var prefs = await SharedPreferences.getInstance();
                      prefs.setString('a', '');
                      prefs.setString('b', '');
                      await prefs.remove('results');
                      globals.cameBackFromSettingsRefresh = true;
                      Navigator.pop(pageContext);
                    },
                  ),
                ],
              );
            },
          );
        },
        trailing: Icon(Icons.exit_to_app),
      ),
      Divider(),
      SwitchListTile(
        title: Text('Theme'),
        subtitle: Text(
            'Current theme is ${DynamicTheme.of(context).brightness == Brightness.dark ? 'dark' : 'light'}'),
        value: DynamicTheme.of(context).brightness == Brightness.dark,
        onChanged: (_) {
          DynamicTheme.of(context).setBrightness(
              Theme.of(context).brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark);
        },
        activeColor: Theme.of(context).accentColor,
      ),
      Divider(),
      ListTile(
        dense: true,
        title: Text(
          'Due to a request from the school district, notifications have been removed from the app.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    key = GlobalKey<ScaffoldState>();

    Widget page = Center(
      child: ListView(
        children: List.from(_topOfSettings(context)),
      ),
    );
    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Stack(
        children: _working ? [LinearProgressIndicator(), page] : [page],
      ),
    );
  }
}
