package com.aigrouphobinh.onelife

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Android 7+ Quick Settings entry for the V3.4 "Ghi nhanh" action.
 *
 * The system owns the tile and its location. A tap unlocks the device when
 * necessary and opens the real Flutter task-entry dialog; it does not place
 * an editable field inside Quick Settings or persist unsanitized data here.
 */
class QuickCaptureTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            icon = Icon.createWithResource(this@QuickCaptureTileService, R.drawable.ic_onelife_capture)
            label = "Ghi nhanh"
            contentDescription = "Ghi nhanh OneLife, mở màn nhập công việc"
            state = Tile.STATE_INACTIVE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                subtitle = "Thêm công việc"
            }
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        if (isLocked) {
            // Respect lockscreen privacy: only show task input after unlock.
            unlockAndRun { openCapture() }
        } else {
            openCapture()
        }
    }

    private fun openCapture() {
        val intent = Intent(this, MainActivity::class.java).apply {
            putExtra(MainActivity.EXTRA_QUICK_CAPTURE, true)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pendingIntent = PendingIntent.getActivity(
                this,
                3401,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
