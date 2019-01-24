import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tuple/tuple.dart';
import 'package:duration/duration.dart';

import 'expanding_card.dart';
import 'dart:convert';

class AdminTab extends StatefulWidget {
  final String auth;
  final bool isUserTab;
  AdminTab({this.auth, this.isUserTab});
  AdminTab.Users({this.auth, this.isUserTab = true});
  AdminTab.Stats({this.auth, this.isUserTab = false});

  @override
  _AdminTabState createState() => _AdminTabState();
}

class _AdminTabState extends State<AdminTab> {
  @override
  void initState() {
    super.initState();
  }

  Future<String> _analytics;

  Future<String> getAnalytics() async {
    http.Response r;
    try {
      r = await http.get('https://ottomated.net/source/admin',
          headers: {'Authentication': widget.auth});
    } catch (e) {
      Fluttertoast.instance.showToast(msg: e.toString());
      return e.toString();
    }
    if (r.statusCode != 404 && r.statusCode != 200) {
      Fluttertoast.instance.showToast(
          msg: 'Server Error (Invalid Request ${r.statusCode})');
      return 'Status ${r.statusCode}';
    }
    return r.body;
  }

  @override
  Widget build(BuildContext context) {
    _analytics = getAnalytics();
    return FutureBuilder(
      future: _analytics,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.data.startsWith('[')) {
          return Center(
            child: Column(
              children: <Widget>[
                Text(snapshot.data),
                RaisedButton(
                  child: Text('Refresh'),
                  onPressed: () async {
                    setState(() {
                      _analytics = getAnalytics();
                    });
                  },
                ),
              ],
            ),
          );
        }
        List users = json.decode(snapshot.data);
        users.forEach((u) => u['school'] =
            (u['username'] as String).split('_')[0].toUpperCase());
        if (widget.isUserTab) {
          ScrollController control = ScrollController();
          return Column(
            children: <Widget>[
              Padding(
                child: Stack(
                  children: <Widget>[
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'Admin Panel',
                          style: TextStyle(fontSize: 24.0),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0.0,
                      right: 0.0,
                      child: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Filter'),
                                content: Column(
                                  children: <Widget>[
                                    Text('Name Filter'),
                                    TextFormField(),
                                  ],
                                ),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  FlatButton(
                                    child: Text('Filter'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 0.0,
                      left: 0.0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_downward),
                        onPressed: () {
                          control.jumpTo(control.position.maxScrollExtent);
                        },
                      ),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(24.0),
              ),
              Flexible(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _analytics = getAnalytics();
                    });
                    return true;
                  },
                  child: ListView(
                    controller: control,
                    physics: AlwaysScrollableScrollPhysics(),
                    children: users.map((c) {
                      Duration time = DateTime.now().difference(
                        DateTime.parse(c['last_online']),
                      );
                      String last;
                      if (time > Duration(seconds: 10))
                        last = prettyDuration(
                          time,
                          abbreviated: true,
                        );
                      else
                        last = '0s';
                      return ExpandingCard(
                        top: ListTile(
                          title: Text(c['name']),
                          subtitle:
                              Text('${c['username']} - Grade ${c['grade']}'),
                          leading: Icon(c['notifications']
                              ? Icons.notifications_active
                              : Icons.notifications_off),
                        ),
                        bottom: ListTile(
                          title: Text('${c['system']} ${c['version']}'),
                          subtitle: Text('Last online: $last ago'),
                          trailing: IconButton(
                            icon: Icon(Icons.info_outline),
                            onPressed: () {
                              List<Widget> children = <Widget>[
                                Text(c['name']),
                                Text('Grade: ${c['grade']}'),
                                Text('GPA: ${c['gpa']}'),
                                Text('Weighted: ${c['weightedGpa']}'),
                                Text('${c['system']} ${c['version']}'),
                                Text('Classes:')
                              ];
                              json.decode(c['classes']).forEach((c) {
                                children.add(
                                  Padding(
                                    child: Text(
                                        '${c['period']}: ${c['name']} rm${c['room']}' +
                                            '\n    ${c['teacher']}'),
                                    padding: EdgeInsets.only(top: 10.0),
                                  ),
                                );
                              });
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('User ${c['username']}'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: children,
                                      ),
                                    ),
                                    actions: <Widget>[
                                      FlatButton(
                                        child: Text('Close'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        } else {
          users.forEach((u) =>
              u['notifications'] = (u['notifications'] as bool) ? 'on' : 'off');

          users.forEach((u) {
            if ((u['school'] as String).contains('@')) {
              u['school'] = 'EMAIL';
            }
          });

          int lastDay = users.where((u) {
            return DateTime.now()
                    .difference(DateTime.parse(u['last_online']))
                    .inDays ==
                0;
          }).length;

          return Column(
            children: <Widget>[
              Padding(
                child: Text(
                  'Admin Panel',
                  style: TextStyle(fontSize: 24.0),
                  textAlign: TextAlign.center,
                ),
                padding: EdgeInsets.all(24.0),
              ),
              Padding(
                child: Text(
                  '${users.length} users',
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                padding: EdgeInsets.all(4.0),
              ),
              Padding(
                child: Text(
                  '$lastDay in last day',
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                padding: EdgeInsets.all(4.0),
              ),
              Flexible(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _analytics = getAnalytics();
                    });
                    return true;
                  },
                  child: ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      PieChart(prop: 'system', users: users),
                      PieChart(prop: 'version', users: users),
                      PieChart(prop: 'grade', users: users),
                      PieChart(prop: 'notifications', users: users),
                      PieChart(prop: 'school', users: users),
                      // Version
                      // Notifications
                      // School
                      // Grade
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class PieChart extends StatelessWidget {
  final List users;
  final String prop;
  final List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.purple,
    Colors.brown,
    Colors.white
  ];
  PieChart({this.users, this.prop});

  Tuple2<List<CircularSegmentEntry>, Map> pieFromList(
      Iterable<String> statsList) {
    List<CircularSegmentEntry> entries = [];
    Set stats = Set.from(statsList);
    Map under = {};
    int colorIndex = 0;
    stats.forEach((item) {
      int count = statsList.where((i) => i == item).length;
      entries.add(CircularSegmentEntry(
          count.toDouble(), colors[colorIndex % colors.length],
          rankKey: item));
      colorIndex++;
    });
    entries.sort((a, b) => b.value.compareTo(a.value));
    entries.forEach((c) => under[c.rankKey] = c.value.toInt());
    return Tuple2(entries, under);
  }

  @override
  Widget build(BuildContext context) {
    Iterable<String> byProp = this.users.map((u) => u[this.prop]);
    Tuple2 t = pieFromList(byProp);

    List<CircularStackEntry> stacks = [CircularStackEntry(t.item1)];

    Map underMap = t.item2 as Map;

    String under = '${this.prop}\n' +
        underMap.keys.map((name) => '$name: ${underMap[name]}').join('\n');

    return Column(
      children: <Widget>[
        AnimatedCircularChart(
          size: Size(200.0, 200.0),
          initialChartData: stacks,
          chartType: CircularChartType.Pie,
        ),
        Text(
          under,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
