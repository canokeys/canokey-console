// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(min, max) =>
      "New PIN should be at least ${min} characters long. The maximum length is ${max}.";

  static String m1(name) =>
      "This action will delete the account ${name} from your CanoKey. Make sure 2FA has been disabled on the web service.";

  static String m2(name) =>
      "Do you want to set the account ${name} as the default output when touching? Be careful, the original configuration will be overwritten.";

  static String m3(keyType) => "Change ${keyType} Key\'s Touch Policy";

  static String m4(retries) => "Incorrect PIN. ${retries} retries left.";

  static String m5(min, max) =>
      "New PUK should be at least ${min} characters long. The maximum length is ${max}.";

  static String m6(slot) =>
      "This action will delete the slot ${slot} from your CanoKey. Make sure you have other ways to authenticate.";

  static String m7(applet) =>
      "This operation will RESET all data of ${applet}!";

  static String m8(length) => "Need exact ${length} characters";

  static String m9(name) =>
      "This action will delete the account ${name} from your CanoKey. Make sure you have other ways to log in.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "actions": MessageLookupByLibrary.simpleMessage("Actions"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "androidAlertTitle": MessageLookupByLibrary.simpleMessage(
      "Touch your CanoKey",
    ),
    "androidPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "Tap your CanoKey or insert it into the USB port",
    ),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "CanoKey Console is the console app for CanoKey, an open-source security key.",
    ),
    "appletLocked": MessageLookupByLibrary.simpleMessage(
      "This applet has been locked.",
    ),
    "applets": MessageLookupByLibrary.simpleMessage("Applets"),
    "beforeSourceLink": MessageLookupByLibrary.simpleMessage(
      "Source code available on GitHub: ",
    ),
    "browserNotSupported": MessageLookupByLibrary.simpleMessage(
      "Your browser does not support WebUSB",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "change": MessageLookupByLibrary.simpleMessage("Change"),
    "changePin": MessageLookupByLibrary.simpleMessage("Change PIN"),
    "changePinPrompt": m0,
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "connectFirst": MessageLookupByLibrary.simpleMessage(
      "Please connect your CanoKey first.",
    ),
    "copied": MessageLookupByLibrary.simpleMessage("Copied"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleted": MessageLookupByLibrary.simpleMessage("Successfully deleted"),
    "desktopPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "Insert your CanoKey into the USB port",
    ),
    "desktopPollError": MessageLookupByLibrary.simpleMessage(
      "Error finding CanoKey connected via USB. Please fix the problem and restart this app:",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "homeDirectlySelect": MessageLookupByLibrary.simpleMessage(
      "Select an applet to start",
    ),
    "homePress": MessageLookupByLibrary.simpleMessage("Press"),
    "homeScreenTitle": MessageLookupByLibrary.simpleMessage("CanoKey Console"),
    "homeSelect": MessageLookupByLibrary.simpleMessage("to select an applet"),
    "interrupted": MessageLookupByLibrary.simpleMessage(
      "Communication interrupted. Try to hold the CanoKey until finished.",
    ),
    "iosAlertMessage": MessageLookupByLibrary.simpleMessage(
      "Hold your iPhone near the CanoKey",
    ),
    "iosPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "Tap the refresh button and tap your CanoKey or insert it into the USB port",
    ),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "CanoKey is busy. Replug it, wait for a moment, and retry.",
    ),
    "newPin": MessageLookupByLibrary.simpleMessage("New PIN"),
    "noCard": MessageLookupByLibrary.simpleMessage("CanoKey not found"),
    "noCredential": MessageLookupByLibrary.simpleMessage("No credential"),
    "noMatchingCredential": MessageLookupByLibrary.simpleMessage(
      "No matching credential found",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("Not supported"),
    "notSupportedInNFC": MessageLookupByLibrary.simpleMessage(
      "Not supported in NFC mode",
    ),
    "oathAccount": MessageLookupByLibrary.simpleMessage("Account name"),
    "oathAddAccount": MessageLookupByLibrary.simpleMessage("Add Account"),
    "oathAddByScanning": MessageLookupByLibrary.simpleMessage("Scan QR Code"),
    "oathAddByScreen": MessageLookupByLibrary.simpleMessage(
      "Scan QR Code on Screen",
    ),
    "oathAddManually": MessageLookupByLibrary.simpleMessage("Add Manually"),
    "oathAdded": MessageLookupByLibrary.simpleMessage("Successfully added"),
    "oathAdvancedSettings": MessageLookupByLibrary.simpleMessage(
      "Advanced Settings. Think well before changing them. You could lock yourself out!",
    ),
    "oathAlgorithm": MessageLookupByLibrary.simpleMessage("Algorithm"),
    "oathCode": MessageLookupByLibrary.simpleMessage("Passphrase"),
    "oathCodeChanged": MessageLookupByLibrary.simpleMessage(
      "Passphrase Changed",
    ),
    "oathCopy": MessageLookupByLibrary.simpleMessage("Copy to Clipboard"),
    "oathCounter": MessageLookupByLibrary.simpleMessage("Counter"),
    "oathCounterMustBeNumber": MessageLookupByLibrary.simpleMessage(
      "Not a number",
    ),
    "oathDelete": m1,
    "oathDigits": MessageLookupByLibrary.simpleMessage("Digits"),
    "oathDuplicated": MessageLookupByLibrary.simpleMessage(
      "Duplicated account",
    ),
    "oathInputCode": MessageLookupByLibrary.simpleMessage("Unlock CanoKey"),
    "oathInputCodePrompt": MessageLookupByLibrary.simpleMessage(
      "To prevent unauthorized access, this CanoKey is protected with a passphrase.",
    ),
    "oathInvalidKey": MessageLookupByLibrary.simpleMessage(
      "Invalid secret key",
    ),
    "oathIssuer": MessageLookupByLibrary.simpleMessage("Issuer"),
    "oathNewCode": MessageLookupByLibrary.simpleMessage("New Passphrase"),
    "oathNewCodePrompt": MessageLookupByLibrary.simpleMessage(
      "Enter a new passphrase. Leave it empty to disable current passphrase.",
    ),
    "oathNoQr": MessageLookupByLibrary.simpleMessage("No QR Code detected"),
    "oathPeriod": MessageLookupByLibrary.simpleMessage("Period"),
    "oathRequireTouch": MessageLookupByLibrary.simpleMessage("Require Touch"),
    "oathRequired": MessageLookupByLibrary.simpleMessage("Required"),
    "oathSecret": MessageLookupByLibrary.simpleMessage("Secret key"),
    "oathSetCode": MessageLookupByLibrary.simpleMessage("Set Passphrase"),
    "oathSetDefault": MessageLookupByLibrary.simpleMessage(
      "Set as Touch Output",
    ),
    "oathSetDefaultPrompt": m2,
    "oathSlot": MessageLookupByLibrary.simpleMessage("Slot"),
    "oathTooLong": MessageLookupByLibrary.simpleMessage("Too long"),
    "oathType": MessageLookupByLibrary.simpleMessage("Type"),
    "off": MessageLookupByLibrary.simpleMessage("Off"),
    "oldPin": MessageLookupByLibrary.simpleMessage("Current PIN"),
    "on": MessageLookupByLibrary.simpleMessage("On"),
    "openpgpAuthentication": MessageLookupByLibrary.simpleMessage(
      "Authentication",
    ),
    "openpgpCardHolder": MessageLookupByLibrary.simpleMessage("Card Holder"),
    "openpgpCardInfo": MessageLookupByLibrary.simpleMessage("Card Info"),
    "openpgpChangeAdminPin": MessageLookupByLibrary.simpleMessage(
      "Change Admin PIN",
    ),
    "openpgpChangeInteraction": m3,
    "openpgpChangeTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "Change Touch Cache Time",
    ),
    "openpgpEncryption": MessageLookupByLibrary.simpleMessage("Encryption"),
    "openpgpKeyNone": MessageLookupByLibrary.simpleMessage("[none]"),
    "openpgpKeys": MessageLookupByLibrary.simpleMessage("Keys"),
    "openpgpManufacturer": MessageLookupByLibrary.simpleMessage("Manufacturer"),
    "openpgpPubkeyUrl": MessageLookupByLibrary.simpleMessage("Public Key URL"),
    "openpgpSN": MessageLookupByLibrary.simpleMessage("Serial Number"),
    "openpgpSignature": MessageLookupByLibrary.simpleMessage("Signature"),
    "openpgpUIF": MessageLookupByLibrary.simpleMessage("Touch Policies"),
    "openpgpUifCacheTime": MessageLookupByLibrary.simpleMessage(
      "Touch Cache Time",
    ),
    "openpgpUifCacheTimeChanged": MessageLookupByLibrary.simpleMessage(
      "Touch cache time has been successfully changed.",
    ),
    "openpgpUifChanged": MessageLookupByLibrary.simpleMessage(
      "Touch policy has been successfully changed.",
    ),
    "openpgpUifOff": MessageLookupByLibrary.simpleMessage("Off"),
    "openpgpUifOn": MessageLookupByLibrary.simpleMessage("On"),
    "openpgpUifPermanent": MessageLookupByLibrary.simpleMessage(
      "Permanent (Cannot turn off)",
    ),
    "openpgpVersion": MessageLookupByLibrary.simpleMessage("Version"),
    "other": MessageLookupByLibrary.simpleMessage("Other"),
    "passInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Please input your Setting PIN. The default value is 123456.",
    ),
    "passNotSupported": MessageLookupByLibrary.simpleMessage(
      "Your CanoKey does not support Pass.",
    ),
    "passSlotConfigPrompt": MessageLookupByLibrary.simpleMessage(
      "Please select a slot type to configure. If you want to use HOTP, set it in the HOTP applet.",
    ),
    "passSlotConfigTitle": MessageLookupByLibrary.simpleMessage(
      "Slot Configuration",
    ),
    "passSlotHotp": MessageLookupByLibrary.simpleMessage("HOTP"),
    "passSlotLong": MessageLookupByLibrary.simpleMessage("Slot Long"),
    "passSlotOff": MessageLookupByLibrary.simpleMessage("Off"),
    "passSlotShort": MessageLookupByLibrary.simpleMessage("Slot Short"),
    "passSlotStatic": MessageLookupByLibrary.simpleMessage("Static Password"),
    "passSlotWithEnter": MessageLookupByLibrary.simpleMessage(
      "The output comes with Enter",
    ),
    "passStatus": MessageLookupByLibrary.simpleMessage("Status"),
    "passkey": MessageLookupByLibrary.simpleMessage("Passkey"),
    "pinChanged": MessageLookupByLibrary.simpleMessage(
      "PIN has been successfully changed.",
    ),
    "pinIncorrect": MessageLookupByLibrary.simpleMessage("Incorrect PIN."),
    "pinInvalidLength": MessageLookupByLibrary.simpleMessage("Invalid length"),
    "pinLength": MessageLookupByLibrary.simpleMessage(
      "The provided PIN is too short or too long.",
    ),
    "pinRetries": m4,
    "pivAlgorithm": MessageLookupByLibrary.simpleMessage("Current Algorithm"),
    "pivAuthentication": MessageLookupByLibrary.simpleMessage("Authentication"),
    "pivCardAuthentication": MessageLookupByLibrary.simpleMessage(
      "Card Authentication",
    ),
    "pivCertificate": MessageLookupByLibrary.simpleMessage("Certificate"),
    "pivChangeManagementKey": MessageLookupByLibrary.simpleMessage(
      "Change Management Key",
    ),
    "pivChangeManagementKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "New Management Key should be 24 bytes long. Please save it in a safe place.",
    ),
    "pivChangePUK": MessageLookupByLibrary.simpleMessage("Change PUK"),
    "pivChangePUKPrompt": m5,
    "pivDelete": MessageLookupByLibrary.simpleMessage("Delete"),
    "pivDeleteSlot": m6,
    "pivEmpty": MessageLookupByLibrary.simpleMessage("Empty"),
    "pivExport": MessageLookupByLibrary.simpleMessage("Export"),
    "pivExportCertificate": MessageLookupByLibrary.simpleMessage(
      "Export Certificate",
    ),
    "pivGenerate": MessageLookupByLibrary.simpleMessage("Generate"),
    "pivImport": MessageLookupByLibrary.simpleMessage("Import"),
    "pivKeyManagement": MessageLookupByLibrary.simpleMessage("Key Management"),
    "pivManagementKey": MessageLookupByLibrary.simpleMessage("Management Key"),
    "pivManagementKeyVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "Management Key verification failed",
    ),
    "pivNewManagementKey": MessageLookupByLibrary.simpleMessage(
      "New Management Key",
    ),
    "pivNewPUK": MessageLookupByLibrary.simpleMessage("New PUK"),
    "pivOldManagementKey": MessageLookupByLibrary.simpleMessage(
      "Current Management Key",
    ),
    "pivOldPUK": MessageLookupByLibrary.simpleMessage("Current PUK"),
    "pivOrigin": MessageLookupByLibrary.simpleMessage("Origin"),
    "pivOriginGenerated": MessageLookupByLibrary.simpleMessage("Generated"),
    "pivOriginImported": MessageLookupByLibrary.simpleMessage("Imported"),
    "pivPinManagement": MessageLookupByLibrary.simpleMessage("PIN Management"),
    "pivPinPolicy": MessageLookupByLibrary.simpleMessage("PIN Policy"),
    "pivPinPolicyAlways": MessageLookupByLibrary.simpleMessage("Always"),
    "pivPinPolicyDefault": MessageLookupByLibrary.simpleMessage("Default"),
    "pivPinPolicyNever": MessageLookupByLibrary.simpleMessage("Never"),
    "pivPinPolicyOnce": MessageLookupByLibrary.simpleMessage("Once"),
    "pivRandomManagementKey": MessageLookupByLibrary.simpleMessage("Random"),
    "pivRetired1": MessageLookupByLibrary.simpleMessage("Retired 1"),
    "pivRetired2": MessageLookupByLibrary.simpleMessage("Retired 2"),
    "pivSignature": MessageLookupByLibrary.simpleMessage("Digital Signature"),
    "pivSlots": MessageLookupByLibrary.simpleMessage("Slots"),
    "pivTouchPolicy": MessageLookupByLibrary.simpleMessage("Touch Policy"),
    "pivTouchPolicyAlways": MessageLookupByLibrary.simpleMessage("Always"),
    "pivTouchPolicyCached": MessageLookupByLibrary.simpleMessage(
      "Cached for 15 seconds",
    ),
    "pivTouchPolicyDefault": MessageLookupByLibrary.simpleMessage("Default"),
    "pivTouchPolicyNever": MessageLookupByLibrary.simpleMessage("Never"),
    "pivUseDefaultManagementKey": MessageLookupByLibrary.simpleMessage(
      "Default",
    ),
    "pivVerifyManagementKey": MessageLookupByLibrary.simpleMessage(
      "Verify Management Key",
    ),
    "pollCanceled": MessageLookupByLibrary.simpleMessage(
      "No CanoKey is selected.",
    ),
    "pollCanoKey": MessageLookupByLibrary.simpleMessage(
      "Please read your CanoKey by clicking the refresh button",
    ),
    "readingAlertMessage": MessageLookupByLibrary.simpleMessage(
      "Hold the CanoKey until finished",
    ),
    "reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "savePinOnDevice": MessageLookupByLibrary.simpleMessage(
      "Save the PIN on this device",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "seconds": MessageLookupByLibrary.simpleMessage("seconds"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "settingsChangeLanguage": MessageLookupByLibrary.simpleMessage(
      "Change Language",
    ),
    "settingsChipId": MessageLookupByLibrary.simpleMessage("Chip ID"),
    "settingsClearPinCache": MessageLookupByLibrary.simpleMessage(
      "Clear Saved PINs",
    ),
    "settingsClearPinCachePrompt": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear all saved PINs from this device?",
    ),
    "settingsFirmwareVersion": MessageLookupByLibrary.simpleMessage(
      "Firmware Version",
    ),
    "settingsFixNFC": MessageLookupByLibrary.simpleMessage("Fix NFC"),
    "settingsFixNFCSuccess": MessageLookupByLibrary.simpleMessage(
      "NFC is successfully fixed",
    ),
    "settingsHotp": MessageLookupByLibrary.simpleMessage(
      "Input HOTP when touching",
    ),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("CanoKey Info"),
    "settingsInputPin": MessageLookupByLibrary.simpleMessage(
      "PIN Verification",
    ),
    "settingsInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Please input your admin PIN. The default value is 123456. This PIN is irrelevant to other applets.",
    ),
    "settingsKeyboardWithReturn": MessageLookupByLibrary.simpleMessage(
      "The output of OTP value comes with enter",
    ),
    "settingsLanguage": MessageLookupByLibrary.simpleMessage("Language"),
    "settingsModel": MessageLookupByLibrary.simpleMessage("Model"),
    "settingsNDEF": MessageLookupByLibrary.simpleMessage("NFC Tag Mode (NDEF)"),
    "settingsNDEFReadonly": MessageLookupByLibrary.simpleMessage(
      "NFC Tag Readonly",
    ),
    "settingsOtherSettings": MessageLookupByLibrary.simpleMessage(
      "Other Settings",
    ),
    "settingsResetAll": MessageLookupByLibrary.simpleMessage("Reset CanoKey"),
    "settingsResetAllPrompt": MessageLookupByLibrary.simpleMessage(
      "All data will be erased. Once confirmed, the CanoKey will blink multiple times. Please touch it each time you see a blink until the success prompt appears.",
    ),
    "settingsResetApplet": m7,
    "settingsResetConditionNotSatisfying": MessageLookupByLibrary.simpleMessage(
      "PIN has not been locked yet",
    ),
    "settingsResetNDEF": MessageLookupByLibrary.simpleMessage("Reset NDEF"),
    "settingsResetOATH": MessageLookupByLibrary.simpleMessage(
      "Reset TOTP/HOTP",
    ),
    "settingsResetOpenPGP": MessageLookupByLibrary.simpleMessage(
      "Reset OpenPGP",
    ),
    "settingsResetPIV": MessageLookupByLibrary.simpleMessage("Reset PIV"),
    "settingsResetPass": MessageLookupByLibrary.simpleMessage("Reset Pass"),
    "settingsResetPresenceTestFailed": MessageLookupByLibrary.simpleMessage(
      "You did not touch the pad in time",
    ),
    "settingsResetSuccess": MessageLookupByLibrary.simpleMessage(
      "Successfully reset",
    ),
    "settingsResetWebAuthn": MessageLookupByLibrary.simpleMessage(
      "Reset WebAuthn",
    ),
    "settingsSN": MessageLookupByLibrary.simpleMessage("Serial Number"),
    "settingsStartPage": MessageLookupByLibrary.simpleMessage("Start Page"),
    "settingsWebAuthnSm2Support": MessageLookupByLibrary.simpleMessage(
      "WebAuthn SM2",
    ),
    "settingsWebUSB": MessageLookupByLibrary.simpleMessage(
      "WebUSB prompt when plug-in",
    ),
    "soundCredit": MessageLookupByLibrary.simpleMessage(
      "Summer Xu is the author of NFC interaction sounds.",
    ),
    "successfullyChanged": MessageLookupByLibrary.simpleMessage(
      "Successfully changed",
    ),
    "validationExactLength": m8,
    "validationHexString": MessageLookupByLibrary.simpleMessage(
      "Please input a valid hexadecimal string.",
    ),
    "viewUserId": MessageLookupByLibrary.simpleMessage("View User ID"),
    "warning": MessageLookupByLibrary.simpleMessage("Warning"),
    "webPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "Insert your CanoKey into the USB port and click the refresh button",
    ),
    "webauthnClientPinNotSupported": MessageLookupByLibrary.simpleMessage(
      "This key does not support WebAuthn PIN.",
    ),
    "webauthnDelete": m9,
    "webauthnInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Please input your WebAuthn PIN.",
    ),
    "webauthnInputPinTitle": MessageLookupByLibrary.simpleMessage(
      "Unlock WebAuthn",
    ),
    "webauthnPinAuthBlocked": MessageLookupByLibrary.simpleMessage(
      "PIN authentication is blocked. Please reinsert you CanoKey to retry.",
    ),
    "webauthnPinBlocked": MessageLookupByLibrary.simpleMessage(
      "PIN authentication is blocked. Please reset WebAuthn.",
    ),
    "webauthnSetPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Please set your WebAuthn PIN to enable management of credentials. The length of PIN should be between 4 and 63.",
    ),
    "webauthnSetPinTitle": MessageLookupByLibrary.simpleMessage(
      "Set WebAuthn PIN",
    ),
  };
}
