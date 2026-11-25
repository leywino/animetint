package com.leywin.animetint

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import flutter.overlay.window.flutter_overlay_window.OverlayService
import flutter.overlay.window.flutter_overlay_window.WindowSetup

/**
 * Quick Settings tile that toggles the existing AnimeTint overlay.
 *
 * The single source of truth for the overlay state is
 * [OverlayService.isRunning]. That flag is maintained by the shared overlay
 * service (set in onStartCommand, cleared in onDestroy), so it reflects the
 * real native overlay state rather than a persisted "last requested" boolean.
 *
 * The tile and the overlay service run in the same app process, so reading the
 * static flag directly is accurate. When the process is killed and recreated
 * the flag resets to false, which correctly matches the overlay being gone.
 */
class AnimeTintTileService : TileService() {

    companion object {
        private const val TAG = "AnimeTintTile"

        /** Re-listen to this tile so it re-reads the real overlay state. */
        fun requestRefresh(context: Context) {
            try {
                TileService.requestListeningState(context, component(context))
            } catch (e: Exception) {
                Log.w(TAG, "requestListeningState failed", e)
            }
        }

        fun component(context: Context): ComponentName =
            ComponentName(context, AnimeTintTileService::class.java)
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onStartListening() {
        super.onStartListening()
        renderState()
    }

    override fun onStopListening() {
        handler.removeCallbacksAndMessages(null)
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()

        // Read the real state, not a cached preference.
        if (OverlayService.isRunning) {
            stopOverlay()
        } else {
            startOverlay()
        }

        // The service lifecycle settles asynchronously; re-listen shortly after
        // so onStartListening() reads the updated OverlayService.isRunning flag.
        handler.postDelayed({ requestRefresh(this) }, 350)

        // Collapse the Quick Settings panel without launching the main app.
        collapsePanel()
    }

    private fun collapsePanel() {
        try {
            val intent = Intent(this, TileCollapseActivity::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                // Android 14+ forbids the Intent overload and requires a
                // PendingIntent; using the Intent version throws
                // UnsupportedOperationException there.
                val pending = PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
                startActivityAndCollapse(pending)
            } else {
                @Suppress("DEPRECATION")
                startActivityAndCollapse(intent)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Unable to collapse Quick Settings panel", e)
        }
    }

    private fun renderState() {
        val tile: Tile = qsTile ?: return
        val active = OverlayService.isRunning
        // Apply the custom monochrome icon on every render so it is correct in
        // both active and inactive states. Quick Settings applies its own tint
        // to the icon's alpha channel, preserving native tinting behavior.
        tile.icon = Icon.createWithResource(this, R.drawable.ic_animetint_qs)
        tile.state = if (active) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = getString(R.string.tile_label)
        tile.updateTile()
    }

    private fun startOverlay() {
        if (!Settings.canDrawOverlays(this)) {
            // Do not silently bypass the permission; send the user to grant it.
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                android.net.Uri.parse("package:$packageName"),
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivityAndCollapse(intent)
            } catch (e: Exception) {
                Log.w(TAG, "Unable to open overlay settings", e)
            }
            return
        }

        // Reuse the existing overlay service. Configure the same window setup
        // the Flutter app uses so behaviour is identical.
        val setup = WindowSetup.getInstance()
        setup.setWidth(-1) // WindowSize.matchParent
        setup.setHeight(-1999) // WindowSize.fullCover
        setup.setEnableDrag(false)
        setup.setFlag("clickThrough")
        setup.setOverlayTitle("AnimeTint")
        setup.setOverlayContent("Screen filter active")
        setup.setPositionGravity("none")
        setup.setNotificationVisibility("visibilityPublic")
        setup.setNotificationIcon(null)

        val intent = Intent(this, OverlayService::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        try {
            // The overlay service calls startForeground() in onCreate, so on
            // Android O+ it must be started with startForegroundService to
            // avoid background-start restrictions when launched from the tile.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start overlay service", e)
        }
    }

    private fun stopOverlay() {
        val intent = Intent(this, OverlayService::class.java)
        try {
            stopService(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop overlay service", e)
        }
    }
}