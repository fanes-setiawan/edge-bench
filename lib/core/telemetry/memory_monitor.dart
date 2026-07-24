import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final memoryProvider = NotifierProvider<MemoryNotifier, double>(MemoryNotifier.new);

class MemoryNotifier extends Notifier<double> {
  Timer? _timer;

  @override
  double build() {
    _startMonitoring();
    ref.onDispose(() {
      _timer?.cancel();
    });
    return 0.0;
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final rssMb = ProcessInfo.currentRss / (1024 * 1024);
      state = rssMb;
    });
  }
}

