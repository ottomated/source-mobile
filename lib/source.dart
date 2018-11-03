library source;

import 'package:tuple/tuple.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
part 'source.g.dart';

@JsonSerializable()
class SourceResults {
  List<String> name;
  String studentID;
  String stateID;
  String imageFilePath;
  String grade;
  String html;
  List<SourceClass> classes;
  SourceResults() {
    this.name = [];
    this.studentID = '';
    this.stateID = '';
    this.imageFilePath = '';
    this.grade = '';
    this.html = '';
    this.classes = [];
  }
  factory SourceResults.fromJson(Map<String, dynamic> json) =>
      _$SourceResultsFromJson(json);
  Map<String, dynamic> toJson() => _$SourceResultsToJson(this);
}

@JsonSerializable()
class SourceClass {
  String className;
  String period;
  String teacherName;
  String teacherEmail;
  String roomNumber;
  double gpaWeight;

  Map<String, SourceClassGrade> overallGrades;
  List<SourceAssignment> assignments;

  String get classNameCased {
    Map<String, String> replaceWords = {'Wrld': 'World'};
    List<String> acronyms = ['AP', 'CIHS'];
    return this.className.splitMapJoin(RegExp(r'\S+'), onMatch: (m) {
      String word = m.group(0);
      bool parentheses = false;
      if (word.startsWith('(')) {
        parentheses = true;
        word = word.substring(1, word.length - 1);
      }
      if (word.length < 3) {
        return word;
      } else if (acronyms.contains(word)) {
        if (parentheses) word = '(' + word + ')';
        return word;
      } else if (word.contains(RegExp(r'[0-9]'))) {
        return word;
      }
      word = word[0] + word.substring(1, word.length).toLowerCase();
      if (replaceWords.containsKey(word)) word = replaceWords[word];

      if (parentheses) word = '(' + word + ')';
      return word;
    });
  }

  SourceClass(
      {this.className,
      this.period,
      this.teacherName,
      this.teacherEmail,
      this.roomNumber,
      this.overallGrades,
      this.assignments}) {
    Iterable<String> nameWords = this.className.split(' ');
    if (nameWords.contains('AP')) {
      this.gpaWeight = 0.05;
    } else if ('' !=
        nameWords.firstWhere(
            (w) =>
                w == 'H' || w.startsWith((RegExp(r'[0-9]'))) && w.endsWith('H'),
            orElse: () => '')) {
      this.gpaWeight = 0.045;
    } else {
      this.gpaWeight = 0.04;
    }
  }
  @override
  String toString() {
    return 'SourceClass[$className, period $period, rm $roomNumber]\n$teacherName: $teacherEmail\n' +
        overallGrades.keys
            .map((q) => '$q: ${overallGrades[q]}')
            .toList()
            .join(', ') +
        '\n\n';
  }

  factory SourceClass.fromJson(Map<String, dynamic> json) =>
      _$SourceClassFromJson(json);
  Map<String, dynamic> toJson() => _$SourceClassToJson(this);
}

@JsonSerializable()
class SourceAssignment {
  DateTime dueDate;
  String category;
  String name;
  List<String> flags;
  SourceAssignmentGrade grade;

  SourceAssignment(
      {this.dueDate, this.category, this.name, this.flags, this.grade});
  factory SourceAssignment.fromJson(Map<String, dynamic> json) =>
      _$SourceAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$SourceAssignmentToJson(this);
  @override
  String toString() {
    return 'SourceAssignment[$name, $category, due $dueDate]: $grade';
  }
}

@JsonSerializable()
class SourceAssignmentGrade {
  String letter;
  double percent;
  double score;
  double maxScore;
  bool graded;
  int color;
  Map<double, Tuple2<String, int>> _letterValues = {
    92.5: Tuple2('A', 0xFF87BD6C),
    89.5: Tuple2('A-', 0xFF87BD6C),
    86.5: Tuple2('B+', 0xFFCFE7FF),
    82.5: Tuple2('B', 0xFFCFE7FF),
    79.5: Tuple2('B-', 0xFFCFE7FF),
    76.5: Tuple2('C+', 0xFFFFFF8D),
    72.5: Tuple2('C', 0xFFFFFF8D),
    69.5: Tuple2('C-', 0xFFFFFF8D),
    66.5: Tuple2('D+', 0xFFF9AC48),
    59.5: Tuple2('D', 0xFFF9AC48),
    0.0: Tuple2('E', 0xFFEF3D3D),
  };
  SourceAssignmentGrade(score, maxScore, graded) {
    this.graded = graded;
    this.score = score;
    this.maxScore = maxScore;
    if (this.maxScore == 0.0) {
      this.percent = 100.0;
    } else {
      this.percent = score / maxScore * 100.0;
      this.percent = (this.percent * 100).roundToDouble() / 100.0;
    }
    if (!graded) {
      this.letter = '?';
      this.color = 0xFFBBBBBB;
    } else {
      for (double high in _letterValues.keys) {
        if (this.percent >= high) {
          this.letter = _letterValues[high].item1;
          this.color = _letterValues[high].item2;
          break;
        }
      }
    }
  }
  @override
  String toString() {
    return 'Grade[$score/$maxScore: $percent ($letter)]';
  }

  String get fancyScore {
    if (!this.graded) return '--/${this.maxScore}';
    String r = '';
    if (this.score.floor() == this.score) {
      r += this.score.floor().toString();
    } else {
      r += this.score.toString();
    }
    r += '/';
    if (this.maxScore.floor() == this.maxScore) {
      r += this.maxScore.floor().toString();
    } else {
      r += this.maxScore.toString();
    }
    return r;
  }

  factory SourceAssignmentGrade.fromJson(Map<String, dynamic> json) =>
      _$SourceAssignmentGradeFromJson(json);
  Map<String, dynamic> toJson() => _$SourceAssignmentGradeToJson(this);
}

@JsonSerializable()
class SourceClassGrade {
  String letter;
  double percent;
  int color;
  Map<double, Tuple2<String, int>> _letterValues = {
    92.5: Tuple2('A', 0xFF87BD6C),
    89.5: Tuple2('A-', 0xFF87BD6C),
    86.5: Tuple2('B+', 0xFFCFE7FF),
    82.5: Tuple2('B', 0xFFCFE7FF),
    79.5: Tuple2('B-', 0xFFCFE7FF),
    76.5: Tuple2('C+', 0xFFFFFF8D),
    72.5: Tuple2('C', 0xFFFFFF8D),
    69.5: Tuple2('C-', 0xFFFFFF8D),
    66.5: Tuple2('D+', 0xFFF9AC48),
    59.5: Tuple2('D', 0xFFF9AC48),
    0.0: Tuple2('E', 0xFFEF3D3D),
  };
  SourceClassGrade(percent) {
    this.percent = percent;
    for (double high in _letterValues.keys) {
      if (percent >= high) {
        this.letter = _letterValues[high].item1;
        this.color = _letterValues[high].item2;
        break;
      }
    }
  }
  @override
  String toString() {
    return 'Grade[$percent ($letter)]';
  }

  factory SourceClassGrade.fromJson(Map<String, dynamic> json) =>
      _$SourceClassGradeFromJson(json);
  Map<String, dynamic> toJson() => _$SourceClassGradeToJson(this);
}

class CookieStore {
  Map<String, String> cookies;

  CookieStore() {
    this.cookies = Map();
  }

  setCookies(String raw) {
    List<String> array = raw.split(RegExp('(?:secure,|HttpOnly,)'));
    for (String cookie in array) {
      cookie = cookie.split(';')[0];
      List<String> _ = cookie.split('=');
      String key = _[0];
      String value = _[1];
      this.cookies[key] = value;
    }
  }

  toString() {
    return this
        .cookies
        .keys
        .map((key) => '$key=${this.cookies[key]}')
        .join('; ');
  }
}

class Source {
  CookieStore _cookies;
  var _client = http.Client();

  Future<void> parseResHTML(SourceResults res) async {
    Document document = parse(res.html);

    // Get names of each quarter/semester
    Element headerRow =
        document.querySelector('#tblgrades tbody tr.center.th2');
    List<String> overallNames =
        headerRow.children.sublist(4, 10).map((el) => el.text).toList();

    List<Element> rows =
        document.querySelectorAll('#tblgrades tbody tr.center:not(.th2)');
    for (Element row in rows) {
      // Period
      String period = row.children[0].innerHtml.split('(')[0];
      // Teacher + Class Name box
      Element box = row.querySelector('[align="left"]');
      // Class name and room                v magic character
      String className = box.text.split('\u00A0')[0].trim();
      String room = box.text.split('Rm:')[1].trim();
      // Teacher info
      String teacherName = box.children.last.text.trim();
      String teacherEmail =
          box.children.last.attributes['href'].split('mailto:')[1].trim();

      Map<String, SourceClassGrade> grades = {};
      // Assignments
      List<SourceAssignment> assignments = [];

      int i = 0;
      for (Element gradeEl in row.querySelectorAll('.colorMyGrade')) {
        if (gradeEl.text != '[ i ]') {
          RegExp r = RegExp('[0-9]+(?:\.[0-9]+)?');
          grades[overallNames[i]] = (SourceClassGrade(
              double.parse(r.firstMatch(gradeEl.text).group(0))));
          if (overallNames[i].startsWith('S')) {
            List<SourceAssignment> newAsses = await parseResClassPage(
              gradeEl.querySelector('a').attributes['href'],
            );
            assignments.addAll(newAsses);
          }
        }
        i++;
      }

      res.classes.add(SourceClass(
          period: period,
          className: className,
          roomNumber: room,
          teacherName: teacherName,
          teacherEmail: teacherEmail,
          overallGrades: grades,
          assignments: assignments));
      // Period
      // Teacher + class name
      // Grades
    }
  }

  Future<List<SourceAssignment>> parseResClassPage(String url) async {
    http.Request req;
    http.StreamedResponse response;
    String body;
    // Make request
    req = http.Request(
        'GET', Uri.parse('https://ps.seattleschools.org/guardian/$url'))
      ..followRedirects = false;
    req.headers.addAll({'Cookie': _cookies.toString()});
    response = await _client.send(req);
    _cookies.setCookies(response.headers['set-cookie']);
    body = await response.stream.transform(utf8.decoder).join();
    Document document = parse(body);
    //print(body);
    List<Element> assElements = document
        .querySelectorAll('.box-round > table[align="center"] > tbody > tr');

    List<SourceAssignment> asses = [];
    for (var row in assElements) {
      if (row.children[0].text == 'No assignments found.') continue;
      List<String> date = row.children[0].text.split('/');
      if (date.length == 1) continue;
      //SourceAssignmentGrade grade = SourceAssignmentGrade(9.0, 10.0);
      String category = row.children[1].text;
      String name = row.children[2].text;
      List<String> grade = row.children[8].text.split('/');
      bool graded = true;
      if (grade.length == 1) grade.add('0');
      if (grade[0] == '--' || grade[0] == 'Score Not Published') {
        graded = false;
        grade[0] = '0';
      }
      SourceAssignment ass = SourceAssignment(
          dueDate: DateTime(
              int.parse(date[2]), int.parse(date[1]), int.parse(date[0])),
          grade: SourceAssignmentGrade(
              double.parse(grade[0]), double.parse(grade[1]), graded),
          category: category,
          name: name);
      asses.add(ass);
    }
    return asses;
  }

  String generateLoginBody(
      String username, String password, String pstoken, String contextData) {
    String b64pw = base64
        .encode(md5.convert(utf8.encode(password)).bytes)
        .replaceAll('=', '');
    String hmaced = Hmac(md5, utf8.encode(contextData))
        .convert(utf8.encode(b64pw))
        .toString();
    String dbpw = Hmac(md5, utf8.encode(contextData))
        .convert(utf8.encode(password.toLowerCase()))
        .toString();
    Map<String, String> req = {
      'pstoken': pstoken,
      'contextData': contextData,
      'dbpw': dbpw,
      'translator_username': '',
      'translator_password': '',
      'translator_ldappassword': '',
      'returnUrl': '',
      'serviceName': 'PS Parent Portal',
      'serviceTicket': '',
      'pcasServerUrl': '/',
      'credentialType': 'User Id and Password Credential',
      'ldappassword': password,
      'account': username,
      'pw': hmaced,
      'translatorpw': ''
    };
    List<String> formdata = [];
    for (String key in req.keys) {
      formdata
          .add('$key=${Uri.encodeComponent(req[key]).replaceAll('%20', '+')}');
    }

    return formdata.join('&');
  }

  Future doReq(String username, String password) async {
    if (username == 'test_student') {
      SourceResults res = SourceResults();
      res.grade = '12';
      res.stateID = '1234567890';
      res.studentID = '1234567';
      res.name = ['Test', 'Student'];
      // Download photo
      http.Response response = await http.get('https://picsum.photos/200/?random');
      var bytes = response.bodyBytes;
      String dir = (await getApplicationDocumentsDirectory()).path;
      File file = File('$dir/${res.name[0]}.jpeg');
      res.imageFilePath = '$dir/${res.name[0]}.jpeg';
      await file.writeAsBytes(bytes);
      res.classes = [
        SourceClass(
          className: 'AP CLASS 1',
          period: '1',
          teacherName: 'Teacher Name',
          teacherEmail: 'email@example.com',
          overallGrades: {
            'Q1': SourceClassGrade(100.0),
            'Q2': SourceClassGrade(80.0),
            'S1': SourceClassGrade(70.0),
            'Q3': SourceClassGrade(60.0),
            'Q4': SourceClassGrade(50.0),
            'S2': SourceClassGrade(40.0),
          },
          assignments: [
            SourceAssignment(
              category: 'HW',
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(10.0, 10.0, true),
              name: 'Assignment 1',
            ),
            SourceAssignment(
              category: 'HW',
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(87.0, 100.0, true),
              name: 'Assignment 2',
            ),
            SourceAssignment(
              category: 'HW',
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(0.0, 10.0, false),
              name: 'Ungraded Assignment 3',
            ),
          ],
        ),SourceClass(
          className: 'HONORS CLASS 1H',
          period: '2',
          teacherName: 'Teacher Name',
          teacherEmail: 'email@example.com',
          overallGrades: {
            'Q1': SourceClassGrade(100.0),
            'Q2': SourceClassGrade(100.0),
            'S1': SourceClassGrade(100.0),
          },
          assignments: [
            SourceAssignment(
              category: 'TEST',
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(100.0, 100.0, true),
              name: 'Assignment 1',
            ),
            SourceAssignment(
              category: 'TEST',
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(80.0, 100.0, true),
              name: 'Assignment 2',
            ),
            SourceAssignment(
              category: 'TEST',
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(70.0, 100.0, true),
              name: 'Assignment 3',
            ),
            SourceAssignment(
              category: 'TEST',
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(60.0, 100.0, true),
              name: 'Assignment 4',
            ),
            SourceAssignment(
              category: 'TEST',
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(50.0, 100.0, true),
              name: 'Assignment 5',
            ),
          ],
        ),
      ];
      return res;
    }
      SourceResults res = SourceResults();
      http.Request req;
      http.StreamedResponse response;
      _cookies = CookieStore();
      // Initialize session
      req = http.Request(
          'GET', Uri.parse('https://ps.seattleschools.org/public/'))
        ..followRedirects = false;
      response = await _client.send(req);
      _cookies.setCookies(response.headers['set-cookie']);
      // Initialize session
      req = http.Request(
          'GET', Uri.parse('https://ps.seattleschools.org/my.policy'))
        ..followRedirects = false;
      req.headers.addAll({'Cookie': _cookies.toString()});
      response = await _client.send(req);
      _cookies.setCookies(response.headers['set-cookie']);
      // Get home
      req = http.Request(
          'GET', Uri.parse('https://ps.seattleschools.org/public/home.html'))
        ..followRedirects = false;
      req.headers.addAll({'Cookie': _cookies.toString()});
      response = await _client.send(req);
      _cookies.setCookies(response.headers['set-cookie']);
      // Parse out tokens
      String body = await response.stream.transform(utf8.decoder).join();
      RegExp pstokenRgx =
          RegExp(r'<input type="hidden" name="pstoken" value="(\w+?)" \/>');
      RegExp contextDataRgx = RegExp(
          r'<input type="hidden" name="contextData" id="contextData" value="(\w+?)" \/>');
      String pstoken = pstokenRgx.firstMatch(body).group(1);
      String contextData = contextDataRgx.firstMatch(body).group(1);
      // Login request
      req = http.Request(
          'POST', Uri.parse('https://ps.seattleschools.org/guardian/home.html'))
        ..followRedirects = false;
      req.headers.addAll({
        'Cookie': _cookies.toString(),
        'Content-Type': 'application/x-www-form-urlencoded'
      });
      req.body = generateLoginBody(username, password, pstoken, contextData);
      response = await _client.send(req);
      _cookies.setCookies(response.headers['set-cookie']);
      // Get page html
      req = http.Request(
          'GET', Uri.parse('https://ps.seattleschools.org/guardian/home.html'))
        ..followRedirects = false;
      req.headers.addAll({'Cookie': _cookies.toString()});
      response = await _client.send(req);
      _cookies.setCookies(response.headers['set-cookie']);
      if (response.statusCode != 200) {
        return null;
      }
      body = await response.stream.transform(utf8.decoder).join();
      res.html = body;

      // Get stuff from home
      res.studentID =
          RegExp(r'Student ID #:<\/div>[\s\S]+?st-demo-val">(.+?)<\/div>')
              .firstMatch(body)
              .group(1);
      res.stateID =
          RegExp(r'State ID #:<\/div>[\s\S]+?st-demo-val">(.+?)<\/div>')
              .firstMatch(body)
              .group(1);
      res.grade =
          RegExp(r'Grade Level:<\/div>[\s\S]+?st-demo-val">(.+?)<\/div>')
              .firstMatch(body)
              .group(1);

      // Download photo html page
      req = http.Request(
          'GET',
          Uri.parse(
              'https://ps.seattleschools.org/guardian/student_photo.html'))
        ..followRedirects = false;
      req.headers.addAll({'Cookie': _cookies.toString()});
      response = await _client.send(req);
      _cookies.setCookies(response.headers['set-cookie']);
      body = await response.stream.transform(utf8.decoder).join();
      // Extract photo url
      RegExp studentPhotoRgx = RegExp('<img src="(.+)" alt="');
      String studentPhotoUrl = 'https://ps.seattleschools.org' +
          studentPhotoRgx.firstMatch(body).group(1);

      // Extract full name
      RegExp nameRgx = RegExp('<title>(.+)<\\/title>');
      String name = nameRgx.firstMatch(body).group(1);
      res.name.addAll(name.split(', ')[1].split(' '));
      res.name.add(name.split(', ')[0]);
      // Download photo
      req = http.Request('GET', Uri.parse(studentPhotoUrl))
        ..followRedirects = false;
      req.headers.addAll({'Cookie': _cookies.toString()});
      response = await _client.send(req);
      var bytes = await response.stream.toBytes();
      String dir = (await getApplicationDocumentsDirectory()).path;
      File file = File('$dir/${res.name[0]}.jpeg');
      res.imageFilePath = '$dir/${res.name[0]}.jpeg';
      await file.writeAsBytes(bytes);

      // Parse HTMLs
      await parseResHTML(res);
      return res;
  }
}
