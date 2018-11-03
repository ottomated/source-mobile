import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'expanding_card.dart';
import 'dart:convert';
import 'source.dart';
import 'login.dart';
import 'settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
String _firebaseToken = '';

void main() {
  runFirebase();
  runApp(SourceApp());
}

Future<void> runFirebase() async {
  _firebaseMessaging.requestNotificationPermissions();
  _firebaseToken = await _firebaseMessaging.getToken();
  print(_firebaseToken);
  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) async {
      print("onMessage: $message");
    },
  );
}

class SourceApp extends StatelessWidget {
  Future<String> _checkLoggedIn() async {
    var prefs = await SharedPreferences.getInstance();
    if (!prefs.getKeys().contains('a') || !prefs.getKeys().contains('b')) {
      return '0';
    } else if (prefs.getString('a') == '' || prefs.getString('b') == '') {
      return '0';
    } else {
      globals.username = prefs.getString('a');
      globals.password = prefs.getString('b');
      return '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    var loggedIn = _checkLoggedIn();
    return MaterialApp(
      title: 'the source',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.blueAccent,
        brightness: Brightness.dark,
      ),
      home: FutureBuilder(
        future: loggedIn,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.data == '0') {
            return LoginPage();
          }
          return HomePage();
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Source _source = Source();
  TabController _tabController;
  List<Widget> _tabs = [];
  List<Tab> _barTabs = [];
  String _gpa = '';
  String _weightedGpa = '';
  GlobalKey<ScaffoldState> key;

  @override
  void initState() {
    //print("initState");
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (_tabController == null) {
      _tabs = [tabProfile()];
      _barTabs = [
        Tab(icon: studentPicture(10.0)),
      ];
      _tabController = TabController(vsync: this, length: 20);
    }

    _doQuickRefresh();
  }

  Future<void> _doQuickRefresh() async {
    var prefs = await SharedPreferences.getInstance();
    if (!prefs.getKeys().contains("results")) {
      return _doRefresh();
    }
    Map resultsMap = json.decode(prefs.getString("results"));
    SourceResults results = SourceResults.fromJson(resultsMap);
    await _performDoRefresh(results);
    _doRefresh();
  }

  Widget studentPicture(double radius) {
    ImageProvider img;
    Widget child;
    File imageFile = File(globals.imageFilePath);
    if (imageFile.existsSync()) {
      img = FileImage(imageFile);
    } else {
      child = Text('');
    }
    return CircleAvatar(
        minRadius: radius,
        maxRadius: radius,
        backgroundColor: Colors.transparent,
        backgroundImage: img,
        child: child);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget clipboardCopier(String text, Text child, EdgeInsets padding) {
    return Container(
      child: InkWell(
        onTap: () async {
          Clipboard.setData(ClipboardData(text: text));
          key.currentState.showSnackBar(
            SnackBar(
              content: Text('Copied to clipboard'),
              backgroundColor: Theme.of(context).accentColor,
              duration: Duration(milliseconds: 500),
            ),
          );
        },
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget tabProfile() {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(24.0),
          child: studentPicture(96.0),
        ),
        Text(
          '${globals.name[0]} ${globals.name.last}',
          style: TextStyle(fontSize: 24.0),
        ),
        Text(
          globals.username,
          style: TextStyle(fontSize: 12.0),
        ),
        Text(
          'Grade ${globals.grade}',
          style: TextStyle(fontSize: 12.0),
        ),
        clipboardCopier(
          globals.studentID,
          Text(
            "Student ID: ${globals.studentID}",
            style: TextStyle(fontSize: 14.0),
          ),
          EdgeInsets.fromLTRB(6.0, 12.0, 6.0, 6.0),
        ),
        clipboardCopier(
          globals.stateID,
          Text(
            "State ID: ${globals.stateID}",
            style: TextStyle(fontSize: 14.0),
          ),
          EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 12.0),
        ),
        Text(
          'GPA: $_gpa\nweighted: $_weightedGpa',
          style: TextStyle(fontSize: 17.0),
          textAlign: TextAlign.center,
        )
      ],
    );
  }

  /*Widget _generateTableCell(SourceClassGrade grade) {
    return _generateTableCellText('${grade.letter}\n${grade.percent}%', 12.0);
  }

  Widget _generateTableCellText(String text, double size) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: size),
      ),
    );
  }*/

  bool _isRefreshing = false;
  Future<void> _doRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    dynamic results = await _source.doReq(globals.username, globals.password);
    setState(() {
      _isRefreshing = false;
    });
    if (results == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(message: 'Invalid Credentials'),
        ),
      );
      return;
    } else if (results.runtimeType != SourceResults) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Exception"),
            content: Text(
              results.toString(),
            ),
          );
        },
      );
      return;
    }
    var prefs = await SharedPreferences.getInstance();
    //print(results.classes[0].assignments);
    prefs.setString("results", json.encode(results));
    _performDoRefresh(results);
  }

  SourceResults _results;
  Future<void> _performDoRefresh(SourceResults results) async {
    _results = results;
    setState(() {
      globals.name = results.name;
      globals.grade = results.grade;
      globals.studentID = results.studentID;
      globals.stateID = results.stateID;
      globals.imageFilePath = results.imageFilePath;
      Iterable<double> gpas = results.classes
          .map((c) => c.overallGrades.keys
              .where((k) => k.startsWith('S'))
              .map((k) => c.overallGrades[k].percent * 0.04))
          .expand((i) => i);
      if (gpas.length == 0) {
        _gpa = '?';
      } else {
        _gpa = ((gpas.reduce((a, b) => a + b) / gpas.length * 10).round() / 10)
            .toString();
      }
      Iterable<double> weightedGpas = results.classes
          .map((c) => c.overallGrades.keys
              .where((k) => k.startsWith('S'))
              .map((k) => c.overallGrades[k].percent * c.gpaWeight))
          .expand((i) => i);
      if (weightedGpas.length == 0) {
        _weightedGpa = '?';
      } else {
        _weightedGpa =
            ((weightedGpas.reduce((a, b) => a + b) / weightedGpas.length * 10)
                        .round() /
                    10)
                .toString();
      }
      _tabs = [tabProfile()];
      _barTabs = [
        Tab(
          icon: studentPicture(10.0),
        ),
      ];
      _tabs.addAll(results.classes.map((sourceClass) {
        String k = sourceClass.overallGrades.keys
            .toList()
            .reversed
            .firstWhere((k) => k.startsWith('S'), orElse: () => '');
        Color c;
        if (k == '') {
          c = Colors.white24;
        } else {
          c = Color(sourceClass.overallGrades[k].color);
        }
        _barTabs.add(
          Tab(
            child: Text(
              sourceClass.period.toString(),
              style: TextStyle(
                color: c,
              ),
            ),
          ),
        );
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Center(
                child: Text(
                  sourceClass.classNameCased,
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
              Center(
                child: InkWell(
                  onTap: () {
                    return showDialog<Null>(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Teacher Info'),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                Text('Name: ${sourceClass.teacherName}'),
                                InkWell(
                                  onTap: () async {
                                    await launch(
                                        'mailto:' + sourceClass.teacherEmail);
                                  },
                                  child: Text(
                                      'Email: ${sourceClass.teacherEmail}'),
                                ),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('OK'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text(
                    sourceClass.teacherName,
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: sourceClass.overallGrades.keys.map((q) {
                    return Container(
                      padding: EdgeInsets.all(4.0),
                      child: Chip(
                        backgroundColor:
                            Color(sourceClass.overallGrades[q].color),
                        label: RichText(
                          text: TextSpan(
                            text: q,
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text:
                                    ': ${sourceClass.overallGrades[q].letter}',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15.0),
                              ),
                              TextSpan(
                                text:
                                    '  ${sourceClass.overallGrades[q].percent.round()}%',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 13.0),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  /* Table(
                    children: sourceClass.overallGrades.keys.map((q) {
                      return new TableRow(children: [
                        _generateTableCellText(q, 15.0),
                        _generateTableCell(sourceClass.overallGrades[q]),
                      ]);
                    }).toList(),
                  ),*/
                ),
              ),
              // Assignments
              _makeAssignmentTable(sourceClass),
            ],
          ),
        );
      }));
    });
  }

  Widget _makeAssignmentTable(SourceClass sourceClass) {
    List<SourceAssignment> asses = sourceClass.assignments;
    if (asses == null) asses = [];
    /*return Table(
      children: asses.reversed.map((ass) {
        return new TableRow(children: <Widget>[
          Text('${ass.dueDate.year}-${ass.dueDate.month}-${ass.dueDate.day}'),
          Text(ass.name),
          Text('${ass.grade.fancyScore}'),
          Text('${ass.grade.percent}% ${ass.grade.letter}')
        ]);
      }).toList(),
    );*/
    return Expanded(
      flex: 5,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: asses.reversed.map((ass) {
          return ExpandingCard(
            top: ListTile(
              leading: ass.grade.percent > 50.0
                  ? Icon(Icons.assignment)
                  : Icon(Icons.assignment_late),
              title: Text(ass.name),
              trailing: Text(
                ass.grade.letter,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Color(ass.grade.color),
                ),
              ),
            ),
            bottom: ListTile(
              title: Text(ass.grade.fancyScore),
              trailing: Text(ass.grade.graded ? '${ass.grade.percent}%' : ''),
            ),
          );
          /*      return new Card(children: <Widget>[
          Text('${ass.dueDate.year}-${ass.dueDate.month}-${ass.dueDate.day}'),
          Text(ass.name),
          Text('${ass.grade.fancyScore}'),
          Text('${ass.grade.percent}% ${ass.grade.letter}')
        ]);*/
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    key = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text('the source'),
        actions: <Widget>[
          Tooltip(
            message: 'Refresh',
            child: IconButton(
              onPressed: () async {
                _doRefresh();
              },
              icon: Icon(Icons.refresh),
            ),
          ),
          Tooltip(
            message: 'Settings',
            child: IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                          classes: _results.classes,
                          firebaseToken: _firebaseToken,
                        ),
                  ),
                );
                if (globals.cameBackFromSettingsRefresh) {
                  globals.cameBackFromSettingsRefresh = false;
                  var prefs = await SharedPreferences.getInstance();
                  prefs.setBool('notify_enabled', false);
                  var keys = prefs.getKeys();
                  for (var k in keys) {
                    if(k.startsWith('notify_') && k != 'notify_enabled') {
                      await prefs.remove(k);
                    }
                  }
                  _doRefresh();
                }
              },
              icon: Icon(Icons.settings),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _barTabs,
          isScrollable: true,
        ),
      ),
      body: Stack(
        children: _getStackChildren(),
      ),
    );
  }

  List<Widget> _getStackChildren() {
    List<Widget> ws = <Widget>[
      TabBarView(
        controller: _tabController,
        children: _tabs,
      ),
    ];
    if (_isRefreshing) {
      ws.add(
        SizedBox(child: LinearProgressIndicator(), height: 2.0),
      );
    }
    return ws;
  }
}
