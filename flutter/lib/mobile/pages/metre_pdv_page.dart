// Metre: tela única do PDV (M10). O cliente só vê o status e, uma única vez, os passos que o
// Android exige confirmar na tela. O resto (servidor, chave, logs, início do serviço) é automático.
// As telas originais continuam em "Opções avançadas" para o técnico. Ver METRE-CHANGES.md.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common.dart';
import '../../common/metre_theme.dart';
import '../../consts.dart';
import '../../models/platform_model.dart';
import '../../models/server_model.dart';
import 'server_page.dart';
import 'settings_page.dart';

const _kAutostartDone = 'metre-autostart-done';

class MetrePdvPage extends StatefulWidget {
  const MetrePdvPage({super.key});

  @override
  State<MetrePdvPage> createState() => _MetrePdvPageState();
}

class _MetrePdvPageState extends State<MetrePdvPage> with WidgetsBindingObserver {
  Timer? _timer;
  bool _keepAlive = true; // até a primeira verificação, não mostra o passo à toa
  bool _autostartScreen = false; // o fabricante tem tela própria de "iniciar automaticamente"
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = periodic_immediate(const Duration(seconds: 3), () async {
      await gFFI.serverModel.fetchID();
      gFFI.invokeMethod("check_service");
    });
    _refresh(autoStart: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // voltando das telas do Android: confere de novo o que já foi liberado
    if (state == AppLifecycleState.resumed) _refresh(autoStart: true);
  }

  Future<void> _refresh({bool autoStart = false}) async {
    final keepAlive = await gFFI.serverModel.metreKeepAliveOk();
    final autostart = bind.mainGetLocalOption(key: _kAutostartDone) != 'Y' &&
        await gFFI.invokeMethod("metre_autostart", "check") == true;
    if (!mounted) return;
    setState(() {
      _keepAlive = keepAlive;
      _autostartScreen = autostart;
    });
    gFFI.invokeMethod("check_service");
    if (autoStart) await gFFI.serverModel.metreAutoStart();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh(autoStart: true);
    }
  }

  Future<void> _grantKeepAlive() async {
    for (final p in [kRequestIgnoreBatteryOptimizations, kSystemAlertWindow]) {
      if (!await AndroidPermissionManager.check(p)) {
        await AndroidPermissionManager.request(p);
      }
    }
  }

  Future<void> _grantScreen() => gFFI.serverModel.startService();

  Future<void> _grantInput() async =>
      AndroidPermissionManager.startAction(kActionAccessibilitySettings);

  Future<void> _openAutostart() async {
    await gFFI.invokeMethod("metre_autostart", "open");
    await bind.mainSetLocalOption(key: _kAutostartDone, value: 'Y');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(builder: (context, model, _) {
        final steps = <_Step>[
          if (!_keepAlive)
            _Step(
                Icons.battery_charging_full,
                'Manter o suporte sempre ligado',
                'Para o suporte continuar disponível com a tela apagada e depois de reiniciar. '
                    'Nas telas seguintes, toque em "Permitir" e ative a chave do MetreViewer.',
                _grantKeepAlive),
          if (!model.mediaOk)
            _Step(
                Icons.screen_share_outlined,
                'Permitir que o técnico veja a tela',
                'Na próxima tela, marque "Não mostrar novamente" e toque em "Iniciar agora". '
                    'Assim isso não é perguntado de novo.',
                _grantScreen),
          if (!model.inputOk)
            _Step(
                Icons.touch_app_outlined,
                'Permitir que o técnico toque na tela',
                'Na próxima tela, toque em "MetreViewer Input" e ative a chave. '
                    'Sem isso o técnico só consegue olhar, sem operar o aparelho.',
                _grantInput),
          if (_autostartScreen)
            _Step(
                Icons.restart_alt,
                'Iniciar junto com o aparelho',
                'Este aparelho tem uma tela própria do fabricante para isso. '
                    'Na próxima tela, ative o MetreViewer.',
                _openAutostart),
        ];
        final inSession = model.clients.any((c) => !c.disconnected);
        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF18191E)
              : const Color(0xFFF5F5F7),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _header(context),
                    const SizedBox(height: 24),
                    _statusCard(context, steps.isEmpty, inSession),
                    const SizedBox(height: 16),
                    _infoCard(context, model),
                    if (steps.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _stepsCard(context, steps),
                    ],
                    if (model.clients.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const ConnectionManager(),
                    ],
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const _AdvancedPage())),
                        child: const Text('Opções avançadas (técnico)',
                            style: TextStyle(color: MetreColors.gray)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _header(BuildContext context) => Row(children: [
        metreLogo(size: 48),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('MetreViewer',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          Text('Suporte remoto Metre',
              style: TextStyle(fontSize: 14, color: MetreColors.gray)),
        ]),
      ]);

  Widget _statusCard(BuildContext context, bool ready, bool inSession) {
    final (IconData icon, Color color, String title, String text) = inSession
        ? (
            Icons.support_agent,
            MetreColors.blue,
            'Atendimento em andamento',
            'Um técnico da Metre está conectado a este aparelho.'
          )
        : ready
            ? (
                Icons.check_circle,
                MetreColors.green,
                'Pronto para receber suporte',
                'Este aparelho está registrado. Você não precisa fazer mais nada.'
              )
            : (
                Icons.info,
                MetreColors.orange,
                'Falta pouco',
                'Faça os passos abaixo uma única vez para liberar o suporte.'
              );
    return MetreCard(
      color: color.withOpacity(0.08),
      child: Row(children: [
        Icon(icon, color: color, size: 44),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 15)),
          ]),
        ),
      ]),
    );
  }

  Widget _infoCard(BuildContext context, ServerModel model) {
    final (String conn, bool connOk) = switch (model.connectStatus) {
      1 => ('Estabelecida', true),
      0 => ('Conectando…', false),
      _ => ('Sem conexão. Verifique a internet.', false),
    };
    Widget row(String label, String value, {bool? ok}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(color: MetreColors.gray))),
            if (ok != null) ...[metreStatusDot(ok), const SizedBox(width: 8)],
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        );
    return MetreCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(children: [
        row('Identificação do aparelho', model.serverId.text),
        const Divider(height: 1),
        row('Serviço', model.isStart ? 'Ativo' : 'Parado', ok: model.isStart),
        const Divider(height: 1),
        row('Conexão com a Metre', conn, ok: connOk),
      ]),
    );
  }

  Widget _stepsCard(BuildContext context, List<_Step> steps) => MetreCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Configuração (só uma vez)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(steps[i].icon, color: MetreColors.orange, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(steps[i].why,
                            style: const TextStyle(color: MetreColors.gray)),
                      ]),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: i == 0 ? MetreColors.orange : null,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14)),
                  onPressed: _busy ? null : () => _run(steps[i].action),
                  child: const Text('Ativar'),
                ),
              ]),
            ),
        ]),
      );
}

class _Step {
  final IconData icon;
  final String title, why;
  final Future<void> Function() action;
  _Step(this.icon, this.title, this.why, this.action);
}

/// Telas originais do app, para o técnico em campo.
class _AdvancedPage extends StatelessWidget {
  const _AdvancedPage();

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Opções avançadas'),
            bottom: const TabBar(
                tabs: [Tab(text: 'Serviço e permissões'), Tab(text: 'Configurações')]),
          ),
          body: TabBarView(children: [ServerPage(), SettingsPage()]),
        ),
      );
}
