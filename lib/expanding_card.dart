library expanding_card;

import 'package:flutter/material.dart';
import 'dart:math';

class ExpandingCard extends StatefulWidget {
  final Widget top;
  final Widget bottom;
  final bool isOpen;

  ExpandingCard({
    Key key,
    @required this.top,
    @required this.bottom,
    this.isOpen = false,
  }) : super(key: key);

  _ExpandingCardState createState() => new _ExpandingCardState(this.isOpen);
}

class _ExpandingCardState extends State<ExpandingCard>
    with TickerProviderStateMixin {
  bool _isOpen;
  bool _isFullyOpen;
  AnimationController _controller;
  Animation _animation;

  _ExpandingCardState(bool _isOpen) {
    this._isOpen = _isOpen;
    this._isFullyOpen = _isOpen;
  }

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = Tween(begin: 0.5, end: 1.0).animate(_controller);
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isFullyOpen = true;
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isFullyOpen = false;
        });
      }
    });
    //_controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _getChildren() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: _isFullyOpen
          ? <Widget>[
              widget.top,
              Divider(),
              widget.bottom,
            ]
          : <Widget>[
              widget.top,
              widget.bottom,
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Column child = _getChildren();
    return Card(
      child: InkWell(
        onTap: () {
          if (_isOpen)
            _controller.reverse();
          else
            _controller.forward();
          _isOpen = !_isOpen;
        },
        child: SizeTransition(
          sizeFactor: _animation,
          child: child,
          axis: Axis.vertical,
          axisAlignment: -1.0,
        ),
      ),
    );
  }
}
