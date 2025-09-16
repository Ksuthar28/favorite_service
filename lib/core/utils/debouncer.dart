import 'dart:async';
import 'dart:ui';

class Debouncer {
  final int milliSeconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({this.milliSeconds = 500});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliSeconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
