// Metre: tela inicial do técnico. Só o essencial: ver os PDVs liberados, saber quais estão
// disponíveis, buscar e conectar. Configurações ficam no menu da barra de título. Ver METRE-CHANGES.md.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../common/formatter/id_formatter.dart';
import '../../common/metre_theme.dart';
import '../../common/widgets/login.dart';
import '../../models/peer_model.dart';
import '../../models/platform_model.dart';
import 'connection_page.dart' show OnlineStatusWidget;

class MetreHomePage extends StatefulWidget {
  /// Avisos do app (instalar, atualizar, erro do sistema); vazio quando não há nada.
  final Widget notices;
  const MetreHomePage({super.key, required this.notices});

  @override
  State<MetreHomePage> createState() => _MetreHomePageState();
}

class _MetreHomePageState extends State<MetreHomePage> {
  final _search = TextEditingController();
  String _query = '';
  bool _onlyOnline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    gFFI.groupModel.pull(force: false);
    // o status "disponível" vem do servidor de ID; a lista de PDVs vem da Metre API
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _queryOnline());
    Future.delayed(const Duration(seconds: 1), _queryOnline);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _queryOnline() {
    final ids = gFFI.groupModel.peers.map((p) => p.id).toList();
    if (ids.isNotEmpty) bind.queryOnlines(ids: ids);
  }

  Future<void> _reload() async {
    await gFFI.groupModel.pull(force: true);
    _queryOnline();
  }

  static String _name(Peer p) =>
      p.alias.isNotEmpty ? p.alias : (p.hostname.isNotEmpty ? p.hostname : formatID(p.id));

  static String _customer(Peer p) =>
      p.device_group_name.isNotEmpty ? p.device_group_name : 'Sem cliente';

  List<Peer> _filtered(List<Peer> all) {
    final q = _query.trim().toLowerCase();
    final qId = q.replaceAll(RegExp(r'\s'), '');
    return all.where((p) {
      if (_onlyOnline && !p.online) return false;
      if (q.isEmpty) return true;
      return _name(p).toLowerCase().contains(q) ||
          _customer(p).toLowerCase().contains(q) ||
          (qId.isNotEmpty && p.id.contains(qId));
    }).toList()
      ..sort((a, b) {
        final c = _customer(a).compareTo(_customer(b));
        if (c != 0) return c;
        if (a.online != b.online) return a.online ? -1 : 1;
        return _name(a).compareTo(_name(b));
      });
  }

  /// Enter ou botão Conectar: um ID digitado, ou o único PDV encontrado pela busca.
  String? _target(List<Peer> found) {
    final id = _query.replaceAll(RegExp(r'\s'), '');
    if (RegExp(r'^\d{6,}$').hasMatch(id)) return id;
    if (found.length == 1) return found.first.id;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: dark ? const Color(0xFF18191E) : const Color(0xFFF5F5F7),
      child: Column(children: [
        _topBar(context),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                child: AnimatedBuilder(
                  animation: gFFI.groupModel.peersModel,
                  builder: (context, _) => Obx(() {
                    gFFI.userModel.userName.value; // reconstrói ao entrar/sair
                    final all = gFFI.groupModel.peers.toList();
                    final found = _filtered(all);
                    final target = _target(found);
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Conectar a um PDV',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          const Text(
                              'Busque pelo nome, pelo cliente ou pelo ID e clique em Conectar.',
                              style: TextStyle(color: MetreColors.gray)),
                          const SizedBox(height: 18),
                          _searchRow(target),
                          const SizedBox(height: 14),
                          if (gFFI.userModel.isLogin) _filterRow(all),
                          const SizedBox(height: 8),
                          Expanded(child: _list(context, all, found)),
                          widget.notices,
                        ]);
                  }),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        OnlineStatusWidget(),
      ]),
    );
  }

  Widget _topBar(BuildContext context) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F2026)
              : Colors.white,
          border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(children: [
          metreLogo(size: 34),
          const SizedBox(width: 12),
          const Text('MetreViewer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showThisComputer(context),
            icon: const Icon(Icons.computer_outlined, size: 18),
            label: const Text('Este computador'),
          ),
          const SizedBox(width: 8),
          Obx(() => gFFI.userModel.isLogin
              ? PopupMenuButton<int>(
                  tooltip: '',
                  onSelected: (_) => logOutConfirmDialog(),
                  itemBuilder: (_) =>
                      [const PopupMenuItem(value: 0, child: Text('Sair'))],
                  child: Row(children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: MetreColors.orange,
                      child: Text(
                          gFFI.userModel.displayNameOrUserName
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    Text(gFFI.userModel.displayNameOrUserName),
                    const Icon(Icons.expand_more, size: 18),
                  ]),
                )
              : ElevatedButton(
                  onPressed: () async {
                    if (await loginDialog() == true) _reload();
                  },
                  child: const Text('Entrar')),
          ),
        ]),
      );

  Widget _searchRow(String? target) => Row(children: [
        Expanded(
          child: TextField(
            controller: _search,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Nome do PDV, cliente ou ID',
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: (_) {
              if (target != null) connect(context, target);
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: MetreColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24)),
            onPressed: target == null ? null : () => connect(context, target),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Conectar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ]);

  Widget _filterRow(List<Peer> all) {
    final online = all.where((p) => p.online).length;
    Widget chip(String label, bool selected, bool value) => ChoiceChip(
          label: Text(label),
          selected: selected,
          selectedColor: MetreColors.orange.withOpacity(0.15),
          onSelected: (_) => setState(() => _onlyOnline = value),
        );
    return Row(children: [
      chip('Todos (${all.length})', !_onlyOnline, false),
      const SizedBox(width: 8),
      chip('Disponíveis ($online)', _onlyOnline, true),
      const Spacer(),
      IconButton(
          tooltip: 'Atualizar lista',
          onPressed: _reload,
          icon: const Icon(Icons.refresh)),
    ]);
  }

  Widget _empty(IconData icon, String title, String text, [Widget? action]) =>
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: MetreColors.offline),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MetreColors.gray)),
          if (action != null) ...[const SizedBox(height: 16), action],
        ]),
      );

  Widget _list(BuildContext context, List<Peer> all, List<Peer> found) {
    if (!gFFI.userModel.isLogin) {
      return _empty(
          Icons.lock_outline,
          'Entre com sua conta Metre',
          'Depois de entrar, os PDVs dos seus clientes aparecem aqui.\n'
              'Você também pode digitar o ID de um aparelho acima.',
          ElevatedButton(
              onPressed: () async {
                if (await loginDialog() == true) _reload();
              },
              child: const Text('Entrar')));
    }
    if (all.isEmpty) {
      return gFFI.groupModel.groupLoading.value
          ? const Center(child: CircularProgressIndicator())
          : _empty(Icons.point_of_sale, 'Nenhum PDV liberado para você',
              'Peça ao administrador para liberar os clientes que você atende.');
    }
    if (found.isEmpty) {
      return _empty(Icons.search_off, 'Nenhum PDV encontrado',
          'Confira o nome ou o ID digitado.');
    }
    final children = <Widget>[];
    String? last;
    for (final p in found) {
      final c = _customer(p);
      if (c != last) {
        last = c;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(c.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: MetreColors.gray)),
        ));
      }
      children.add(_row(context, p));
    }
    return ListView(padding: const EdgeInsets.only(bottom: 16), children: children);
  }

  Widget _row(BuildContext context, Peer p) {
    final os = p.platform.isEmpty ? '' : ' · ${p.platform}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onDoubleTap: () => connect(context, p.id),
        child: MetreCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(children: [
            metreStatusDot(p.online, size: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_name(p),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('ID ${formatID(p.id)}$os',
                    style: const TextStyle(fontSize: 13, color: MetreColors.gray)),
              ]),
            ),
            Text(p.online ? 'Disponível' : 'Desligado',
                style: TextStyle(
                    fontSize: 13,
                    color: p.online ? MetreColors.green : MetreColors.gray)),
            const SizedBox(width: 16),
            IconButton(
              tooltip: 'Transferir arquivos',
              onPressed: () => connect(context, p.id, isFileTransfer: true),
              icon: const Icon(Icons.folder_outlined),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: MetreColors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
              onPressed: () => connect(context, p.id),
              child: const Text('Conectar'),
            ),
          ]),
        ),
      ),
    );
  }

  /// ID e senha deste PC, para o raro caso de alguém precisar acessar o computador do técnico.
  void _showThisComputer(BuildContext context) {
    final m = gFFI.serverModel;
    gFFI.dialogManager.show((setState, close, context) {
      Widget field(String label, String value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              SizedBox(
                  width: 120,
                  child: Text(label,
                      style: const TextStyle(color: MetreColors.gray))),
              Expanded(
                  child: SelectableText(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600))),
              IconButton(
                tooltip: 'Copiar',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  showToast(translate('Copied'));
                },
              ),
            ]),
          );
      return CustomAlertDialog(
        title: const Text('Este computador'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Use estes dados só se alguém precisar acessar este computador.',
              style: TextStyle(color: MetreColors.gray)),
          const SizedBox(height: 8),
          field('ID', m.serverId.text),
          field('Senha', m.serverPasswd.text),
        ]),
        actions: [dialogButton('OK', onPressed: close)],
        onSubmit: close,
        onCancel: close,
      );
    });
  }
}
