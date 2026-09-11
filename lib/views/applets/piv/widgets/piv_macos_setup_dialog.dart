import 'package:canokey_console/controller/applets/piv/piv_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/models/piv_macos_setup.dart';
import 'package:flutter/material.dart';

class PivMacOsSetupDialog extends StatefulWidget {
  const PivMacOsSetupDialog({super.key, required this.controller});
  final PivController controller;

  @override
  State<PivMacOsSetupDialog> createState() => _PivMacOsSetupDialogState();
}

class _PivMacOsSetupDialogState extends State<PivMacOsSetupDialog> {
  final _pin = TextEditingController();
  final _managementKey = TextEditingController();
  PivMacOsSetupPlan? _plan;
  bool _busy = true, _failed = false, _consent = false, _done = false;
  bool _invalid = false;
  final Map<String, bool> _progress = {};

  @override
  void initState() {
    super.initState();
    _inspect();
  }

  @override
  void dispose() {
    _pin.dispose();
    _managementKey.dispose();
    super.dispose();
  }

  Future<void> _inspect() async {
    setState(() {
      _busy = true;
      _failed = false;
      _consent = false;
      _plan = null;
      _progress.clear();
    });
    PivMacOsSetupPlan? plan;
    try {
      plan = await widget.controller.inspectMacOsSetup();
    } catch (_) {
      /* Show retry below. */
    }
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _busy = false;
      _failed = plan == null;
      _done = plan?.complete ?? false;
    });
  }

  Future<void> _configure() async {
    final pin = _pin.text;
    final managementKey = _managementKey.text.trim();
    if (!RegExp(r'^[\x20-\x7E]{6,8}$').hasMatch(pin) ||
        (!widget.controller.pinOnlyMode &&
            (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(managementKey) ||
                managementKey.length != 48))) {
      setState(() => _invalid = true);
      return;
    }
    setState(() {
      _busy = true;
      _invalid = false;
    });
    var success = false;
    try {
      success = await widget.controller.configureMacOsLogin(
        plan: _plan!,
        pin: pin,
        managementKey: managementKey,
        usePinOnly: widget.controller.pinOnlyMode,
        allowReplacement: _consent,
        onProgress: (slot, done) {
          if (mounted) setState(() => _progress[slot] = done);
        },
      );
    } catch (_) {
      /* Preserve completed slots and offer a fresh inspection. */
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = success;
      _failed = !success;
    });
  }

  String _action(S s, PivMacOsSetupAction action) => switch (action) {
    PivMacOsSetupAction.keep => s.pivMacSetupKeep,
    PivMacOsSetupAction.create => s.pivMacSetupCreate,
    PivMacOsSetupAction.issueCertificate => s.pivMacSetupIssue,
    PivMacOsSetupAction.replaceCertificate => s.pivMacSetupReplaceCert,
    PivMacOsSetupAction.replaceKey => s.pivMacSetupReplaceKey,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(s.pivMacSetupTitle),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_done ? s.pivMacSetupDone : s.pivMacSetupIntro),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: LinearProgressIndicator(),
                  ),
                if (_plan != null && !_done) ...[
                  const SizedBox(height: 12),
                  for (final slot in _plan!.slots)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(slot.slotNumber),
                      title: Text(_action(s, slot.action)),
                      subtitle: _progress.containsKey(slot.slotNumber)
                          ? Text(
                              _progress[slot.slotNumber]!
                                  ? s.pivMacSetupFinished
                                  : s.pivMacSetupWorking,
                            )
                          : null,
                    ),
                  if (!_failed) ...[
                    if (_plan!.needsReplacementConsent)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _consent,
                        onChanged: _busy
                            ? null
                            : (value) =>
                                  setState(() => _consent = value ?? false),
                        title: Text(s.pivMacSetupConsent),
                      ),
                    TextField(
                      controller: _pin,
                      enabled: !_busy,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'PIV PIN'),
                    ),
                    if (!widget.controller.pinOnlyMode)
                      TextField(
                        controller: _managementKey,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: s.pivMacSetupManagementKey,
                        ),
                      ),
                    if (_invalid)
                      Text(
                        s.pivMacSetupInvalid,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ],
                if (_failed) Text(s.pivMacSetupError),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(s.close),
          ),
          if (_failed)
            FilledButton(
              onPressed: _busy ? null : _inspect,
              child: Text(s.pivMacSetupInspect),
            )
          else if (!_done)
            FilledButton(
              onPressed:
                  _busy ||
                      _plan == null ||
                      (_plan!.needsReplacementConsent && !_consent)
                  ? null
                  : _configure,
              child: Text(s.pivMacSetupStart),
            ),
        ],
      ),
    );
  }
}
