package com.example.flutter_app_close

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class MyBackgroundService : Service() {

    companion object {
        // Must match the channelKey you define in awesome_notifications init
        const val CHANNEL_KEY = "force_quit_channel"
        const val CHANNEL_NAME = "Force Quit Alerts"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)

        // Build an intent to reopen the app when notification is tapped
        val reopenIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, reopenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_KEY)
            .setContentTitle("Come back!")
            .setContentText("We miss you! Tap to reopen.")
            .setSmallIcon(getSmallIconResource())
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(9999, notification)

        stopSelf()
    }

    private fun getSmallIconResource(): Int {
        // Uses the icon awesome_notifications uses — res/drawable/res_app_icon
        val resId = resources.getIdentifier("res_app_icon", "drawable", packageName)
        return if (resId != 0) resId else android.R.drawable.ic_dialog_info
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_KEY,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            )
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}