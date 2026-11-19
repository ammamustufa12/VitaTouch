import 'package:flutter/foundation.dart';

class ShellController extends ChangeNotifier {
  static const stickerTab = 4;

  int index = 0;

  void openTab(int value) {
    final next = value.clamp(0, 3);
    if (next == index) {
      return;
    }
    index = next;
    notifyListeners();
  }
}
