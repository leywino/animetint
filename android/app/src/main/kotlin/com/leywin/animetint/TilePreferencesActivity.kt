package com.leywin.animetint

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * Target of the tile's native long-press action
 * [android.service.quicksettings.TileService.ACTION_QS_TILE_PREFERENCES].
 *
 * SystemUI resolves an activity in this package handling that action when the
 * user long-presses the tile. If none exists it falls back to the system App
 * details screen. This trampoline simply opens the normal AnimeTint UI and
 * finishes, so a long press never touches the overlay state.
 */
class TilePreferencesActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        startActivity(launchIntent)
        finish()
        overridePendingTransition(0, 0)
    }
}