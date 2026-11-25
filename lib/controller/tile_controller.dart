import 'package:flutter/services.dart';

/// Thin wrapper around the native Quick Settings tile integration.
///
/// The actual overlay state is owned by the native overlay service; this
/// channel only queries it and asks Android to refresh the tile. It never
/// stores overlay state on the Flutter side.
class TileController {
  TileController._();

  static const MethodChannel _channel =
      MethodChannel('com.leywin.animetint/tile');

  /// Returns the real overlay state as reported by the native overlay service.
  static Future<bool> isOverlayActive() async {
    try {
      return await _channel.invokeMethod<bool>('isOverlayActive') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Asks Android to re-listen to the tile so it re-reads the overlay state.
  static Future<void> requestTileRefresh() async {
    try {
      await _channel.invokeMethod<void>('requestTileRefresh');
    } on PlatformException {
      // Ignore: tile refresh is best-effort.
    } on MissingPluginException {
      // Ignore.
    }
  }

  /// Prompts the user to add the AnimeTint tile (Android 13+).
  /// Returns true when the request was dispatched.
  static Future<bool> requestAddTile() async {
    try {
      return await _channel.invokeMethod<bool>('requestAddTile') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}