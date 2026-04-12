import 'dart:async';

import 'package:flutter/foundation.dart';

class TrackingProvider extends ChangeNotifier {
  static const Duration initialDuration = Duration(minutes: 30);

  Duration _remaining = initialDuration;
  Timer? _timer;

  Duration get remaining => _remaining;
  bool get isFree => _remaining == Duration.zero;

  String get formattedTime {
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void startCountdown() {
    _timer?.cancel();
    if (_remaining == Duration.zero) {
      _remaining = initialDuration;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > Duration.zero) {
        _remaining -= const Duration(seconds: 1);
        notifyListeners();
        return;
      }

      timer.cancel();
      notifyListeners();
    });
    notifyListeners();
  }

  void resetAndStart() {
    _remaining = initialDuration;
    startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
