
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tuple/tuple.dart';
import 'package:duration/duration.dart';
import 'package:fcharts/fcharts.dart';

import 'expanding_card.dart';
import 'dart:convert';

class AdminTab extends StatefulWidget {
  final String auth;
  AdminTab({this.auth});

  @override
  _AdminTabState createState() => _AdminTabState();
}

class _AdminTabState extends State<AdminTab>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
  }

  final wantKeepAlive = true;

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
        Map<String, dynamic> data;
        try {
          data = json.decode(snapshot.data);
        } on FormatException {
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
        List<Tuple2<String, int>> gpas = [];
        int i = 0;
        for (int gpa in data["gpa"]) {
          gpas.add(Tuple2((4 * i / 20).toString(), gpa));
          i++;
        }
        List<Tuple2<String, int>> aps = [];
        i = 0;
        for (int ap in data["aps"]) {
          gpas.add(Tuple2(i.toString(), ap));
          i++;
        }

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
                '${data["users"]} users',
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
                    PieChart("System", data["system"]),
                    PieChart("Version", data["version"]),
                    PieChart("School", data["school"]),
                    PieChart("Grade", data["grade"]),
                    Histogram(gpas),
                    Histogram(aps),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PieChart extends StatelessWidget {
  final String name;
  final Map<String, int> data;
  final List<String> keys;
  final List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.lightGreen,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.purple,
  ];
  PieChart(this.name, Map<String, dynamic> data)
      : this.data = data.cast<String, int>(),
        this.keys = data.keys.toList()
          ..sort((a, b) => data[b].compareTo(data[a]));

  List<CircularSegmentEntry> pieFromList() {
    List<CircularSegmentEntry> entries = [];
    int colorIndex = 0;
    for (var k in keys) {
      entries.add(CircularSegmentEntry(
        data[k].toDouble(),
        colors[colorIndex % colors.length],
        rankKey: k,
      ));
      colorIndex++;
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    List<CircularStackEntry> stacks = [CircularStackEntry(pieFromList())];

    String under = '${this.name}\n' +
        keys.map((name) => '$name: ${data[name]}').join('\n');

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

class Histogram extends StatelessWidget {
  final List<Tuple2<String, int>> data;

  Histogram(List data)
      : this.data = data.cast<Tuple2<String, int>>();

  @override
  Widget build(BuildContext context) {
    final xAxis = ChartAxis<String>(
      span: ListSpan(data.map((d) => d.item1).toList()),
    );
    int max = 0;
    for (var g in data) {
      if (g.item2 > max) max = g.item2;
    }

    final yAxis = ChartAxis<int>(
      span: IntSpan(0, max),
      tickGenerator: IntervalTickGenerator.byN(15),
    );

    return Padding(
      padding: EdgeInsets.all(32.0),
      child: AspectRatio(
        aspectRatio: 2.0,
        child: BarChart<Tuple2, String, int>(
          data: data,
          xAxis: xAxis,
          yAxis: yAxis,
          bars: [
            Bar<Tuple2, String, int>(
              xFn: (d) => d.item1,
              valueFn: (d) => d.item2,
              fill: PaintOptions.fill(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
