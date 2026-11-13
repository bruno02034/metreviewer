package com.carriez.flutter_hbb

import android.Manifest.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
import android.Manifest.permission.SYSTEM_ALERT_WINDOW
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.Toast
import com.hjq.permissions.XXPermissions
import io.flutter.embedding.android.FlutterActivity

const val DEBUG_BOOT_COMPLETED = "com.carriez.flutter_hbb.DEBUG_BOOT_COMPLETED"

class BootReceiver : BroadcastReceiver() {
    private val logTag = "tagBootReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(logTag, "onReceive ${intent.action}")

        // Metre: além de ligar o aparelho, sobe o serviço depois de atualizar o app e quando
        // a verificação periódica encontra o serviço parado. Ver METRE-CHANGES.md.
        val action = intent.action
        if (action in listOf(Intent.ACTION_BOOT_COMPLETED, DEBUG_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED, ACT_METRE_WATCHDOG)) {
            // check SharedPreferences config
            val prefs = context.getSharedPreferences(KEY_SHARED_PREFERENCES, FlutterActivity.MODE_PRIVATE)
            if (!prefs.getBoolean(KEY_START_ON_BOOT_OPT, false)) {
                Log.d(logTag, "KEY_START_ON_BOOT_OPT is false")
                return
            }
            // check pre-permission
            if (!XXPermissions.isGranted(context, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, SYSTEM_ALERT_WINDOW)){
                Log.d(logTag, "REQUEST_IGNORE_BATTERY_OPTIMIZATIONS or SYSTEM_ALERT_WINDOW is not granted")
                return
            }
            MetreCompat.scheduleWatchdog(context)
            if (action == ACT_METRE_WATCHDOG && MainService.isReady) return

            val it = Intent(context, MainService::class.java).apply {
                this.action = ACT_INIT_MEDIA_PROJECTION_AND_SERVICE
                putExtra(EXT_INIT_FROM_BOOT, true)
            }
            if (action != ACT_METRE_WATCHDOG) {
                Toast.makeText(context, "MetreViewer: pronto para suporte", Toast.LENGTH_LONG).show()
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(it)
                } else {
                    context.startService(it)
                }
            } catch (e: Exception) {
                // Android 12+ pode recusar o início em segundo plano; a próxima verificação tenta de novo.
                Log.w(logTag, "start service failed: $e")
            }
        }
    }
}
