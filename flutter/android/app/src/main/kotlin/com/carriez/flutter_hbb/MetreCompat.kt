package com.carriez.flutter_hbb

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock

// Metre: recuperação do serviço e diferenças entre fabricantes, num lugar só. Ver METRE-CHANGES.md.
const val ACT_METRE_WATCHDOG = "com.metre.viewer.WATCHDOG"

object MetreCompat {
    // Verificação periódica: se o Android matar o serviço, o BootReceiver o sobe de novo.
    fun scheduleWatchdog(context: Context) {
        val intent = Intent(context, BootReceiver::class.java).setAction(ACT_METRE_WATCHDOG)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE else PendingIntent.FLAG_UPDATE_CURRENT
        val pending = PendingIntent.getBroadcast(context, 7301, intent, flags)
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.setInexactRepeating(AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + AlarmManager.INTERVAL_FIFTEEN_MINUTES,
            AlarmManager.INTERVAL_FIFTEEN_MINUTES, pending)
    }

    // Telas de "iniciar automaticamente" que alguns fabricantes acrescentam ao Android.
    // Aparelhos com Android puro (como o M10 Bematech/Elgin) não têm nenhuma: a lista volta vazia.
    private val autostartScreens = listOf(
        ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
        ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
        ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
        ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"),
        ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity"),
        ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity"),
    )

    fun autostartIntent(context: Context): Intent? = autostartScreens
        .map { Intent().setComponent(it).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
        .firstOrNull { it.resolveActivity(context.packageManager) != null }
}
