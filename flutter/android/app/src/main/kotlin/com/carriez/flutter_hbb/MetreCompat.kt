package com.carriez.flutter_hbb

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import android.os.SystemClock

// Metre: recuperação do serviço e diferenças entre fabricantes, num lugar só. Ver METRE-CHANGES.md.
const val ACT_METRE_WATCHDOG = "com.metre.viewer.WATCHDOG"

object MetreCompat {
    // Codificadores de vídeo do aparelho, para o diagnóstico em "Opções avançadas".
    val codecReport = mutableListOf<String>()

    // O codificador por hardware só aguenta metade da tela (ex.: M10 MT6580, H.264 até 720 px):
    // a captura já nasce com metade da resolução, para o codificador ser criado no tamanho certo.
    @Volatile var hwNeedsHalf = false
    @Volatile var codecInfoLoaded = false

    // O Wi-Fi do Android entra em economia de energia entre um pacote e outro: no M10 o ping na
    // mesma rede ia de 2 ms a 1,3 s (o roteador respondia em 0 ms), o que atrasava cliques,
    // congelava a imagem e estourava a conexão direta (1 s de prazo) e caía no relay.
    // Com o serviço no ar, o rádio fica acordado.
    private var wifiLock: WifiManager.WifiLock? = null

    @Suppress("DEPRECATION")
    fun holdWifi(context: Context, hold: Boolean) {
        try {
            if (hold && wifiLock == null) {
                val wm = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                wifiLock = wm.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "metre:wifi").apply {
                    setReferenceCounted(false); acquire()
                }
            } else if (!hold) {
                wifiLock?.let { if (it.isHeld) it.release() }
                wifiLock = null
            }
        } catch (e: Exception) { android.util.Log.e("MetreCompat", "wifi lock: $e") }
    }

    @Suppress("DEPRECATION")
    private fun wifiInfo(context: Context): String = try {
        val wm = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val i = wm.connectionInfo
        "sinal ${i.rssi} dBm, ${i.linkSpeed} Mbps, ${i.frequency} MHz, sem economia: ${wifiLock?.isHeld == true}"
    } catch (e: Exception) { "indisponível ($e)" }

    // O Android 13+ não deixa o app ler o próprio estado (appop de leitura restrita: exige MANAGE_APPOPS).
    // Por isso o diagnóstico não afirma "sim" nem "não"; quem decide é a tela de Acessibilidade.
    fun restrictedSettings(context: Context): String =
        if (Build.VERSION.SDK_INT < 33) "n/a" else "não legível pelo app"

    private fun installSource(context: Context): String = try {
        if (Build.VERSION.SDK_INT >= 30) {
            val i = context.packageManager.getInstallSourceInfo(context.packageName)
            val src = if (Build.VERSION.SDK_INT >= 33) " origem=${i.packageSource}" else ""
            "instalador=${i.installingPackageName} iniciador=${i.initiatingPackageName}$src"
        } else "instalador=${context.packageManager.getInstallerPackageName(context.packageName)}"
    } catch (e: Exception) { "desconhecido ($e)" }

    fun diagnostics(context: Context): String = buildString {
        appendLine("Aparelho: ${Build.MANUFACTURER} ${Build.MODEL} (${Build.HARDWARE}), Android ${Build.VERSION.RELEASE} / API ${Build.VERSION.SDK_INT}")
        appendLine("Processador: ${Build.SUPPORTED_ABIS.joinToString()}, núcleos: ${Runtime.getRuntime().availableProcessors()}")
        appendLine("Captura ativa: ${MainService.isReady}, controle ativo: ${InputService.isOpen}")
        appendLine("Wi-Fi: ${wifiInfo(context)}")
        appendLine("Instalação: ${installSource(context)}; configuração restrita: ${restrictedSettings(context)}")
        appendLine("Codificadores de vídeo:")
        codecReport.distinct().forEach { appendLine("  $it") }
        appendLine()
        appendLine("Log (vídeo e codificação, mais recentes por último):")
        // logs ficam no armazenamento privado do app: <files>/<nome do app>/Logs
        val logs = listOfNotNull(context.getExternalFilesDir(null), context.filesDir)
            .flatMap { it.walkTopDown().maxDepth(4).filter { f -> f.isFile && f.parentFile?.name == "Logs" }.toList() }
            .sortedBy { it.lastModified() }
        val keys = listOf("metre-stats", "metre-h264", "codec", "encoder", "hwcodec", "half_scale", "fps", "Connection closed", "ERROR", "intranet", "relay", "punch")
        logs.takeLast(2).flatMap { f -> try { f.readLines() } catch (e: Exception) { listOf("erro ao ler ${f.name}: $e") } }
            .filter { line -> keys.any { line.contains(it, true) } }
            .takeLast(60)
            .forEach { appendLine(it.take(300)) }
        if (logs.isEmpty()) appendLine("  (nenhum arquivo de log encontrado)")
    }

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
