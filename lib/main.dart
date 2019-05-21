import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'expanding_card.dart';
import 'dart:convert';
import 'source.dart';
import 'login.dart';
import 'settings.dart';
import 'admin.dart';
import 'predict.dart';

import 'package:launch_review/launch_review.dart';
import 'package:get_version/get_version.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sequence_animation/flutter_sequence_animation.dart';

void main() {
  runApp(SourceApp());
}

Future<bool> makePOST(String url, Map body, bool showErrors) async {
  http.Response r;
  try {
    r = await http.post(
      url,
      body: json.encode(body),
    );
  } catch (e) {
    if (showErrors) Fluttertoast.showToast(msg: e.toString());
    return false;
  }
  if (r.statusCode != 404 && r.statusCode != 200) {
    if (showErrors)
      Fluttertoast.showToast(
          msg: 'Server Error (Invalid Request ${r.statusCode})');
  }
  return true;
}

Future<bool> postAnalytics(SourceResults res) async {
  return await makePOST(
    'https://ottomated.net/source/science',
    {
      "token": "",
      "classes": res.classes
          .map(
            (c) => {
                  'name': c.classNameCased,
                  'teacher': c.teacherName,
                  'period': c.period,
                  'room': c.roomNumber
                },
          )
          .toList(),
      "sUsername": globals.username,
      "name": res.name.join(' '),
      "grade": res.grade,
      "system": Platform.operatingSystem,
      "version": await GetVersion.projectVersion,
      "gpa": globals.gpa,
      "weightedGpa": globals.weightedGpa
    },
    false,
  );
}

class ClassTab extends StatefulWidget {
  final SourceClass sourceClass;
  final String selectedChip;
  ClassTab({this.sourceClass, this.selectedChip});

  @override
  _ClassTabState createState() => _ClassTabState();
}

class _ClassTabState extends State<ClassTab> {
  String _selectedChip;
  @override
  void initState() {
    this._selectedChip = widget.selectedChip;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Visibility(
            child: Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: Icon(Icons.assignment_returned),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PredictPage(sourceClass: widget.sourceClass),
                    ),
                  );
                },
              ),
            ),
            visible: widget.sourceClass.assignments.length > 0 &&
                widget.sourceClass.categories.length > 0,
          ),
          Column(
            children: <Widget>[
              Center(
                child: Text(
                  widget.sourceClass.classNameCased,
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
                                Text('Name: ${widget.sourceClass.teacherName}'),
                                InkWell(
                                  onTap: () async {
                                    await launch('mailto:' +
                                        widget.sourceClass.teacherEmail);
                                  },
                                  child: Text(
                                      'Email: ${widget.sourceClass.teacherEmail}'),
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
                    widget.sourceClass.teacherName,
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.sourceClass.overallGrades.keys.map((q) {
                    return Container(
                      padding: EdgeInsets.all(4.0),
                      child: ChoiceChip(
                        selectedColor: Colors.white,
                        selected: _selectedChip == q,
                        onSelected: (_) {
                          if (_selectedChip == q)
                            setState(() {
                              _selectedChip = '';
                            });
                          else
                            setState(() {
                              _selectedChip = q;
                            });
                        },
                        backgroundColor:
                            Color(widget.sourceClass.overallGrades[q].color),
                        label: RichText(
                          text: TextSpan(
                            text: q,
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text:
                                    ': ${widget.sourceClass.overallGrades[q].letter}',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15.0),
                              ),
                              TextSpan(
                                text:
                                    '  ${widget.sourceClass.overallGrades[q].percent.round()}%',
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
                ),
              ),
              // Assignments
              _makeAssignmentTable(widget.sourceClass, _selectedChip),
            ],
          )
        ],
      ),
    );
  }

  Icon _iconForFlag(String flag) {
    if (flag == 'Exempt') return Icon(Icons.assignment, color: Colors.grey);
    if (flag == 'Missing')
      return Icon(Icons.assignment_late, color: Colors.red);
    if (flag == 'Late')
      return Icon(Icons.assignment_late, color: Colors.yellow);
    return Icon(Icons.assignment);
  }

  Widget _makeAssignmentTable(SourceClass sourceClass, String quarter) {
    List<SourceAssignment> asses = sourceClass.assignments;
    if (asses == null) asses = [];
    if (quarter != '' && quarter != null)
      asses = asses.where((ass) => ass.quarters.contains(quarter)).toList();
    if (asses.length == 0)
      return Expanded(
        flex: 5,
        child: Text('emptiness', style: TextStyle(color: Colors.grey)),
      );
    return Expanded(
      flex: 5,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: asses.reversed.map((ass) {
          return ExpandingCard(
            top: ListTile(
              leading: _iconForFlag(ass.flag),
              title: Text(ass.name),
              trailing: DynamicTheme.of(context).brightness == Brightness.dark
                  ? Text(
                      ass.grade.letter,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: ass.flag == 'Exempt'
                            ? Colors.grey
                            : Color(ass.grade.color),
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      width: 30.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: ass.flag == 'Exempt'
                            ? Colors.grey
                            : Color(ass.grade.color),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        ass.grade.letter,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
            ),
            bottom: ListTile(
              subtitle: Text(
                  '${sourceClass.getCategory(ass).name.length > 25 ? sourceClass.getCategory(ass).name.substring(0, 25) + '...' : sourceClass.getCategory(ass).name}\n${ass.dueDate.month}/${ass.dueDate.day}/${ass.dueDate.year}'),
              title: Text(
                  '${ass.grade.fancyScore}${ass.flag == '' ? '' : ' (' + ass.flag + ')'}'),
              trailing: Text(ass.grade.graded ? '${ass.grade.percent}%' : '',
                  style: TextStyle(fontSize: 17.0)),
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
}

class SourceApp extends StatelessWidget {
  Future<String> _checkLoggedIn() async {
    var prefs = await SharedPreferences.getInstance();
    var keys = prefs.getKeys();
    if (!keys.contains('hasClickedToCopy')) {
      await prefs.setBool('hasClickedToCopy', globals.hasClickedToCopy);
    }
    globals.hasClickedToCopy = prefs.getBool('hasClickedToCopy');
    if (!keys.contains('a') || !keys.contains('b')) {
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
    return DynamicTheme(
      defaultBrightness: Brightness.dark,
      data: (brightness) => ThemeData(
            primarySwatch: Colors.blue,
            accentColor: Colors.blueAccent,
            brightness: brightness,
            primaryColor: Color.fromRGBO(33, 33, 33, 1),
          ),
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'The Source',
          theme: theme,
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
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  AnimationController _controller;
  SequenceAnimation _rainbow;
  Source _source = Source();
  List<Widget> _tabs = [];
  List<Tab> _barTabs = [];
  String gpa = '';
  bool get _isAdmin {
    var bytes = utf8.encode(globals.username);
    if (sha1.convert(bytes).toString() ==
        'e00d4cc521a30ed62610aa06e1e7d7ef23a22aee')
      return true;
    else
      return false;
  }

  String weightedGpa = '';
  GlobalKey<ScaffoldState> key;
  Map<String, String> selectedChips = {};
  Timer analyticsTimer;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    //print("initState");
    super.initState();

    _controller = AnimationController(vsync: this);
    _rainbow = SequenceAnimationBuilder()
        .addAnimatable(
          animatable:
              ColorTween(begin: Color(0xffff0000), end: Color(0xffffff00)),
          from: const Duration(milliseconds: 0),
          to: const Duration(milliseconds: 500),
          tag: "color",
        )
        .addAnimatable(
          animatable:
              ColorTween(begin: Color(0xffffff00), end: Color(0xff00ff00)),
          from: const Duration(milliseconds: 500),
          to: const Duration(milliseconds: 1000),
          tag: "color",
        )
        .addAnimatable(
          animatable:
              ColorTween(begin: Color(0xff00ff00), end: Color(0xff00ffff)),
          from: const Duration(milliseconds: 1000),
          to: const Duration(milliseconds: 1500),
          tag: "color",
        )
        .addAnimatable(
          animatable:
              ColorTween(begin: Color(0xff00ffff), end: Color(0xff0000ff)),
          from: const Duration(milliseconds: 1500),
          to: const Duration(milliseconds: 2000),
          tag: "color",
        )
        .addAnimatable(
          animatable:
              ColorTween(begin: Color(0xff0000ff), end: Color(0xffff00ff)),
          from: const Duration(milliseconds: 2000),
          to: const Duration(milliseconds: 2500),
          tag: "color",
        )
        .animate(_controller);
    _controller.addListener(() {
      if (_controller.status == AnimationStatus.completed)
        _controller.reverse();
      if (_controller.status == AnimationStatus.dismissed)
        _controller.forward();
    });
    _controller.forward();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (_isAdmin) {
      var bytes = utf8.encode(globals.username + globals.password);
      _tabs = [AdminTab(auth: sha1.convert(bytes).toString()), tabProfile()];
      _barTabs = [
        Tab(
          icon: Icon(Icons.settings),
        ),
        Tab(
          icon: studentPicture(10.0),
        ),
      ];
    } else {
      _tabs = [tabProfile()];
      _barTabs = [
        Tab(
          icon: studentPicture(10.0),
        ),
      ];
    }
    _checkVersion();

    if (analyticsTimer == null)
      analyticsTimer = Timer.periodic(Duration(seconds: 30), (Timer t) {
        if (_results != null) postAnalytics(_results);
      });
    _doQuickRefresh();
    Future.delayed(Duration(seconds: 10), () {
      Timer.periodic(Duration(seconds: 10), (Timer t) {
        if (_results == null) _doRefresh();
      });
    });
  }

  Future<void> _checkVersion() async {
    String currentVersion = await GetVersion.projectVersion;

    http.Response r;
    Map js;
    try {
      r = await http.post(
        'https://ottomated.net/source/version',
        body: json.encode(
            {'version': currentVersion, 'os': Platform.operatingSystem}),
      );
      js = json.decode(r.body);
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      return;
    }
    if (r.statusCode == 200) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
              title: Text('Update Required'),
              content: Text(
                  '$currentVersion => ${js['versionCode']}\n${js['changes']}'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Visit App Store'),
                  onPressed: () async {
                    LaunchReview.launch(
                        androidAppId: 'net.ottomated.sourcemobile',
                        iOSAppId: '1441562686',
                        writeReview: false);
                  },
                ),
              ],
            ),
      );
    }
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
      child: child,
    );
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
    if (_results == null) {
      return Center(
        child: RaisedButton(
          child: Text('Refresh'),
          onPressed: () async {
            _doRefresh();
          },
        ),
      );
    }
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
          'GPA: $gpa\nweighted: $weightedGpa',
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
    if (globals.username == '' || globals.password == '') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
      return;
    }
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
      if (results[1].runtimeType == SocketException) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Internet connection failed"),
              content: Text(
                results[1].toString(),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('Okay'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          },
        );
      } else if (results[2].toString().contains("IOClient.send")) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("The Source is down."),
              content: Text(
                results[1].toString(),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('Okay'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Exception'),
              content: Text(
                results[1].toString(),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('Do nothing'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text('Submit bug report'),
                  onPressed: () async {
                    await makePOST(
                      'https://ottomated.net/source/bugreport',
                      {
                        'error': results[1].toString(),
                        'trace': results[2].toString(),
                        'system': Platform.operatingSystem,
                        'version': await GetVersion.platformVersion,
                        'source': json.encode(results[0]),
                      },
                      true,
                    );
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          },
        );
      }
      return;
    }
    var prefs = await SharedPreferences.getInstance();
    //print(results.classes[0].assignments);

    prefs.setString("results", json.encode(results));
    _performDoRefresh(results);
  }

  SourceResults _results;
  Future<void> _performDoRefresh(SourceResults results) async {
    postAnalytics(results);
    _results = results;
    setState(() {
      globals.name = results.name;
      globals.grade = results.grade;
      globals.studentID = results.studentID;
      globals.stateID = results.stateID;
      globals.imageFilePath = results.imageFilePath;
      Iterable<double> gpas =
          results.classes.map((c) => c.gpa).where((g) => g != null);
      if (gpas.length == 0) {
        gpa = '?';
      } else {
        double preciseGpa = gpas.reduce((a, b) => a + b) / gpas.length;
        globals.gpa = preciseGpa;
        gpa = preciseGpa.toStringAsPrecision(3);
      }
      Iterable<double> weightedGpas =
          results.classes.map((c) => c.weightedGpa).where((g) => g != null);
      if (weightedGpas.length == 0) {
        weightedGpa = '?';
      } else {
        double preciseGpa =
            weightedGpas.reduce((a, b) => a + b) / weightedGpas.length;
        globals.weightedGpa = preciseGpa;
        weightedGpa = preciseGpa.toStringAsPrecision(3);
      }
      if (_isAdmin) {
        var bytes = utf8.encode(globals.username + globals.password);
        _tabs = [AdminTab(auth: sha1.convert(bytes).toString()), tabProfile()];
        _barTabs = [
          Tab(
            icon: Icon(Icons.settings),
          ),
          Tab(
            icon: studentPicture(10.0),
          ),
        ];
        //_tabController.index = 2;
      } else {
        _tabs = [tabProfile()];
        _barTabs = [
          Tab(
            icon: studentPicture(10.0),
          ),
        ];
      }

      results.classes.sort((a, b) {
        int s = b.semester.compareTo(a.semester);
        if (s == 0)
          return (int.tryParse(a.period) ?? 100)
              .compareTo((int.tryParse(a.period) ?? 100));
        else
          return s;
      });

      _tabs.addAll(results.classes.map((sourceClass) {
        int k = sourceClass.semester;
        Color c;
        if (k == 0) {
          c = Colors.white24;
        } else {
          c = Color(sourceClass.overallGrades['S$k'].color);
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
        return ClassTab(
          sourceClass: sourceClass,
          selectedChip: selectedChips[sourceClass.className],
        );
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    var _tabController = TabController(
        vsync: this, length: _barTabs.length, initialIndex: _isAdmin ? 1 : 0);
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
                _doQuickRefresh();
              },
              icon: Icon(Icons.refresh),
              color: _isRefreshing ? Colors.black : Colors.white,
            ),
          ),
          Tooltip(
            message: 'Settings',
            child: IconButton(
              onPressed: () async {
                if (_isRefreshing) return;
                /*if (globals.username == 'test_student' ||
                    globals.username == 'student') {
                  key.currentState.showSnackBar(SnackBar(
                    content: Text('Settings disabled for debug student'),
                    backgroundColor: Theme.of(context).accentColor,
                  ));
                  return;
                }*/
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                          classes: _results == null
                              ? []
                              : (_results.classes == null
                                  ? []
                                  : _results.classes),
                        ),
                  ),
                );
                if (globals.cameBackFromSettingsRefresh) {
                  globals.cameBackFromSettingsRefresh = false;
                  _doRefresh();
                }
              },
              icon: Icon(Icons.settings),
              color: _isRefreshing ? Colors.black : Colors.white,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _barTabs,
          isScrollable: true,
          indicatorColor: DynamicTheme.of(context).brightness == Brightness.dark
              ? null
              : Colors.white,
        ),
      ),
      body: Stack(
        children: _getStackChildren(_tabController),
      ),
    );
  }

  List<Widget> _getStackChildren(TabController _tabController) {
    List<Widget> ws = <Widget>[
      TabBarView(
        controller: _tabController,
        children: _tabs,
      ),
    ];
    if (_isRefreshing) {
      ws.add(
        SizedBox(
            child: AnimatedBuilder(
              builder: (ctx, child) {
                return Theme(
                  data: ThemeData(
                      accentColor: _rainbow["color"].value,
                      backgroundColor: Colors.transparent),
                  child: LinearProgressIndicator(),
                );
              },
              animation: _controller,
            ),
            height: 2.0),
      );
    }
    return ws;
  }
}
