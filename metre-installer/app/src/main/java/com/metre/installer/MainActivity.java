package com.metre.installer;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.pm.PackageInstaller;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Metre Instalador (prova de conceito).
 *
 * O Android 13+ aplica a "Configuração restrita" (bloqueio da Acessibilidade) a apps instalados a
 * partir de um ARQUIVO (origem "arquivo baixado" / "arquivo local"). Apps instalados por outro app
 * através do PackageInstaller (sessão), como fazem as lojas, não recebem esse bloqueio.
 * Este instalador baixa o MetreViewer e o instala por sessão. Não declara origem falsa: não chama
 * setPackageSource (fica "não especificada").
 */
public class MainActivity extends Activity {
    static final String TARGET = "com.metre.viewer";
    static final String BASE =
            "https://github.com/bruno02034/metreviewer/releases/download/metre-nightly/";

    private TextView status;
    private Button button;
    private boolean waitingPermission = false;
    private final Handler ui = new Handler(Looper.getMainLooper());

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setPadding(64, 64, 64, 64);
        root.setBackgroundColor(Color.WHITE);
        TextView title = new TextView(this);
        title.setText("Suporte Metre");
        title.setTextSize(26);
        title.setTextColor(0xFF0B5CC4);
        title.setGravity(Gravity.CENTER);
        status = new TextView(this);
        status.setTextSize(18);
        status.setTextColor(Color.DKGRAY);
        status.setGravity(Gravity.CENTER);
        status.setPadding(0, 40, 0, 40);
        button = new Button(this);
        button.setTextSize(18);
        root.addView(title);
        root.addView(status);
        root.addView(button);
        setContentView(root);
        button.setOnClickListener(v -> start());
        refresh();
    }

    @Override
    protected void onResume() {
        super.onResume();
        // voltando da tela "Permitir desta fonte": continua sozinho
        if (waitingPermission && canInstall()) {
            waitingPermission = false;
            start();
        } else {
            refresh();
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        int st = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, Integer.MIN_VALUE);
        if (st == PackageInstaller.STATUS_PENDING_USER_ACTION) {
            Intent confirm = intent.getParcelableExtra(Intent.EXTRA_INTENT);
            if (confirm != null) startActivity(confirm);
            return;
        }
        if (st == PackageInstaller.STATUS_SUCCESS) {
            status.setText("MetreViewer instalado. Abrindo...");
            openTarget();
        } else if (st != Integer.MIN_VALUE) {
            String msg = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE);
            status.setText("A instalação não terminou (" + st + (msg != null ? ": " + msg : "") + ").\nToque para tentar de novo.");
            button.setEnabled(true);
        }
    }

    private boolean installed() {
        try {
            getPackageManager().getPackageInfo(TARGET, 0);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private boolean canInstall() {
        return Build.VERSION.SDK_INT < 26 || getPackageManager().canRequestPackageInstalls();
    }

    private void refresh() {
        button.setEnabled(true);
        if (installed()) {
            status.setText("O MetreViewer já está instalado.");
            button.setText("Abrir o MetreViewer");
            button.setOnClickListener(v -> openTarget());
        } else {
            status.setText("Toque no botão para instalar o aplicativo de suporte da Metre.");
            button.setText("Instalar o suporte Metre");
            button.setOnClickListener(v -> start());
        }
    }

    private void start() {
        if (!canInstall()) {
            // o Android exige que o cliente permita que este app instale outro (uma vez)
            waitingPermission = true;
            status.setText("Na próxima tela, ative \"Permitir desta fonte\" e volte.");
            startActivity(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:" + getPackageName())));
            return;
        }
        button.setEnabled(false);
        status.setText("Baixando o MetreViewer...");
        new Thread(this::downloadAndInstall).start();
    }

    private void downloadAndInstall() {
        String abi = Build.SUPPORTED_ABIS.length > 0 ? Build.SUPPORTED_ABIS[0] : "";
        String file = abi.startsWith("arm64") ? "rustdesk-1.5.3-aarch64-signed.apk"
                : "rustdesk-1.5.3-armv7-signed.apk";
        try {
            PackageInstaller pi = getPackageManager().getPackageInstaller();
            PackageInstaller.SessionParams params =
                    new PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL);
            params.setAppPackageName(TARGET);
            int id = pi.createSession(params);
            try (PackageInstaller.Session s = pi.openSession(id)) {
                HttpURLConnection c = (HttpURLConnection) new URL(BASE + file).openConnection();
                c.setInstanceFollowRedirects(true);
                c.setConnectTimeout(20000);
                c.setReadTimeout(60000);
                long total = c.getContentLengthLong();
                try (InputStream in = c.getInputStream();
                     OutputStream out = s.openWrite("metreviewer.apk", 0, total)) {
                    byte[] buf = new byte[256 * 1024];
                    long done = 0;
                    int n;
                    int lastPct = -1;
                    while ((n = in.read(buf)) > 0) {
                        out.write(buf, 0, n);
                        done += n;
                        int pct = total > 0 ? (int) (done * 100 / total) : -1;
                        if (pct != lastPct && pct % 5 == 0) {
                            lastPct = pct;
                            ui.post(() -> status.setText("Baixando o MetreViewer... " + lastPctText(pct)));
                        }
                    }
                    s.fsync(out);
                }
                Intent cb = new Intent(this, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
                int flags = PendingIntent.FLAG_UPDATE_CURRENT
                        | (Build.VERSION.SDK_INT >= 31 ? PendingIntent.FLAG_MUTABLE : 0);
                // o próprio Android devolve o resultado a esta tela (que está aberta durante a instalação)
                PendingIntent pending = PendingIntent.getActivity(this, id, cb, flags);
                ui.post(() -> status.setText("Confirme a instalação na próxima tela."));
                s.commit(pending.getIntentSender());
            }
        } catch (Exception e) {
            ui.post(() -> {
                status.setText("Não foi possível baixar ou instalar: " + e.getMessage()
                        + "\nVerifique a internet e toque para tentar de novo.");
                button.setEnabled(true);
            });
        }
    }

    private static String lastPctText(int pct) {
        return pct >= 0 ? pct + "%" : "";
    }

    private void openTarget() {
        Intent i = getPackageManager().getLaunchIntentForPackage(TARGET);
        if (i != null) startActivity(i);
    }
}
