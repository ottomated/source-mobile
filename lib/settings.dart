import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'source.dart';
import 'login.dart';
import 'globals.dart' as globals;

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.classes}) : super(key: key);
  List<SourceClass> classes;

  @override
  SettingsPageState createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {
  SharedPreferences _prefs;
  Map<String, bool> _localPrefs = {};
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    for (var c in widget.classes) {
      String k = 'notify_' + c.className;
      _localPrefs[k] = true;
    }
    _init();
  }

  void _init() async {
    _prefs = await SharedPreferences.getInstance();
    Set<String> keys = _prefs.getKeys();
    if (keys.contains('notify_enabled')) {
      _notificationsEnabled = _prefs.getBool('notify_enabled');
    } else {
      await _prefs.setBool('notify_enabled', false);
    }
    for (var c in widget.classes) {
      String k = 'notify_' + c.className;
      if (!keys.contains(k)) {
        await _prefs.setBool(k, true);
        setState(() {
          _localPrefs[k] = true;
        });
      } else {
        setState(() {
          _localPrefs[k] = _prefs.getBool(k);
        });
      }
    }
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
                if (globals.cameBackFromSettingsRefresh2) {
                  globals.cameBackFromSettingsRefresh2 = false;
                  globals.cameBackFromSettingsRefresh = true;
                  Navigator.of(context).pop();
                }
              },
              trailing: Icon(Icons.person_add),
            ),
            Divider(),
            SwitchListTile(
              title: Text('Notifications'),
              subtitle: Text(
                  'Push notifications are ${_notificationsEnabled ? 'enabled' : 'disabled'}'),
              value: _notificationsEnabled,
              onChanged: (newVal) async {
                if (newVal) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Push Notifcations'),
                        content: Text(
                            'By enabling push notifications, you agree that your stored credentials will be uploaded, encrypted and stored. This is necessary in order to send you notifications. If you wish to disable this at any point, you can disable this switch.'),
                        actions: <Widget>[
                          FlatButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          FlatButton(
                            child: Text('Accept'),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _prefs.setBool('notify_enabled', newVal);
                              setState(() {
                                _notificationsEnabled = newVal;
                              });
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  await _prefs.setBool('notify_enabled', newVal);
                  setState(() {
                    _notificationsEnabled = newVal;
                  });
                }
              },
              activeColor: Theme.of(context).accentColor,
            ),
            ExpansionTile(
              title: Text(
                  'Classes (${_localPrefs.values.where((k) => k).length}/${widget.classes.length} enabled)'),
              children: widget.classes.map((c) {
                String k = 'notify_' + c.className;
                return CheckboxListTile(
                  dense: true,
                  title: Text(c.classNameCased),
                  onChanged: _notificationsEnabled
                      ? (newVal) async {
                          await _prefs.setBool(k, newVal);
                          setState(() {
                            _localPrefs[k] = newVal;
                          });
                        }
                      : null,
                  value: _localPrefs[k],
                  activeColor: Theme.of(context).accentColor,
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
