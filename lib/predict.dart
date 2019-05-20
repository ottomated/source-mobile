import 'package:flutter/material.dart';
import 'source.dart';
import 'package:dynamic_theme/dynamic_theme.dart';

class PredictPage extends StatefulWidget {
  PredictPage({Key key, this.sourceClass}) : super(key: key);
  final SourceClass sourceClass;

  @override
  PredictPageState createState() {
    return PredictPageState();
  }
}

class PredictPageState extends State<PredictPage> {
  TextEditingController _maxScoreController = TextEditingController(text: "0");
  TextEditingController _pScoreController = TextEditingController();
  TextEditingController _percentController = TextEditingController();
  FocusNode _maxScoreFocus = FocusNode();
  FocusNode _pScoreFocus = FocusNode();
  FocusNode _percentFocus = FocusNode();

  SourceCategory _selectedCategory;
  int _maxScore;
  double _pScore;
  int _percent;

  @override
  void initState() {
    _selectedCategory = widget.sourceClass.latestCategories[0];
    super.initState();
  }

  @override
  void dispose() {
    _maxScoreController.dispose();
    _pScoreController.dispose();
    _percentController.dispose();
    _maxScoreFocus.dispose();
    _pScoreFocus.dispose();
    _percentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = DynamicTheme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    String pFrom = '?';
    String pTo = '?';
    String perScore = '?';
    if (_maxScore != null) {
      // Sum the weighted score of the other categories
      double otherCategories = widget.sourceClass.latestCategories
          .where((c) => c.id != _selectedCategory.id)
          .map((c) => (c.weight / 100) * (c.earned / c.possible))
          .reduce((a, b) => a + b);

      double thisCategory = (_selectedCategory.weight / 100) *
          ((_selectedCategory.earned + _pScore) /
              (_selectedCategory.possible + _maxScore));
      pFrom = widget.sourceClass
              .overallGrades[widget.sourceClass.latestSemester].percent
              .round()
              .toString() +
          '%';
      pTo = ((otherCategories + thisCategory) * 100).round().toString() + '%';
      if (_percent != null) {
        perScore = (((_percent / 100) - otherCategories) /
                        (_selectedCategory.weight / 100) *
                        (_selectedCategory.possible + _maxScore) -
                    _selectedCategory.earned)
                .toStringAsFixed(1) +
            '/' +
            _maxScore.toString();
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Calculator'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Text(
                widget.sourceClass.classNameCased,
                style: TextStyle(fontSize: 24.0),
              ),
            ),
            Padding(padding: EdgeInsets.all(8.0)),
            Center(child: Text('If there was an assignment')),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("in the   "),
                DropdownButton(
                  value: _selectedCategory,
                  items: widget.sourceClass.latestCategories.map((t) {
                    return DropdownMenuItem<SourceCategory>(
                      child: Text(t.name.length > 25
                          ? t.name.substring(0, 25) + '...'
                          : t.name),
                      value: t,
                    );
                  }).toList(),
                  onChanged: (s) {
                    setState(() {
                      _selectedCategory = s;
                    });
                  },
                ),
                Text(" category"),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("with a maximum score of  "),
                Flexible(
                  child: Container(
                    width: 40.0,
                    child: TextField(
                      controller: _maxScoreController,
                      focusNode: _maxScoreFocus,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      onChanged: (s) {
                        int maxScore = (double.tryParse(s) ?? -1).round();

                        int prevMax = _maxScore;
                        if (maxScore > 0) {
                          setState(() {
                            _maxScore = maxScore;

                            if (_pScore == null)
                              _pScore = maxScore.toDouble();
                            else
                              _pScore = (_pScore / prevMax * maxScore * 10)
                                      .roundToDouble() /
                                  10;
                            if (_percent == null)
                              _percent = widget
                                  .sourceClass
                                  .overallGrades[
                                      widget.sourceClass.latestSemester]
                                  .percent
                                  .round();
                            _percentController.value =
                                TextEditingValue(text: _percent.toString());
                            _pScoreController.value =
                                TextEditingValue(text: _pScore.toString());
                          });
                        }
                      },
                      onEditingComplete: () {
                        _maxScoreFocus.unfocus();
                        int maxScore =
                            (double.tryParse(_maxScoreController.value.text) ??
                                    -1)
                                .round();
                        int prevMax = _maxScore;
                        if (maxScore <= 0) {
                          _maxScoreController.value =
                              TextEditingValue(text: '0');
                          return;
                        }
                        _maxScoreController.value =
                            TextEditingValue(text: maxScore.toString());
                        setState(() {
                          _maxScore = maxScore;
                          if (_pScore == null)
                            _pScore = maxScore.toDouble();
                          else
                            _pScore = (_pScore / prevMax * maxScore * 10)
                                    .roundToDouble() /
                                10;

                          _pScoreController.value =
                              TextEditingValue(text: _pScore.toString());
                        });
                      },
                    ),
                  ),
                ),
                Text(" points"),
              ],
            ),
            Padding(padding: EdgeInsets.all(16.0)),
            Divider(),
            Padding(padding: EdgeInsets.all(16.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    text: 'Scoring ',
                    style: TextStyle(fontSize: 13.0, color: textColor),
                  ),
                ),
                Flexible(
                  child: Container(
                    width: 40.0,
                    child: TextField(
                      controller: _pScoreController,
                      focusNode: _pScoreFocus,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      enabled: _maxScore != null,
                      onChanged: (s) {
                        double pScore = (double.tryParse(s) ?? -1);
                        if (pScore < 0) pScore = 0;

                        setState(() {
                          _pScore = pScore;
                        });
                      },
                      onEditingComplete: () {
                        _pScoreFocus.unfocus();
                        double pScore =
                            (double.tryParse(_pScoreController.value.text) ??
                                -1);
                        if (pScore < 0) pScore = 0;

                        _pScoreController.value =
                            TextEditingValue(text: pScore.toString());
                        setState(() {
                          _pScore = pScore;
                        });
                      },
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: ' would bring you from ',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: textColor,
                    ),
                    children: [
                      TextSpan(
                        text: pFrom,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                          color: textColor,
                        ),
                      ),
                      TextSpan(
                        text: ' to ',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: textColor,
                        ),
                      ),
                      TextSpan(
                        text: pTo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            Padding(padding: EdgeInsets.all(8.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RichText(
                    text: TextSpan(
                        text: 'To have at least ',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: textColor,
                        ))),
                Flexible(
                  child: Container(
                    width: 40.0,
                    child: TextField(
                      controller: _percentController,
                      focusNode: _percentFocus,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      enabled: _maxScore != null,
                      onChanged: (s) {
                        int percent = (double.tryParse(s) ?? -1).round();
                        if (percent < 0) percent = 0;
                        setState(() {
                          _percent = percent;
                        });
                      },
                      onEditingComplete: () {
                        _percentFocus.unfocus();
                        int percent =
                            (double.tryParse(_percentController.value.text) ??
                                    -1)
                                .round();
                        if (percent <= 0) {
                          _percentController.value =
                              TextEditingValue(text: '0');
                          return;
                        }
                        _percentController.value =
                            TextEditingValue(text: percent.toString());
                        setState(() {
                          _percent = percent;
                        });
                      },
                    ),
                  ),
                ),
                RichText(
                    text: TextSpan(
                        text: ' percent',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: textColor,
                        ))),
              ],
            ),
            Padding(padding: EdgeInsets.all(4.0)),
            Center(
              child: RichText(
                text: TextSpan(
                  text: 'you would need to score ',
                  style: TextStyle(
                    fontSize: 13.0,
                    color: textColor,
                  ),
                  children: [
                    TextSpan(
                      text: perScore,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
