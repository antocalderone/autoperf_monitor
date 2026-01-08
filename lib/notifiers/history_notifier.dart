// lib/notifiers/history_notifier.dart
import 'package:flutter/material.dart';

class HistoryNotifier with ChangeNotifier {
  void notifyHistoryChanged() {
    notifyListeners();
  }
}
