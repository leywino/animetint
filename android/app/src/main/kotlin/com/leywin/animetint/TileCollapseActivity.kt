package com.leywin.animetint

import android.app.Activity
import android.os.Bundle

/**
 * Invisible activity whose only purpose is to collapse the Quick Settings
 * panel after a tile click.
 *
 * TileService exposes no public "collapse the shade" API, but
 * [android.service.quicksettings.TileService.startActivityAndCollapse] collapses
 * the panel as a side effect of launching an activity. This activity draws
 * nothing and finishes immediately, so the main application is never shown.
 */
class TileCollapseActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        finish()
        overridePendingTransition(0, 0)
    }
}