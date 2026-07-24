import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/edge_theme.dart';
import '../fps_monitor.dart';
import '../memory_monitor.dart';

class TelemetryOverlay extends ConsumerWidget {
  const TelemetryOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fps = ref.watch(fpsProvider);
    final memoryMb = ref.watch(memoryProvider);

    Color getFpsColor(double fps) {
      if (fps >= 55) return EdgeTheme.stateGood;
      if (fps >= 30) return EdgeTheme.stateWarn;
      return EdgeTheme.stateFail;
    }

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: EdgeTheme.surfaceOverlay.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: EdgeTheme.surfaceRaised),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'FPS: ${fps.toStringAsFixed(1).padLeft(4, '0')}',
                    style: EdgeTheme.monoTextStyle.copyWith(
                      color: getFpsColor(fps),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'MEM: ${memoryMb.toStringAsFixed(1).padLeft(5, '0')} MB',
                    style: EdgeTheme.monoTextStyle.copyWith(
                      color: EdgeTheme.stateGood,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
