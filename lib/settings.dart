import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'source.dart';
import 'login.dart';
import 'dart:convert';
import 'globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.classes, this.firebaseToken}) : super(key: key);
  final List<SourceClass> classes;
  final String firebaseToken;

  @override
  SettingsPageState createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {
  SharedPreferences _prefs;
  Map<String, dynamic> _localPrefs = {};
  bool _notificationsEnabled = false;
  GlobalKey<ScaffoldState> key;

  bool _working = false;

  @override
  void initState() {
    super.initState();
    resetLocals();
    _init();
  }

  void resetLocals() {
    for (var c in widget.classes) {
      if (c.categories.length == 0)
        _localPrefs[c.className] = true;
      else
        _localPrefs[c.className] = Map.fromIterable(
          c.categories,
          key: (cat) => cat.id,
          value: (cat) => true,
        );
    }
  }

  void _init() async {
    _prefs = await SharedPreferences.getInstance();
    Set<String> keys = _prefs.getKeys();
    if (keys.contains('notify_enabled')) {
      setState(() {
        _notificationsEnabled = _prefs.getBool('notify_enabled');
      });
    } else {
      await _prefs.setBool('notify_enabled', false);
    }

    if (keys.contains('notify_class_settings')) {
      _localPrefs =
          json.decode(await _prefs.getString('notify_class_settings'));
    } else {
      await _prefs.setString('notify_class_settings', json.encode(_localPrefs));
    }
  }

  Future<bool> _makeRequest(String url, Map body) async {
    if (_working) return false;
    setState(() {
      _working = true;
    });
    http.Response r;
    try {
      r = await http.post(
        url,
        body: json.encode(body),
      );
    } catch (e) {
      print(e);
      setState(() {
        _working = false;
      });
      Fluttertoast.showToast(msg: e.toString());
      Navigator.pop(context);
      return false;
    }
    setState(() {
      _working = false;
    });
    if (r.statusCode != 404 && r.statusCode != 200) {
      Fluttertoast.showToast(
          msg: 'Server Error (Invalid Request ${r.statusCode})');
      Navigator.pop(context);
      return false;
    }
    return true;
  }

  List<Widget> _topOfSettings(BuildContext pageContext) {
    return [
      ListTile(
        title: Text('Logged in as ${globals.username}'),
        subtitle: Text('Log out'),
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
                      await _makeRequest(
                        'https://ottomated.net/source/deregister',
                        {'token': widget.firebaseToken},
                      );
                      globals.username = '';
                      globals.password = '';
                      var prefs = await SharedPreferences.getInstance();
                      prefs.setString('a', '');
                      prefs.setString('b', '');
                      await _prefs.remove('notify_enabled');
                      await _prefs.remove('notify_class_settings');
                      await _prefs.remove('results');
                      globals.cameBackFromSettingsRefresh = true;
                      Navigator.pop(pageContext);
                    },
                  ),
                ],
              );
            },
          );
        },
        trailing: Icon(Icons.person_add),
      ),
      Divider(),
      SwitchListTile(
        title: Text('Notifications'),
        subtitle: Text(
            'Push notifications are ${_notificationsEnabled ? 'enabled' : 'disabled'}'),
        value: _notificationsEnabled,
        onChanged: widget.classes.length == 0
            ? null
            : (newVal) async {
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
                            onPressed: _working
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                          ),
                          FlatButton(
                            child: Text('Accept'),
                            onPressed: _working
                                ? null
                                : () async {
                                    if (_working) return;
                                    bool success = await _makeRequest(
                                      'https://ottomated.net/source/register',
                                      {
                                        'token': widget.firebaseToken,
                                        'sUsername': globals.username,
                                        'sPassword': globals.password,
                                        'classes': Map.fromEntries(
                                          widget.classes.map((c) =>
                                              MapEntry(c.className, true)),
                                        ),
                                      },
                                    );
                                    Navigator.pop(context);
                                    if (success) {
                                      await _prefs.setBool(
                                          'notify_enabled', true);
                                      setState(() {
                                        _notificationsEnabled = true;
                                      });
                                    }
                                  },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  bool success = await _makeRequest(
                    'https://ottomated.net/source/deregister',
                    {'token': widget.firebaseToken},
                  );
                  if (success) {
                    resetLocals();
                    await _prefs.setString(
                        'notify_class_settings', json.encode(_localPrefs));

                    await _prefs.setBool('notify_enabled', false);
                    setState(() {
                      _notificationsEnabled = false;
                    });
                  }
                }
              },
        activeColor: Theme.of(context).accentColor,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    key = GlobalKey<ScaffoldState>();

    Widget page = Center(
      child: ListView(
        children: List.from(_topOfSettings(context))
          ..addAll(
            widget.classes.map((c) {
              if (c.categories.length > 0 && _localPrefs[c.className].runtimeType != bool) {
                return ExpansionTile(
                  title: Text(c.classNameCased),
                  children: c.categories.map((cat) {
                    var miniOnChg = _notificationsEnabled
                        ? (newVal) async {
                            Map newPrefs =
                                json.decode(json.encode(_localPrefs));
                            newPrefs[c.className][cat.id] = newVal;

                            bool success = await _makeRequest(
                              'https://ottomated.net/source/prefs',
                              {
                                'token': widget.firebaseToken,
                                'updates': json.encode(newPrefs)
                              },
                            );
                            if (success) {
                              _localPrefs = Map.from(newPrefs);
                              await _prefs.setString('notify_class_settings',
                                  json.encode(_localPrefs));
                            }
                          }
                        : null;
                        //print('$_localPrefs ${c.className} ${cat.id} ${_localPrefs[c.className]}');
                    return InkWell(
                      onTap: () => miniOnChg(!_localPrefs[c.className][cat.id]),
                      child: ListTile(
                        title: Text(cat.name),
                        dense: true,
                        leading: Padding(
                          padding: EdgeInsets.only(left: 30.0),
                          child: Checkbox(
                            value: _localPrefs[c.className][cat.id],
                            onChanged: miniOnChg,
                            activeColor: Theme.of(context).accentColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  leading: Checkbox(
                    onChanged: _notificationsEnabled
                        ? (_) async {
                            Map newPrefs =
                                json.decode(json.encode(_localPrefs));
                            bool toEnable = false;
                            if ((_localPrefs[c.className] as Map)
                                .values
                                .any((_) => !_)) {
                              toEnable = true;
                            }

                            for (SourceCategory cat in c.categories) {
                              newPrefs[c.className][cat.id] = toEnable;
                            }
                            bool success = await _makeRequest(
                              'https://ottomated.net/source/prefs',
                              {
                                'token': widget.firebaseToken,
                                'updates': json.encode(newPrefs)
                              },
                            );
                            if (success) {
                              _localPrefs = Map.from(newPrefs);
                              await _prefs.setString('notify_class_settings',
                                  json.encode(_localPrefs));
                            }
                          }
                        : null,
                    value: () {
                      int numberEnabled =
                          _localPrefs[c.className].values.where((_) {
                        return _ as bool;
                      }).length;
                      if (numberEnabled == 0) {
                        return false;
                      } else if (numberEnabled ==
                          _localPrefs[c.className].values.length) {
                        return true;
                      } else {
                        return null;
                      }
                    }(),
                    tristate: true,
                    activeColor: Theme.of(context).accentColor,
                  ),
                );
              } else {
                var miniOnChg = _notificationsEnabled
                    ? (newVal) async {
                        Map newPrefs = json.decode(json.encode(_localPrefs));
                        newPrefs[c.className] = newVal;

                        bool success = await _makeRequest(
                          'https://ottomated.net/source/prefs',
                          {
                            'token': widget.firebaseToken,
                            'updates': json.encode(newPrefs)
                          },
                        );
                        if (success) {
                          _localPrefs = Map.from(newPrefs);
                          await _prefs.setString('notify_class_settings',
                              json.encode(_localPrefs));
                        }
                      }
                    : null;
                return InkWell(
                  onTap: () => miniOnChg(!_localPrefs[c.className]),
                  child: ListTile(
                    title: Text(c.classNameCased),
                    leading: Checkbox(
                      onChanged: miniOnChg,
                      value: _localPrefs[c.className],
                      activeColor: Theme.of(context).accentColor,
                    ),
                  ),
                );
              }
            }),
          ),
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
