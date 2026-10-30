import 'dart:async';

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
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class WebAuthnController extends PollingController {
  WebAuthnController({WebAuthnCardClient? client})
    : _client = client ?? WebAuthnCardClient();

  final WebAuthnCardClient _client;
  final _localPinCache = CredentialCache('webauthn');
  final List<WebAuthnItem> webAuthnItems = [];
  FirmwareVersion firmwareVersion = const FirmwareVersion(0, 0, 0);
  FunctionSetVersion functionSetVersion = FunctionSetVersion.v1;
  String? disabledMessage;

  /// Display state from the latest getInfo; refreshed after PIN mutations.
  WebAuthnInfo? _info;

  /// authenticatorConfig (0x0D) always fails on 2.0.x firmware; on 3.x it is
  /// offered only once getInfo reports one of the related options.
  bool get supportsConfig =>
      CanoKey.functionSet(
        functionSetVersion,
      ).contains(Func.webAuthnAuthenticatorConfig) &&
      hasConfigInfo;

  bool get hasConfigInfo =>
      _info?.alwaysUv != null || _info?.minPinLength != null;

  bool? get alwaysUv => _info?.alwaysUv;

  int? get minPinLength => _info?.minPinLength;

  @override
  Logger get log => Logging.logger('WebAuthn:Controller');

  @override
  void onClose() {
    _client.cancelPendingOperations();
    _localPinCache.clear();
    _info = null;
    super.onClose();
  }

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
          for (var credential in await pinToken.enumerateCredentials(
            rp.idHash,
          )) {
            webAuthnItems.add(
              WebAuthnItem(
                rpId: rp.id,
                userName: credential.userName ?? '<unknown>',
                userDisplayName: credential.userDisplayName ?? '<unknown>',
                userId: credential.userId ?? const [],
                credentialId: credential.credentialId,
              ),
            );
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
        Prompts.showPrompt(
          S.current.webauthnPinRequired,
          ContentThemeColor.danger,
        );
        return;
      }

      final session = await _client.beginPinSession(await _refreshInfo());
      try {
        await session.changePin(pinToTry, newPin);
      } on ProtocolException catch (e) {
        _showPinError(e);
        return;
      } catch (error, stack) {
        await _uncertainPinWrite(sn, error, stack);
      } finally {
        session.close();
      }
      await _setPinCache(sn, newPin, savePin);
      final refreshed = await _refreshInfoAfterPinChange();
      Navigator.pop(Get.context!);
      if (refreshed) {
        Prompts.showPrompt(
          S.current.pinChanged,
          ContentThemeColor.success,
          forceSnackBar: true,
        );
      }
    });
  }

  Future<void> delete(List<int> credentialId) async {
    log.t('Call WebAuthnController.delete');
    await SmartCard.process((String sn) async {
      String? pinToTry = _loadPin(sn);
      if (pinToTry == null) {
        Prompts.showPrompt(
          S.current.webauthnPinRequired,
          ContentThemeColor.danger,
        );
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
      Prompts.showPrompt(
        S.of(Get.context!).deleted,
        ContentThemeColor.success,
        forceSnackBar: true,
      );
      webAuthnItems.removeWhere(
        (element) => listEquals(element.credentialId, credentialId),
      );
      update();
    });
  }

  Future<bool> toggleAlwaysUv() async {
    log.t('Call WebAuthnController.toggleAlwaysUv');
    return _runAuthenticatorConfig((token) => token.toggleAlwaysUv());
  }

  Future<bool> setMinPinLength(int newMinPinLength, bool forcePinChange) async {
    log.t('Call WebAuthnController.setMinPinLength');
    return _runAuthenticatorConfig(
      (token) => token.setMinPinLength(
        newMinPinLength,
        forcePinChange: forcePinChange,
      ),
    );
  }

  Future<bool> enableLongTouchForReset() async {
    log.t('Call WebAuthnController.enableLongTouchForReset');
    return _runAuthenticatorConfig((token) => token.enableLongTouchForReset());
  }

  /// Run one authenticatorConfig operation with a fresh cfg (0x20) token;
  /// never reuse the credmgmt (0x04) token.
  Future<bool> _runAuthenticatorConfig(
    Future<void> Function(WebAuthnPinToken token) operation,
  ) async {
    if (!supportsConfig) {
      return false;
    }

    var succeeded = false;
    await SmartCard.process((String sn) async {
      final pinToken = await _getPinToken(
        sn,
        permissions: WebAuthnCardClient.permissionAuthenticatorConfig,
      );
      if (pinToken == null) {
        return;
      }
      try {
        await operation(pinToken);
      } on ProtocolException catch (e) {
        _showConfigError(e);
        return;
      } finally {
        pinToken.close();
      }
      succeeded = true;
      log.i('Successfully changed authenticator config');
      // Re-read getInfo on this lease. refreshData starts a new card use case
      // and must not be nested inside the configuration operation.
      try {
        await _refreshInfo();
      } catch (error, stack) {
        // The write already succeeded: never report it as a failed toggle,
        // which would invite a retry that reverses the device's new state.
        _info = null;
        update();
        log.w(
          'Config saved, but getInfo failed',
          error: error,
          stackTrace: stack,
        );
        Prompts.showPrompt(
          S.current.webauthnConfigRefreshFailed,
          ContentThemeColor.warning,
        );
        return;
      }
      update();
      Prompts.showPrompt(
        S.of(Get.context!).successfullyChanged,
        ContentThemeColor.success,
        forceSnackBar: true,
      );
    });
    return succeeded;
  }

  void _showConfigError(ProtocolException error) {
    if (error.details.statusWord == 0x37) {
      Prompts.showPrompt(
        S.of(Get.context!).webauthnPinPolicyViolation,
        ContentThemeColor.danger,
      );
    } else {
      _showPinError(error);
    }
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

  Future<WebAuthnInfo> _refreshInfo() async => _info = await _client.getInfo();

  Future<WebAuthnPinToken?> _getPinToken(
    String sn, {
    int permissions = WebAuthnCardClient.permissionCredentialManagement,
  }) async {
    final info = await _refreshInfo();

    // We do nothing if the device does not support credMgmt or clientPin
    if (info.credMgmt != true || info.clientPin == null) {
      Prompts.showPrompt(
        S.of(Get.context!).webauthnClientPinNotSupported,
        ContentThemeColor.danger,
      );
      return null;
    }

    // If PIN is not set, ask the user to set PIN first
    if (info.clientPin == false) {
      if (!await _setPin(sn)) {
        return null;
      }
    }

    if (_info == null) return null;
    assert(_info!.clientPin == true);

    if (_info!.forcePinChange == true) {
      return _forceChangePin(sn, permissions: permissions);
    }

    final attemptedPins = <String>{};
    // Try local cache first
    if (_localPinCache.containsKey(sn)) {
      attemptedPins.add(_localPinCache[sn]!);
      final pinToken = await _doGetPinToken(
        _localPinCache[sn]!,
        permissions: permissions,
      );
      if (pinToken != null) {
        return pinToken;
      }
      _localPinCache.remove(sn);
    }

    // Try LocalStorage
    String? pinToTry = LocalStorage.getPinCache(sn, _tag);
    if (pinToTry != null && attemptedPins.add(pinToTry)) {
      final pinToken = await _doGetPinToken(pinToTry, permissions: permissions);
      if (pinToken != null) {
        _localPinCache[sn] = pinToTry;
        return pinToken;
      } else {
        await LocalStorage.setPinCache(sn, _tag, null);
      }
    } else if (pinToTry != null) {
      // This persisted value was already rejected from the local cache.
      await LocalStorage.setPinCache(sn, _tag, null);
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
        try {
          final pinToken = await SmartCard.withInputCard<WebAuthnPinToken>(
            sn,
            () async {
              await _refreshInfo();
              final token = await _doGetPinToken(pin, permissions: permissions);
              if (token == null) return null;
              try {
                await _setPinCache(sn, pin, savePin);
                return token;
              } catch (_) {
                token.close();
                rethrow;
              }
            },
          );
          if (pinToken != null && !completer.isCompleted) {
            completer.complete(pinToken);
            Navigator.pop(Get.context!);
          }
        } catch (error, stack) {
          if (!completer.isCompleted) completer.completeError(error, stack);
          Navigator.pop(Get.context!);
        }
      },
      onCancel: () async {
        SmartCard.nfcState = NfcState.idle;
        if (!completer.isCompleted) completer.complete(null);
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
      confirmPin: true,
      validators: [LengthValidator(min: 4, max: 63)],
      showSaveOption: true,
      onSubmit: (pin, savePin) async {
        try {
          final set = await SmartCard.withInputCard<bool>(sn, () async {
            final session = await _client.beginPinSession(await _refreshInfo());
            try {
              await session.setPin(pin);
            } on ProtocolException catch (error) {
              _showPinError(error);
              return null;
            } catch (error, stack) {
              await _uncertainPinWrite(sn, error, stack);
            } finally {
              session.close();
            }
            await _setPinCache(sn, pin, savePin);
            final refreshed = await _refreshInfoAfterPinChange();
            if (refreshed) {
              Prompts.showPrompt(
                S.current.pinChanged,
                ContentThemeColor.success,
              );
            }
            return true;
          });
          if (set == true && !completer.isCompleted) {
            completer.complete(true);
            Navigator.pop(Get.context!);
          }
        } catch (error, stack) {
          if (!completer.isCompleted) completer.completeError(error, stack);
          Navigator.pop(Get.context!);
        }
      },
      onCancel: () async {
        SmartCard.nfcState = NfcState.idle;
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    return await completer.future;
  }

  Future<WebAuthnPinToken?> _doGetPinToken(
    String pin, {
    int permissions = WebAuthnCardClient.permissionCredentialManagement,
  }) async {
    final session = await _client.beginPinSession(
      _info ?? await _refreshInfo(),
    );
    try {
      return await session.getPinToken(pin, permissions: permissions);
    } on ProtocolException catch (e) {
      _showPinError(e);
      return null;
    } finally {
      session.close();
    }
  }

  Future<WebAuthnPinToken?> _forceChangePin(
    String sn, {
    int permissions = WebAuthnCardClient.permissionCredentialManagement,
  }) async {
    await SmartCard.stopPollingNfc(withInput: true);
    final completer = Completer<WebAuthnPinToken?>();
    Object? terminalError;
    StackTrace? terminalStack;
    await ForcePinChangeDialog.show(
      minPinLength: _info?.minPinLength ?? 4,
      onSubmit: (currentPin, newPin, savePin) async {
        try {
          final changed = await SmartCard.withInputCard<(WebAuthnPinToken?,)>(
            sn,
            () async {
              final session = await _client.beginPinSession(
                await _refreshInfo(),
              );
              try {
                await session.changePin(currentPin, newPin);
              } on ProtocolException catch (error) {
                _showPinError(error);
                return null;
              } catch (error, stack) {
                await _uncertainPinWrite(sn, error, stack);
              } finally {
                session.close();
              }
              // From this point the old PIN is obsolete, even if readback or
              // acquiring the next token fails. Close this dialog on success.
              await _setPinCache(sn, newPin, savePin);
              if (!await _refreshInfoAfterPinChange()) return (null,);
              WebAuthnPinToken? token;
              final acquired = await refreshAfterWrite(() async {
                token = await _doGetPinToken(newPin, permissions: permissions);
              });
              if (acquired && token != null) {
                Prompts.showPrompt(
                  S.current.pinChanged,
                  ContentThemeColor.success,
                );
              }
              return (token,);
            },
          );
          if (changed == null) return false;
          if (!completer.isCompleted) completer.complete(changed.$1);
          return true;
        } catch (error, stack) {
          terminalError = error;
          terminalStack = stack;
          if (!completer.isCompleted) completer.complete(null);
          Navigator.pop(Get.context!);
          return false;
        }
      },
      onCancel: () {
        SmartCard.nfcState = NfcState.idle;
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    if (terminalError != null) {
      Error.throwWithStackTrace(terminalError!, terminalStack!);
    }
    if (!completer.isCompleted) completer.complete(null);
    return completer.future;
  }

  /// CTAP failures keep the raw CTAP status byte in [ProtocolError.statusWord]:
  /// 0x31 PIN_INVALID, 0x32 PIN_BLOCKED, 0x34 PIN_AUTH_BLOCKED and 0x37
  /// PIN_POLICY_VIOLATION select the same prompts the fido2 statuses did.
  void _showPinError(ProtocolException error) {
    switch (error.details.statusWord) {
      case 0x31:
        Prompts.showPrompt(
          S.of(Get.context!).pinIncorrect,
          ContentThemeColor.danger,
        );
      case 0x34:
        Prompts.showPrompt(
          S.of(Get.context!).webauthnPinAuthBlocked,
          ContentThemeColor.danger,
        );
      case 0x32:
        Prompts.showPrompt(
          S.of(Get.context!).webauthnPinBlocked,
          ContentThemeColor.danger,
        );
      case 0x37:
        Prompts.showPrompt(
          S.of(Get.context!).changePinPrompt(_info?.minPinLength ?? 4, 63),
          ContentThemeColor.danger,
        );
      default:
        Prompts.showPrompt(
          S.current.pinVerificationFailed,
          ContentThemeColor.danger,
        );
    }
  }

  Future<Never> _uncertainPinWrite(
    String sn,
    Object error,
    StackTrace stack,
  ) async {
    await _forgetPin(sn);
    log.w(
      'PIN write outcome unknown; cached PIN discarded',
      error: error,
      stackTrace: stack,
    );
    // Input scans may retry a transport failure in a read-only operation.
    // An uncertain PIN write must instead end the prompt and owning use case.
    Error.throwWithStackTrace(
      StateError('PIN write outcome unknown; read the card again'),
      stack,
    );
  }

  Future<void> _forgetPin(String sn) async {
    _localPinCache.remove(sn);
    await LocalStorage.setPinCache(sn, _tag, null);
  }

  Future<void> _setPinCache(String sn, String pin, bool savePin) async {
    // Replace persisted credentials even when the user opts out of saving the
    // new PIN. Otherwise a restart silently brings the obsolete PIN back.
    await _forgetPin(sn);
    if (savePin) await LocalStorage.setPinCache(sn, _tag, pin);
    _localPinCache[sn] = pin;
  }

  Future<bool> _refreshInfoAfterPinChange() async {
    _info = null;
    return refreshAfterWrite(() async {
      await _refreshInfo();
      update();
    });
  }

  final String _tag = 'webauthn';
}
