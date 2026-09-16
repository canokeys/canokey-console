import 'dart:async';

import 'package:canokey_console/controller/base/admin.dart';
import 'package:canokey_console/controller/base/polling_controller.dart';
import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/theme/admin_theme.dart';
import 'package:canokey_console/helper/utils/applet_switches.dart';
import 'package:canokey_console/helper/utils/logging.dart';
import 'package:canokey_console/helper/utils/prompts.dart';
import 'package:canokey_console/helper/utils/protocol_operation.dart';
import 'package:canokey_console/helper/utils/smartcard.dart';
import 'package:canokey_console/helper/utils/webauthn_card.dart';
import 'package:canokey_console/helper/widgets/input_pin_dialog.dart';
import 'package:canokey_console/helper/widgets/validators.dart';
import 'package:canokey_console/models/canokey.dart';
import 'package:canokey_console/models/webauthn.dart';
import 'package:canokey_console/views/applets/webauthn/dialogs/force_pin_change_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class WebAuthnController extends PollingController with AdminApplet {
  final WebAuthnCardClient _client = WebAuthnCardClient();
  final _localPinCache = CredentialCache('webauthn');
  final List<WebAuthnItem> webAuthnItems = [];
  FirmwareVersion firmwareVersion = const FirmwareVersion(0, 0, 0);
  FunctionSetVersion functionSetVersion = FunctionSetVersion.v1;
  String? disabledMessage;

  /// Display state from the latest getInfo; refreshed after PIN mutations.
  WebAuthnInfo? _info;

  bool get supportsSm2Settings =>
      CanoKey.functionSet(functionSetVersion).contains(Func.webAuthnSm2Support);

  @override
  Logger get log => Logging.logger('WebAuthn:Controller');

  @override
  Future<void> doRefreshData() async {
    log.t('Call WebAuthnController.doRefreshData');
    await SmartCard.process((String sn) async {
      final switchStatus = await AppletSwitches.readStatus();
      firmwareVersion = switchStatus.firmwareVersion;
      functionSetVersion = switchStatus.functionSetVersion;
      update();
      if (!switchStatus.webAuthnEnabled) {
        disabledMessage = AppletSwitches.disabledMessage('WebAuthn');
        polled = false;
        webAuthnItems.clear();
        update();
        return;
      }
      disabledMessage = null;

      WebAuthnPinToken? pinToken = await _getPinToken(sn);
      if (pinToken == null) {
        return;
      }

      webAuthnItems.clear();

      try {
        for (var rp in await pinToken.enumerateRps()) {
          for (var credential
              in await pinToken.enumerateCredentials(rp.idHash)) {
            webAuthnItems.add(WebAuthnItem(
              rpId: rp.id,
              userName: credential.userName ?? '<unknown>',
              userDisplayName: credential.userDisplayName ?? '<unknown>',
              userId: credential.userId ?? const [],
              credentialId: credential.credentialId,
            ));
          }
        }
      } finally {
        pinToken.close();
      }

      polled = true;
      update();
    });
  }

  Future<void> changePin(String newPin, bool savePin) async {
    log.t('Call WebAuthnController.changePin');
    await SmartCard.process((String sn) async {
      String? pinToTry = _loadPin(sn);
      if (pinToTry == null) {
        Prompts.showPrompt(S.current.webauthnPinRequired, ContentThemeColor.danger);
        return;
      }

      final session = await _client.beginPinSession(await _refreshInfo());
      try {
        await session.changePin(pinToTry, newPin);
      } on ProtocolException catch (e) {
        _showPinError(e);
        return;
      } finally {
        session.close();
      }
      await _refreshInfo();
      await _setPinCache(sn, newPin, savePin);
      log.i('Successfully changed PIN');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(
          S.of(Get.context!).pinChanged, ContentThemeColor.success,
          forceSnackBar: true);
    });
  }

  Future<WebAuthnSm2Config?> readSm2Config() async {
    log.t('Call WebAuthnController.readSm2Config');
    if (!supportsSm2Settings) {
      return null;
    }

    WebAuthnSm2Config? config;
    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }
      config = await adminCardClient.readSm2Config(pin: adminPinForCurrentLease);
    });
    return config;
  }

  Future<void> changeSm2Config(bool enabled, int curveId, int algoId) async {
    log.t('Call WebAuthnController.changeSm2Config');
    if (!supportsSm2Settings) {
      Prompts.showPrompt(
          S.of(Get.context!).notSupported, ContentThemeColor.warning);
      return;
    }

    await SmartCard.process((String sn) async {
      if (!await authenticate(sn)) {
        return;
      }
      await adminCardClient.writeSm2Config(
        pin: adminPinForCurrentLease,
        enabled: enabled,
        curveId: curveId,
        algoId: algoId,
      );
      log.i('Successfully changed WebAuthn SM2 config');
      Navigator.pop(Get.context!);
      Prompts.showPrompt(
          S.of(Get.context!).successfullyChanged, ContentThemeColor.success,
          forceSnackBar: true);
    });
  }

  Future<void> delete(List<int> credentialId) async {
    log.t('Call WebAuthnController.delete');
    await SmartCard.process((String sn) async {
      String? pinToTry = _loadPin(sn);
      if (pinToTry == null) {
        Prompts.showPrompt(S.current.webauthnPinRequired, ContentThemeColor.danger);
        return;
      }

      final pinToken = await _doGetPinToken(pinToTry);
      if (pinToken == null) {
        return;
      }
      try {
        await pinToken.deleteCredential(credentialId);
      } finally {
        pinToken.close();
      }
      log.i('Successfully deleted credential');

      Navigator.pop(Get.context!);
      Prompts.showPrompt(S.of(Get.context!).delete, ContentThemeColor.success,
          forceSnackBar: true);
      webAuthnItems.removeWhere(
          (element) => listEquals(element.credentialId, credentialId));
      update();
    });
  }

  String? _loadPin(String sn) {
    // Try local cache first
    if (_localPinCache.containsKey(sn)) {
      return _localPinCache[sn]!;
    }

    // Try local storage
    final pin = LocalStorage.getPinCache(sn, _tag);
    if (pin != null) {
      _localPinCache[sn] = pin;
      return pin;
    }

    return null;
  }

  Future<WebAuthnInfo> _refreshInfo() async =>
      _info = await _client.getInfo();

  Future<WebAuthnPinToken?> _getPinToken(String sn) async {
    final info = await _refreshInfo();

    // We do nothing if the device does not support credMgmt or clientPin
    if (info.credMgmt != true || info.clientPin == null) {
      Prompts.showPrompt(S.of(Get.context!).webauthnClientPinNotSupported,
          ContentThemeColor.danger);
      return null;
    }

    // If PIN is not set, ask the user to set PIN first
    if (info.clientPin == false) {
      if (!await _setPin(sn)) {
        return null;
      }
    }

    assert(_info!.clientPin == true);

    if (_info!.forcePinChange == true) {
      return _forceChangePin(sn);
    }

    // Try local cache first
    if (_localPinCache.containsKey(sn)) {
      final pinToken = await _doGetPinToken(_localPinCache[sn]!);
      if (pinToken != null) {
        return pinToken;
      }
      _localPinCache.remove(sn);
    }

    // Try LocalStorage
    String? pinToTry = LocalStorage.getPinCache(sn, _tag);
    if (pinToTry != null) {
      final pinToken = await _doGetPinToken(pinToTry);
      if (pinToken != null) {
        _localPinCache[sn] = pinToTry;
        return pinToken;
      } else {
        await LocalStorage.setPinCache(sn, _tag, null);
      }
    }

    // Finally, prompt user
    // When using NFC, we need to finish NFC before showing the dialog
    await SmartCard.stopPollingNfc(withInput: true);
    final completer = Completer<WebAuthnPinToken?>();
    InputPinDialog.show(
      title: S.of(Get.context!).webauthnInputPinTitle,
      label: 'PIN',
      prompt: S.of(Get.context!).webauthnInputPinPrompt,
      validators: [LengthValidator(min: 4, max: 63)],
      showSaveOption: true,
      onSubmit: (pin, savePin) async {
        // When using NFC, we need to poll NFC again
        SmartCard.nfcState = NfcState.processWithInput;
        if (!await SmartCard.pollNfcOrWebUsb()) {
          Prompts.stopPromptAndroidPolling();
          Prompts.showPrompt(
              S.of(Get.context!).noCard, ContentThemeColor.warning,
              level: 'W');
          return; // timeout, do not close the dialog
        }
        Prompts.stopPromptAndroidPolling();
        WebAuthnPinToken? pinToken;
        try {
          pinToken = await _doGetPinToken(pin);
        } on PlatformException catch (e) {
          await SmartCard.stopPollingNfc(withInput: true);
          log.e('_doGetPinToken failed', error: e);
          if (e.code == '500') {
            Prompts.showPrompt(
                S.of(Get.context!).interrupted, ContentThemeColor.danger);
          }
        }
        if (pinToken != null) {
          log.t('PIN verified');
          await _setPinCache(sn, pin, savePin);
          completer.complete(pinToken);
          // Since PIN has been cached, if error happens, we don't need to re-prompt
          SmartCard.nfcState = NfcState.processWithoutInput;
          // Close the dialog
          Navigator.pop(Get.context!);
        }
      },
      onCancel: () async {
        SmartCard.nfcState = NfcState.idle;
        completer.complete(null);
      },
    );
    return await completer.future;
  }

  Future<bool> _setPin(String sn) async {
    // When using NFC, we need to stop polling before showing the dialog
    await SmartCard.stopPollingNfc(withInput: true);
    final completer = Completer<bool>();
    InputPinDialog.show(
      title: S.of(Get.context!).webauthnSetPinTitle,
      label: 'PIN',
      prompt: S.of(Get.context!).webauthnSetPinPrompt,
      validators: [LengthValidator(min: 4, max: 63)],
      showSaveOption: true,
      onSubmit: (pin, savePin) async {
        // When using NFC, we need to poll NFC again
        SmartCard.nfcState = NfcState.processWithInput;
        if (!await SmartCard.pollNfcOrWebUsb()) {
          Prompts.stopPromptAndroidPolling();
          Prompts.showPrompt(
              S.of(Get.context!).noCard, ContentThemeColor.warning,
              level: 'W');
          return; // timeout, do not close the dialog
        }
        Prompts.stopPromptAndroidPolling();
        try {
          final session =
              await _client.beginPinSession(_info ?? await _refreshInfo());
          try {
            await session.setPin(pin);
          } finally {
            session.close();
          }
          // Refresh getInfo so later PIN-token operations see the
          // authenticator's new clientPin state.
          await _refreshInfo();
          log.i('setPin success');
        } on PlatformException catch (e) {
          await SmartCard.stopPollingNfc(withInput: true);
          log.e('setPin failed', error: e);
          if (e.code == '500') {
            Prompts.showPrompt(
                S.of(Get.context!).interrupted, ContentThemeColor.danger);
          }
          return;
        } catch (e, s) {
          await SmartCard.stopPollingNfc(withInput: true);
          log.e('setPin failed', error: e, stackTrace: s);
          Prompts.showPrompt(S.current.webauthnSetPinFailed, ContentThemeColor.danger);
          return;
        }
        await _setPinCache(sn, pin, savePin);

        // PIN set, close the dialog and prompt the user
        Navigator.pop(Get.context!);
        Prompts.showPrompt(
            S.of(Get.context!).pinChanged, ContentThemeColor.success);
        // Since PIN has been cached, if error happens, we don't need to re-prompt
        SmartCard.nfcState = NfcState.processWithoutInput;
        completer.complete(true);
      },
      onCancel: () async {
        SmartCard.nfcState = NfcState.idle;
        completer.complete(false);
      },
    );
    return await completer.future;
  }

  Future<WebAuthnPinToken?> _doGetPinToken(String pin) async {
    final session =
        await _client.beginPinSession(_info ?? await _refreshInfo());
    try {
      return await session.getPinToken(pin);
    } on ProtocolException catch (e) {
      _showPinError(e);
      return null;
    } finally {
      session.close();
    }
  }

  Future<WebAuthnPinToken?> _forceChangePin(String sn) async {
    await SmartCard.stopPollingNfc(withInput: true);
    final completer = Completer<WebAuthnPinToken?>();
    await ForcePinChangeDialog.show(
      minPinLength: _info?.minPinLength ?? 4,
      onSubmit: (currentPin, newPin, savePin) async {
        SmartCard.nfcState = NfcState.processWithInput;
        if (!await SmartCard.pollNfcOrWebUsb()) {
          Prompts.stopPromptAndroidPolling();
          Prompts.showPrompt(
              S.of(Get.context!).noCard, ContentThemeColor.warning,
              level: 'W');
          return false;
        }
        Prompts.stopPromptAndroidPolling();
        try {
          final session = await _client.beginPinSession(_info!);
          try {
            await session.changePin(currentPin, newPin);
          } finally {
            session.close();
          }
          await _refreshInfo();
          final pinToken = await _doGetPinToken(newPin);
          if (pinToken == null) {
            await SmartCard.stopPollingNfc(withInput: true);
            return false;
          }
          await _setPinCache(sn, newPin, savePin);
          SmartCard.nfcState = NfcState.processWithoutInput;
          if (!completer.isCompleted) {
            completer.complete(pinToken);
          }
          Prompts.showPrompt(
              S.of(Get.context!).pinChanged, ContentThemeColor.success);
          return true;
        } on ProtocolException catch (e) {
          await SmartCard.stopPollingNfc(withInput: true);
          _showPinError(e);
          return false;
        } on PlatformException catch (e) {
          await SmartCard.stopPollingNfc(withInput: true);
          log.e('force PIN change failed', error: e);
          if (e.code == '500') {
            Prompts.showPrompt(
                S.of(Get.context!).interrupted, ContentThemeColor.danger);
          } else {
            Prompts.showPrompt(S.current.webauthnChangePinFailed, ContentThemeColor.danger);
          }
          return false;
        } catch (e, s) {
          await SmartCard.stopPollingNfc(withInput: true);
          log.e('force PIN change failed', error: e, stackTrace: s);
          Prompts.showPrompt(S.current.webauthnChangePinFailed, ContentThemeColor.danger);
          return false;
        }
      },
      onCancel: () {
        SmartCard.nfcState = NfcState.idle;
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );
    if (!completer.isCompleted) {
      completer.complete(null);
    }
    return completer.future;
  }

  /// CTAP failures keep the raw CTAP status byte in [ProtocolError.statusWord]:
  /// 0x31 PIN_INVALID, 0x32 PIN_BLOCKED, 0x34 PIN_AUTH_BLOCKED and 0x37
  /// PIN_POLICY_VIOLATION select the same prompts the fido2 statuses did.
  void _showPinError(ProtocolException error) {
    switch (error.details.statusWord) {
      case 0x31:
        Prompts.showPrompt(
            S.of(Get.context!).pinIncorrect, ContentThemeColor.danger);
      case 0x34:
        Prompts.showPrompt(
            S.of(Get.context!).webauthnPinAuthBlocked, ContentThemeColor.danger);
      case 0x32:
        Prompts.showPrompt(
            S.of(Get.context!).webauthnPinBlocked, ContentThemeColor.danger);
      case 0x37:
        Prompts.showPrompt(
            S.of(Get.context!).changePinPrompt(_info?.minPinLength ?? 4, 63),
            ContentThemeColor.danger);
      default:
        Prompts.showPrompt(S.current.pinVerificationFailed, ContentThemeColor.danger);
    }
  }

  Future<void> _setPinCache(
      String sn, String pin, bool cachedInLocalStorage) async {
    _localPinCache[sn] = pin;
    if (cachedInLocalStorage) {
      await LocalStorage.setPinCache(sn, _tag, pin);
    }
  }

  final String _tag = 'webauthn';
}
