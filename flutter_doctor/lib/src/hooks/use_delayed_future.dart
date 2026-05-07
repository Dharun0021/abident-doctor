import 'dart:async';

import 'package:flutter/material.dart';

/// Lightweight "loading then data" pattern for skeleton → content transitions.
class DelayedContentController extends ChangeNotifier {
  DelayedContentController({this.delay = const Duration(milliseconds: 450)});

  final Duration delay;
  bool _ready = false;
  Timer? _timer;

  bool get ready => _ready;

  void start() {
    _ready = false;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(delay, () {
      _ready = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
