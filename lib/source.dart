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
  String errorID;
  List<SourceClass> classes;
  SourceResults() {
    this.name = [];
    this.studentID = '';
    this.stateID = '';
    this.imageFilePath = '';
    this.grade = '';
    this.html = '';
    this.errorID = '';
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
  List<SourceCategory> categories;

  String get classNameCased {
    Map<String, String> replaceWords = {'Wrld': 'World', 'Des': 'Design'};
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
      this.assignments,
      this.categories}) {
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
  SourceCategory category;
  List<String> quarters;
  String name;
  List<String> flags;
  SourceAssignmentGrade grade;

  SourceAssignment(
      {this.dueDate,
      this.category,
      this.name,
      this.flags,
      this.grade,
      this.quarters});
  factory SourceAssignment.fromJson(Map<String, dynamic> json) =>
      _$SourceAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$SourceAssignmentToJson(this);
  @override
  String toString() {
    return 'SourceAssignment[$name, ${category.id}, due $dueDate]: $grade';
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
    if (!this.graded) {
      String r = '--/';
      if (this.maxScore.floor() == this.maxScore) {
        r += this.maxScore.floor().toString();
      } else {
        r += this.maxScore.toString();
      }
      return r;
    }
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
  SourceClassGrade(double percent) {
    this.percent = percent;
    for (double high in _letterValues.keys) {
      if (percent >= high) {
        this.letter = _letterValues[high].item1;
        this.color = _letterValues[high].item2;
        break;
      }
    }
  }
  SourceClassGrade.fromP(double percent) {
    this.letter = 'P';
    this.color = 0xFF628D62;
    this.percent = percent;
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

@JsonSerializable()
class SourceCategory {
  String id;
  String name;
  double weight;

  SourceCategory({this.id, this.name, this.weight});
  @override
  String toString() {
    return 'SourceCategory[${name} (${id}: ${weight}%]';
  }

  factory SourceCategory.fromJson(Map<String, dynamic> json) =>
      _$SourceCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$SourceCategoryToJson(this);
}

class Source {
  CookieStore _cookies;
  var _client = http.Client();

  Future<void> parseResHTML(SourceResults res) async {
    res.errorID += '\nParsing html';
    Document document = parse(res.html);

    res.errorID += '\nGetting quarter names';
    // Get names of each quarter/semester
    Element headerRow =
        document.querySelector('#tblgrades tbody tr.center.th2');
    List<String> overallNames =
        headerRow.children.sublist(4, 10).map((el) => el.text).toList();

    res.errorID += '\nGetting rows';
    List<Element> rows =
        document.querySelectorAll('#tblgrades tbody tr.center:not(.th2)');
    for (Element row in rows) {
      res.errorID += '\nParsing period ' + row.firstChild.text;
      // Period
      String period = row.children[0].innerHtml.split('(')[0];
      res.errorID += '\nParsing class name/room ' + row.firstChild.text;
      // Teacher + Class Name box
      Element box = row.querySelector('[align="left"]');
      // Class name and room                v magic character
      String className = box.text.split('\u00A0')[0].trim();
      String room = box.text.split('Rm:')[1].trim();
      // Teacher info
      res.errorID += '\nParsing teacher ' + row.firstChild.text;
      String teacherName = box.children.last.text.trim();
      String teacherEmail =
          box.children.last.attributes['href'].split('mailto:')[1].trim();

      Map<String, SourceClassGrade> grades = {};

      List<SourceAssignment> assignments = [];
      List<SourceCategory> categories = [];

      int i = 0;
      DateTime middle;
      for (Element gradeEl in row.querySelectorAll('.colorMyGrade')) {
        res.errorID += '\nParsing semester grade for class ' +
            className +
            ' text ' +
            gradeEl.text;
        if (gradeEl.text != '[ i ]') {
          RegExp r = RegExp('[0-9]+(?:\.[0-9]+)?');
          double p = double.parse(r.firstMatch(gradeEl.text).group(0));
          if (gradeEl.text.startsWith('P'))
            grades[overallNames[i]] = (SourceClassGrade.fromP(p));
          else
            grades[overallNames[i]] = (SourceClassGrade(p));
          if (overallNames[i] == 'Q1' || overallNames[i] == 'Q3') {
            res.errorID += '\nParsing datetime ' + gradeEl.text;
            middle = _parseDateTime(
                Uri.parse(gradeEl.querySelector('a').attributes['href'])
                    .queryParameters['enddate']
                    .split('/'));
          }
          if (overallNames[i].startsWith('S')) {
            Tuple2 r = await parseResClassPage(
                gradeEl.querySelector('a').attributes['href'],
                middle,
                Tuple2(overallNames[i - 2], overallNames[i - 1]),
                overallNames[i],
                res);
            List<SourceAssignment> newAsses = r.item1;
            List<SourceCategory> newCats = r.item2;
            assignments.addAll(newAsses);
            categories.addAll(newCats);
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
          assignments: assignments,
          categories: categories));
      // Period
      // Teacher + class name
      // Grades
    }
  }

  DateTime _parseDateTime(List<String> date) {
    return DateTime(int.parse(date[2]), int.parse(date[0]), int.parse(date[1]));
  }

  Future<Tuple2<List<SourceAssignment>, List<SourceCategory>>>
      parseResClassPage(
          String url,
          DateTime middle,
          Tuple2<String, String> qnames,
          String semester,
          SourceResults res) async {
    http.Request req;
    http.StreamedResponse response;
    String body;
    res.errorID += '\nRequesting class page ' + url;
    // Make request
    req = http.Request(
        'GET', Uri.parse('https://ps.seattleschools.org/guardian/$url'))
      ..followRedirects = false;
    req.headers.addAll({'Cookie': _cookies.toString()});
    response = await _client.send(req);
    _cookies.setCookies(response.headers['set-cookie']);
    body = await response.stream.transform(utf8.decoder).join();
    Document document = parse(body);

    List<Element> catElements =
        document.querySelectorAll('#sps-assignment-categories > tbody > tr');
    List<SourceCategory> cats = [];

    for (var row in catElements) {
      res.errorID += '\nParsing category name ' + row.firstChild.text;
      List<String> n = row.children[0].text.split(' (');
      if (n.length != 2) continue;
      String id = n[1].split(')')[0];
      String name = n[0];

      res.errorID += '\nParsing category weight ' + row.children[1].text;
      String w = row.children[1].text.split('%')[0];
      double weight;
      if (w == '-') {
        weight = 0.0;
      } else {
        weight = double.parse(row.children[1].text.split('%')[0]);
      }
      cats.add(SourceCategory(
        id: id,
        name: name,
        weight: weight,
      ));
    }

    List<Element> assElements = document
        .querySelectorAll('.box-round > table[align="center"] > tbody > tr');

    List<SourceAssignment> asses = [];

    for (var row in assElements) {
      if (row.children[0].text == 'No assignments found.') continue;
      res.errorID += '\nGetting date ' + row.children[0].text;
      List<String> date = row.children[0].text.split('/');
      if (date.length == 1) continue;
      //SourceAssignmentGrade grade = SourceAssignmentGrade(9.0, 10.0);
      String category = row.children[1].text;
      String name = row.children[2].text;
      res.errorID += '\nParsing grade ' + row.children[8].text;
      List<String> grade = row.children[8].text.split('/');
      bool graded = true;
      if (grade.length == 1) grade.add('0');
      if (grade[0] == '--' || grade[0] == 'Score Not Published') {
        graded = false;
        grade[0] = '0';
      }
      res.errorID += '\nParsing date $date';
      DateTime dueDate = _parseDateTime(date);

      res.errorID += '\nConstructing ass: grade: $grade';
      //print('${dueDate} ${middle} ${qnames}');
      SourceAssignment ass = SourceAssignment(
          dueDate: dueDate,
          grade: SourceAssignmentGrade(
              double.parse(grade[0]), double.parse(grade[1]), graded),
          category: cats.firstWhere(
            (c) => c.id == category,
            orElse: () => SourceCategory(id: '', name: '', weight: 0.0),
          ),
          name: name,
          quarters: [
            semester,
            dueDate.isAfter(middle) ? qnames.item2 : qnames.item1
          ]);
      asses.add(ass);
    }
    return Tuple2(asses, cats);
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
    if (username == 'test_student' || username == 'student') {
      SourceResults res = SourceResults();
      res.grade = '12';
      res.stateID = '1234567890';
      res.studentID = '1234567';
      res.name = ['John', 'Doe'];
      // Download photo
      http.Response response =
          await http.get('https://picsum.photos/200/?random');
      var bytes = response.bodyBytes;
      String dir = (await getApplicationDocumentsDirectory()).path;
      File file = File('$dir/${res.name[0]}.jpeg');
      res.imageFilePath = '$dir/${res.name[0]}.jpeg';
      await file.writeAsBytes(bytes);
      res.classes = [
        SourceClass(
          className: 'AP CALCULUS',
          period: '1',
          teacherName: 'Math Teacher',
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
              category:
                  SourceCategory(id: 'HW', name: 'Homework', weight: 50.0),
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(10.0, 10.0, true),
              name: 'Homework 1',
            ),
            SourceAssignment(
              category: SourceCategory(id: 'TST', name: 'Tests', weight: 50.0),
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(87.0, 100.0, true),
              name: 'Unit Test',
            ),
            SourceAssignment(
              category:
                  SourceCategory(id: 'HW', name: 'Homework', weight: 50.0),
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(0.0, 10.0, false),
              name: 'Homework 2',
            ),
          ],
        ),
        SourceClass(
          className: 'WRLD HISTORY 1H',
          period: '2',
          teacherName: 'History Teacher',
          teacherEmail: 'email@example.com',
          overallGrades: {
            'Q1': SourceClassGrade(100.0),
            'Q2': SourceClassGrade(100.0),
            'S1': SourceClassGrade(100.0),
          },
          assignments: [
            SourceAssignment(
              category: SourceCategory(
                  id: 'TEST', name: 'Tests/Quizzes', weight: 50.0),
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(100.0, 100.0, true),
              name: 'Unit 1',
            ),
            SourceAssignment(
              category: SourceCategory(
                  id: 'TEST', name: 'Tests/Quizzes', weight: 50.0),
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(80.0, 100.0, true),
              name: 'Unit 2',
            ),
            SourceAssignment(
              category: SourceCategory(
                  id: 'TEST', name: 'Tests/Quizzes', weight: 50.0),
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(70.0, 100.0, true),
              name: 'Unit 3',
            ),
            SourceAssignment(
              category: SourceCategory(
                  id: 'TEST', name: 'Tests/Quizzes', weight: 50.0),
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(60.0, 100.0, true),
              name: 'Unit 4',
            ),
            SourceAssignment(
              category: SourceCategory(
                  id: 'TEST', name: 'Tests/Quizzes', weight: 50.0),
              dueDate: DateTime.now(),
              grade: SourceAssignmentGrade(50.0, 100.0, true),
              name: 'Unit 5',
            ),
          ],
        ),
      ];
      return res;
    }
    SourceResults res = SourceResults();
    res.errorID += '\nRequest 1';
    try {
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
      res.errorID += '\nRequest 2';
      req = http.Request(
          'GET', Uri.parse('https://ps.seattleschools.org/my.policy'))
        ..followRedirects = false;
      req.headers.addAll({'Cookie': _cookies.toString()});
      response = await _client.send(req);
      _cookies.setCookies(response.headers['set-cookie']);
      // Get home
      res.errorID += '\nRequest 3';
      req = http.Request(
          'GET', Uri.parse('https://ps.seattleschools.org/public/home.html'))
        ..followRedirects = false;
      req.headers.addAll({'Cookie': _cookies.toString()});
      response = await _client.send(req);
      if (response.headers['set-cookie'] == null)
        throw Exception(
            'The Source is down for maintenance.\nRegular hours:\nWednesday: 10PM - 11PM\nSaturday: 6AM-9AM');
      _cookies.setCookies(response.headers['set-cookie']);
      // Parse out tokens
      res.errorID += '\nRequest 3: getting tokens';
      String body = await response.stream.transform(utf8.decoder).join();
      RegExp pstokenRgx =
          RegExp(r'<input type="hidden" name="pstoken" value="(\w+?)" \/>');
      RegExp contextDataRgx = RegExp(
          r'<input type="hidden" name="contextData" id="contextData" value="(\w+?)" \/>');
      String pstoken = pstokenRgx.firstMatch(body).group(1);
      String contextData = contextDataRgx.firstMatch(body).group(1);
      res.errorID += '\nRequest 4';
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
      res.errorID += '\nRequest 5';
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

      res.errorID += '\nGetting student info';
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

      res.errorID += '\nGetting photo';
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

      res.errorID += '\nGetting full name';
      // Extract full name
      RegExp nameRgx = RegExp('<title>(.+)<\\/title>');
      String name = nameRgx.firstMatch(body).group(1);
      res.name.addAll(name.split(', ')[1].split(' '));
      res.name.add(name.split(', ')[0]);
      res.errorID += '\nDownloading photo';
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
    } catch (e, trace) {
      return [res, e, trace];
    }
  }
}
