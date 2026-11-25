package com.leywin.animetint

import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Log
import flutter.overlay.window.flutter_overlay_window.OverlayService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.leywin.animetint/tile"
        private const val LOG_TAG = "AnimeTintTile"
    }

    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isOverlayActive" -> result.success(OverlayService.isRunning)
                "requestTileRefresh" -> {
                    AnimeTintTileService.requestRefresh(this)
                    result.success(true)
                }
                "requestAddTile" -> {
                    result.success(requestAddTile())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel?.setMethodCallHandler(null)
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /**
     * Prompts the user to add the AnimeTint tile to Quick Settings.
     * Only available on Android 13 (API 33) and above. Returns true when the
     * request was dispatched, false otherwise.
     */
    private fun requestAddTile(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        val manager = getSystemService(Context.STATUS_BAR_SERVICE) as? StatusBarManager
            ?: return false
        val component = ComponentName(this, AnimeTintTileService::class.java)
        val icon = Icon.createWithResource(this, R.drawable.ic_animetint_qs)
        val label = getString(R.string.tile_label)
        val executor = Executors.newSingleThreadExecutor()
        try {
            manager.requestAddTileService(
                component,
                label,
                icon,
                executor,
            ) { result ->
                Log.d(LOG_TAG, "requestAddTileService result: $result")
            }
            return true
        } catch (e: Exception) {
            Log.w(LOG_TAG, "requestAddTileService failed", e)
            return false
        }
    }
}