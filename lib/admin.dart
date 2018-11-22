import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tuple/tuple.dart';

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
      Fluttertoast.showToast(msg: e.toString());
      return e.toString();
    }
    if (r.statusCode != 404 && r.statusCode != 200) {
      Fluttertoast.showToast(
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
            child: Text(snapshot.data),
          );
        }
        List users = json.decode(snapshot.data);
        users.forEach((u) => u['school'] = (u['username'] as String).split('_')[0].toUpperCase());
        if (widget.isUserTab) {
          print(users);
          return Column(
            children: <Widget>[
              Center(
                child: Padding(
                  child: Text(
                    'Admin Panel',
                    style: TextStyle(fontSize: 24.0),
                  ),
                  padding: EdgeInsets.all(24.0),
                ),
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
                    children: users.map((c) {
                      String last = DateTime.now()
                          .difference(DateTime.parse(c['last_online']))
                          .inSeconds
                          .toString();
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
                          subtitle: Text('Last online: $last seconds ago'),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        } else {
          users.forEach((u) => u['notifications'] = (u['notifications'] as bool) ? 'on' : 'off');

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
      under[item] = count;
      entries.add(
          CircularSegmentEntry(count.toDouble(), colors[colorIndex], rankKey: item));
          colorIndex++;
    });
    return Tuple2(entries, under);
  }

  @override
  Widget build(BuildContext context) {
    Iterable<String> byProp = this.users.map((u) => u[this.prop]);
    Tuple2 t = pieFromList(byProp);

    List<CircularStackEntry> stacks = [CircularStackEntry(t.item1)];

    Map underMap = t.item2 as Map;

    String under ='${this.prop}\n' + 
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
