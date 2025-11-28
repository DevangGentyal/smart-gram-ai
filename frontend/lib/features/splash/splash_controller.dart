import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashControllerProvider =
    StateNotifierProvider<SplashController, bool>((ref) {
  return SplashController();
});

class SplashController extends StateNotifier<bool> {
  SplashController() : super(false);

  void start() => state = true;
}


