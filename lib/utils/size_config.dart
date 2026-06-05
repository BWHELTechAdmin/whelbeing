import 'package:flutter/widgets.dart';

/// Viewport-relative sizing utility.
///
/// Call [SizeConfig.init] at the start of every [build] method before using
/// [vh] or [vw]:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   SizeConfig.init(context);
///   final vh = SizeConfig.vh;
///   final vw = SizeConfig.vw;
///   // e.g.  height: 10 * vh  →  10 % of screen height
///   //        width: 50 * vw  →  50 % of screen width
/// }
/// ```
class SizeConfig {
  SizeConfig._();

  /// Full logical-pixel width of the screen.
  static late double screenWidth;

  /// Full logical-pixel height of the screen.
  static late double screenHeight;

  /// 1 % of [screenWidth].
  ///
  /// Use as a size multiplier: `width: 50 * vw` → 50 % of screen width.
  static late double vw;

  /// 1 % of [screenHeight].
  ///
  /// Use as a size multiplier: `height: 10 * vh` → 10 % of screen height.
  static late double vh;

  /// Reads the current viewport dimensions from [context] and updates
  /// [screenWidth], [screenHeight], [vw], and [vh].
  ///
  /// Must be called before any other member is accessed.
  static void init(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    screenWidth  = size.width;
    screenHeight = size.height;
    vw = screenWidth  / 100;
    vh = screenHeight / 100;
  }
}
