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

  static String m0(applet) =>
      "${applet} is disabled. Enable it in Settings first.";

  static String m1(min, max) =>
      "New PIN should be at least ${min} characters long. The maximum length is ${max}.";

  static String m2(error) => "Save failed: ${error}";

  static String m3(used, total) => "${used} of ${total} bytes";

  static String m4(error) => "The ndef library rejected this record: ${error}";

  static String m5(name) =>
      "This action will delete the account ${name} from your CanoKey. Make sure 2FA has been disabled on the web service.";

  static String m6(name) =>
      "Do you want to set the account ${name} as the default output when touching? Be careful, the original configuration will be overwritten.";

  static String m7(keyType) => "Change ${keyType} Key\'s Touch Policy";

  static String m8(remaining) => "Retries: ${remaining}";

  static String m9(seconds) => "${seconds} sec";

  static String m10(retries) => "Incorrect PIN. ${retries} retries left.";

  static String m11(algorithm) => "Algorithm: ${algorithm}";

  static String m12(slot) =>
      "A self-signed certificate was written to slot ${slot}.";

  static String m13(min, max) =>
      "New PUK should be at least ${min} characters long. The maximum length is ${max}.";

  static String m14(slot) => "Clear Slot ${slot}";

  static String m15(slot) =>
      "This action will delete the slot ${slot} from your CanoKey. Make sure you have other ways to authenticate.";

  static String m16(algorithm) => "Generating a ${algorithm} key";

  static String m17(sourceSlot) => "Move Key from ${sourceSlot}";

  static String m18(action, slot) =>
      "${action} will replace the private key in slot ${slot}. Existing authentication or signing that depends on this key may stop working.";

  static String m19(policy) => "PIN: ${policy}";

  static String m20(index) => "Retired ${index}";

  static String m21(remaining, total) => "Retries: ${remaining}/${total}";

  static String m22(policy) => "Touch: ${policy}";

  static String m23(layout) => "Current: ${layout}";

  static String m24(applet) =>
      "This operation will RESET all data of ${applet}!";

  static String m25(min) => "At least ${min} characters";

  static String m26(max) => "At most ${max} characters";

  static String m27(length) => "Need exact ${length} characters";

  static String m28(name) =>
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
    "appletDisabled": m0,
    "appletLocked": MessageLookupByLibrary.simpleMessage(
      "This applet has been locked.",
    ),
    "applets": MessageLookupByLibrary.simpleMessage("Applets"),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "beforeSourceLink": MessageLookupByLibrary.simpleMessage(
      "Source code available on GitHub: ",
    ),
    "browserNotSupported": MessageLookupByLibrary.simpleMessage(
      "Your browser does not support WebUSB",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "change": MessageLookupByLibrary.simpleMessage("Change"),
    "changePin": MessageLookupByLibrary.simpleMessage("Change PIN"),
    "changePinPrompt": m1,
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "connectFirst": MessageLookupByLibrary.simpleMessage(
      "Please connect your CanoKey first.",
    ),
    "copied": MessageLookupByLibrary.simpleMessage("Copied"),
    "copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleted": MessageLookupByLibrary.simpleMessage("Successfully deleted"),
    "desktopPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "Insert your CanoKey into the USB port",
    ),
    "desktopPollError": MessageLookupByLibrary.simpleMessage(
      "Error finding CanoKey connected via USB. Please fix the problem and restart this app:",
    ),
    "disable": MessageLookupByLibrary.simpleMessage("Disable"),
    "disableSound": MessageLookupByLibrary.simpleMessage("Sound disabled"),
    "enable": MessageLookupByLibrary.simpleMessage("Enable"),
    "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
    "fileSaveFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to save file",
    ),
    "fileSaveFailedWithError": m2,
    "fileSaved": MessageLookupByLibrary.simpleMessage("Saved"),
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
      "Pull down or tap refresh, then hold your iPhone near your CanoKey, or insert it into the USB port",
    ),
    "ndefAbsoluteUri": MessageLookupByLibrary.simpleMessage("Absolute URI"),
    "ndefAddRecord": MessageLookupByLibrary.simpleMessage("Add record"),
    "ndefAndroidApplication": MessageLookupByLibrary.simpleMessage("AAR"),
    "ndefAndroidPackage": MessageLookupByLibrary.simpleMessage(
      "Android package name",
    ),
    "ndefBluetoothAddressType": MessageLookupByLibrary.simpleMessage(
      "Address type",
    ),
    "ndefBluetoothClassic": MessageLookupByLibrary.simpleMessage(
      "Bluetooth Classic",
    ),
    "ndefBluetoothLowEnergy": MessageLookupByLibrary.simpleMessage(
      "Bluetooth Low Energy",
    ),
    "ndefBluetoothPublicAddress": MessageLookupByLibrary.simpleMessage(
      "Public",
    ),
    "ndefBluetoothRandomAddress": MessageLookupByLibrary.simpleMessage(
      "Random",
    ),
    "ndefBytesUsed": m3,
    "ndefCapacity": MessageLookupByLibrary.simpleMessage("Capacity"),
    "ndefCapacityExceeded": MessageLookupByLibrary.simpleMessage(
      "The message exceeds the NDEF capacity.",
    ),
    "ndefContact": MessageLookupByLibrary.simpleMessage("Contact"),
    "ndefContactEmail": MessageLookupByLibrary.simpleMessage(
      "Email (optional)",
    ),
    "ndefContactName": MessageLookupByLibrary.simpleMessage("Name"),
    "ndefContactOrganization": MessageLookupByLibrary.simpleMessage(
      "Organization (optional)",
    ),
    "ndefCustom": MessageLookupByLibrary.simpleMessage("Custom record"),
    "ndefDeviceInformation": MessageLookupByLibrary.simpleMessage(
      "Device Information",
    ),
    "ndefDeviceModel": MessageLookupByLibrary.simpleMessage("Model"),
    "ndefDeviceName": MessageLookupByLibrary.simpleMessage(
      "Device name (optional)",
    ),
    "ndefDeviceUniqueName": MessageLookupByLibrary.simpleMessage(
      "Unique name (optional)",
    ),
    "ndefDeviceVendor": MessageLookupByLibrary.simpleMessage("Vendor"),
    "ndefDeviceVersion": MessageLookupByLibrary.simpleMessage(
      "Version (optional)",
    ),
    "ndefEditRecord": MessageLookupByLibrary.simpleMessage("Edit record"),
    "ndefEncoding": MessageLookupByLibrary.simpleMessage("Text encoding"),
    "ndefExternal": MessageLookupByLibrary.simpleMessage("External type"),
    "ndefExternalType": MessageLookupByLibrary.simpleMessage(
      "External type name",
    ),
    "ndefHandover": MessageLookupByLibrary.simpleMessage("Connection Handover"),
    "ndefHandoverType": MessageLookupByLibrary.simpleMessage(
      "Handover record type",
    ),
    "ndefInvalidEmail": MessageLookupByLibrary.simpleMessage(
      "Enter a valid email address.",
    ),
    "ndefInvalidExternalType": MessageLookupByLibrary.simpleMessage(
      "Enter a lowercase external type, such as example.com:record.",
    ),
    "ndefInvalidLanguage": MessageLookupByLibrary.simpleMessage(
      "Enter a valid language code, such as en or zh-Hans.",
    ),
    "ndefInvalidMacAddress": MessageLookupByLibrary.simpleMessage(
      "Enter a MAC address such as AA:BB:CC:DD:EE:FF.",
    ),
    "ndefInvalidMessage": MessageLookupByLibrary.simpleMessage(
      "The stored message is not valid NDEF data. Reset NDEF in Settings before editing it.",
    ),
    "ndefInvalidMimeType": MessageLookupByLibrary.simpleMessage(
      "Enter a valid MIME type, such as text/plain.",
    ),
    "ndefInvalidPackageName": MessageLookupByLibrary.simpleMessage(
      "Enter a valid Android package name, such as com.example.app.",
    ),
    "ndefInvalidPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "Enter a valid phone number.",
    ),
    "ndefInvalidRecord": m4,
    "ndefInvalidUri": MessageLookupByLibrary.simpleMessage(
      "Enter a URI with a scheme, such as https:// or mailto:.",
    ),
    "ndefInvalidUuid": MessageLookupByLibrary.simpleMessage(
      "Enter a UUID in canonical form.",
    ),
    "ndefLanguage": MessageLookupByLibrary.simpleMessage("Language code"),
    "ndefMacAddress": MessageLookupByLibrary.simpleMessage("MAC address"),
    "ndefMime": MessageLookupByLibrary.simpleMessage("MIME"),
    "ndefMimeType": MessageLookupByLibrary.simpleMessage("MIME type"),
    "ndefMoveDown": MessageLookupByLibrary.simpleMessage("Move down"),
    "ndefMoveUp": MessageLookupByLibrary.simpleMessage("Move up"),
    "ndefNoRecords": MessageLookupByLibrary.simpleMessage("No NDEF records"),
    "ndefNoRecordsDescription": MessageLookupByLibrary.simpleMessage(
      "Add a URI or text record to make the tag discoverable.",
    ),
    "ndefOptionalHex": MessageLookupByLibrary.simpleMessage(
      "Optional hexadecimal bytes",
    ),
    "ndefOther": MessageLookupByLibrary.simpleMessage("Other"),
    "ndefPayload": MessageLookupByLibrary.simpleMessage("Payload"),
    "ndefPayloadConversionFailed": MessageLookupByLibrary.simpleMessage(
      "The payload cannot be converted between UTF-8 text and hexadecimal bytes.",
    ),
    "ndefPayloadEncoding": MessageLookupByLibrary.simpleMessage(
      "Payload encoding",
    ),
    "ndefPayloadHex": MessageLookupByLibrary.simpleMessage("Hex"),
    "ndefPayloadText": MessageLookupByLibrary.simpleMessage("Text"),
    "ndefPhone": MessageLookupByLibrary.simpleMessage("Phone"),
    "ndefPhoneNumber": MessageLookupByLibrary.simpleMessage("Phone number"),
    "ndefReadOnly": MessageLookupByLibrary.simpleMessage(
      "The NDEF tag is read-only.",
    ),
    "ndefReadOnlyDescription": MessageLookupByLibrary.simpleMessage(
      "Writing is disabled. Turn off NFC Tag Readonly in Settings to edit these records.",
    ),
    "ndefReadOnlyStatus": MessageLookupByLibrary.simpleMessage("Read-only"),
    "ndefRecordId": MessageLookupByLibrary.simpleMessage(
      "Record ID (optional, hex)",
    ),
    "ndefRecordType": MessageLookupByLibrary.simpleMessage("Record type"),
    "ndefRecords": MessageLookupByLibrary.simpleMessage("Records"),
    "ndefRequiredField": MessageLookupByLibrary.simpleMessage(
      "This field is required.",
    ),
    "ndefSaveToKey": MessageLookupByLibrary.simpleMessage("Save to CanoKey"),
    "ndefSaved": MessageLookupByLibrary.simpleMessage("NDEF records saved"),
    "ndefSignature": MessageLookupByLibrary.simpleMessage("Signature"),
    "ndefSmartPoster": MessageLookupByLibrary.simpleMessage("Smart Poster"),
    "ndefSmartPosterAction": MessageLookupByLibrary.simpleMessage(
      "Suggested action",
    ),
    "ndefSmartPosterActionEdit": MessageLookupByLibrary.simpleMessage("Edit"),
    "ndefSmartPosterActionOpen": MessageLookupByLibrary.simpleMessage("Open"),
    "ndefSmartPosterActionSave": MessageLookupByLibrary.simpleMessage("Save"),
    "ndefSmartPosterTitle": MessageLookupByLibrary.simpleMessage(
      "Title (optional)",
    ),
    "ndefTagContent": MessageLookupByLibrary.simpleMessage("NFC tag content"),
    "ndefTagContentDescription": MessageLookupByLibrary.simpleMessage(
      "Configure the records shared when another device scans this CanoKey.",
    ),
    "ndefText": MessageLookupByLibrary.simpleMessage("Text"),
    "ndefTextValue": MessageLookupByLibrary.simpleMessage("Text content"),
    "ndefTnfAbsoluteUri": MessageLookupByLibrary.simpleMessage("Absolute URI"),
    "ndefTnfEmpty": MessageLookupByLibrary.simpleMessage("Empty"),
    "ndefTnfExternal": MessageLookupByLibrary.simpleMessage(
      "NFC Forum external",
    ),
    "ndefTnfMedia": MessageLookupByLibrary.simpleMessage("Media (MIME)"),
    "ndefTnfRequiresEmptyType": MessageLookupByLibrary.simpleMessage(
      "This TNF requires an empty type name.",
    ),
    "ndefTnfUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "ndefTnfWellKnown": MessageLookupByLibrary.simpleMessage(
      "NFC Forum well-known",
    ),
    "ndefTypeName": MessageLookupByLibrary.simpleMessage("Type name"),
    "ndefUnsavedChanges": MessageLookupByLibrary.simpleMessage(
      "Unsaved changes",
    ),
    "ndefUri": MessageLookupByLibrary.simpleMessage("URI"),
    "ndefUriValue": MessageLookupByLibrary.simpleMessage("URI"),
    "ndefWifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
    "ndefWifiAuthentication": MessageLookupByLibrary.simpleMessage(
      "Authentication",
    ),
    "ndefWifiEncryption": MessageLookupByLibrary.simpleMessage("Encryption"),
    "ndefWifiPassword": MessageLookupByLibrary.simpleMessage(
      "Network password",
    ),
    "ndefWritable": MessageLookupByLibrary.simpleMessage("Writable"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "CanoKey is busy. Replug it, wait for a moment, and retry.",
    ),
    "newPin": MessageLookupByLibrary.simpleMessage("New PIN"),
    "next": MessageLookupByLibrary.simpleMessage("Next"),
    "nfcSound": MessageLookupByLibrary.simpleMessage("NFC interaction sound"),
    "nfcSoundPrompt": MessageLookupByLibrary.simpleMessage(
      "Playing in order: poll, finish, error",
    ),
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
    "oathDelete": m5,
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
    "oathSetDefaultPrompt": m6,
    "oathSlot": MessageLookupByLibrary.simpleMessage("Slot"),
    "oathTooLong": MessageLookupByLibrary.simpleMessage("Too long"),
    "oathType": MessageLookupByLibrary.simpleMessage("Type"),
    "off": MessageLookupByLibrary.simpleMessage("Off"),
    "oldPin": MessageLookupByLibrary.simpleMessage("Current PIN"),
    "on": MessageLookupByLibrary.simpleMessage("On"),
    "openpgpAdminPin": MessageLookupByLibrary.simpleMessage("Admin PIN"),
    "openpgpAdminPinLength": MessageLookupByLibrary.simpleMessage(
      "Admin PIN length must be between 8 and 64 characters.",
    ),
    "openpgpAuthentication": MessageLookupByLibrary.simpleMessage(
      "Authentication",
    ),
    "openpgpCacheSeconds": MessageLookupByLibrary.simpleMessage(
      "Cache seconds",
    ),
    "openpgpCardHolder": MessageLookupByLibrary.simpleMessage("Card Holder"),
    "openpgpCardInfo": MessageLookupByLibrary.simpleMessage("Card Info"),
    "openpgpChangeAdminPin": MessageLookupByLibrary.simpleMessage(
      "Change Admin PIN",
    ),
    "openpgpChangeInteraction": m7,
    "openpgpChangeSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "Change Signature PIN Policy",
    ),
    "openpgpChangeTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "Change Touch Cache Time",
    ),
    "openpgpCurrentAdminPin": MessageLookupByLibrary.simpleMessage(
      "Current Admin PIN",
    ),
    "openpgpEncryption": MessageLookupByLibrary.simpleMessage("Encryption"),
    "openpgpKeyEmpty": MessageLookupByLibrary.simpleMessage("Empty"),
    "openpgpKeyImported": MessageLookupByLibrary.simpleMessage("Imported"),
    "openpgpKeyNone": MessageLookupByLibrary.simpleMessage("[none]"),
    "openpgpKeys": MessageLookupByLibrary.simpleMessage("Keys"),
    "openpgpManufacturer": MessageLookupByLibrary.simpleMessage("Manufacturer"),
    "openpgpNewAdminPin": MessageLookupByLibrary.simpleMessage("New Admin PIN"),
    "openpgpPermanentTouchConfirmation": MessageLookupByLibrary.simpleMessage(
      "I understand this makes touch permanently enabled for this key.",
    ),
    "openpgpPubkeyUrl": MessageLookupByLibrary.simpleMessage("Public Key URL"),
    "openpgpResetCode": MessageLookupByLibrary.simpleMessage("Reset Code"),
    "openpgpRetries": m8,
    "openpgpRetriesUnknown": MessageLookupByLibrary.simpleMessage(
      "Retries: unknown",
    ),
    "openpgpSN": MessageLookupByLibrary.simpleMessage("Serial Number"),
    "openpgpSetPinRetries": MessageLookupByLibrary.simpleMessage(
      "Set PIN Retries",
    ),
    "openpgpSetPinRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "This resets User PIN to 123456 and Admin PIN to 12345678.",
    ),
    "openpgpSetPinRetriesTitle": MessageLookupByLibrary.simpleMessage(
      "Set PIN/Reset/Admin PIN Retries",
    ),
    "openpgpSetResetCode": MessageLookupByLibrary.simpleMessage(
      "Set Reset Code",
    ),
    "openpgpSetResetCodePrompt": MessageLookupByLibrary.simpleMessage(
      "Reset Code must be between 8 and 64 characters. Admin PIN is required.",
    ),
    "openpgpSetTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "Set Touch Cache Time",
    ),
    "openpgpSetTouchCacheTimePrompt": MessageLookupByLibrary.simpleMessage(
      "Set how long one touch confirmation can be reused. 0 means every operation needs a new touch. Admin PIN is required.",
    ),
    "openpgpSignature": MessageLookupByLibrary.simpleMessage("Signature"),
    "openpgpSignaturePin": MessageLookupByLibrary.simpleMessage(
      "Signature PIN",
    ),
    "openpgpSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "Signature PIN Policy",
    ),
    "openpgpTouchCacheOff": MessageLookupByLibrary.simpleMessage("0 sec (off)"),
    "openpgpTouchCacheSeconds": m9,
    "openpgpTouchCached": MessageLookupByLibrary.simpleMessage("Cached touch"),
    "openpgpTouchCachedLabel": MessageLookupByLibrary.simpleMessage(
      "Touch: Cached",
    ),
    "openpgpTouchNone": MessageLookupByLibrary.simpleMessage("No touch"),
    "openpgpTouchOffLabel": MessageLookupByLibrary.simpleMessage("Touch: Off"),
    "openpgpTouchOnLabel": MessageLookupByLibrary.simpleMessage("Touch: On"),
    "openpgpTouchPermanent": MessageLookupByLibrary.simpleMessage("Permanent"),
    "openpgpTouchPermanentCached": MessageLookupByLibrary.simpleMessage(
      "Permanent cached",
    ),
    "openpgpTouchPermanentCachedLabel": MessageLookupByLibrary.simpleMessage(
      "Touch: Permanent cached",
    ),
    "openpgpTouchPermanentLabel": MessageLookupByLibrary.simpleMessage(
      "Touch: Permanent",
    ),
    "openpgpTouchRequired": MessageLookupByLibrary.simpleMessage(
      "Requires touch",
    ),
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
    "openpgpUnblockUserPin": MessageLookupByLibrary.simpleMessage(
      "Unblock User PIN",
    ),
    "openpgpUseAdminPin": MessageLookupByLibrary.simpleMessage("Use Admin PIN"),
    "openpgpUseResetCode": MessageLookupByLibrary.simpleMessage(
      "Use Reset Code",
    ),
    "openpgpUserPin": MessageLookupByLibrary.simpleMessage("User PIN"),
    "openpgpUserPinLength": MessageLookupByLibrary.simpleMessage(
      "User PIN length must be between 6 and 64 characters.",
    ),
    "openpgpVerifyEverySignature": MessageLookupByLibrary.simpleMessage(
      "Verify every signature",
    ),
    "openpgpVerifyEverySignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "Verify User PIN for every signature",
    ),
    "openpgpVerifyOnceAfterInsertion": MessageLookupByLibrary.simpleMessage(
      "Verify once after insertion",
    ),
    "openpgpVerifyOnceAfterInsertionPrompt":
        MessageLookupByLibrary.simpleMessage(
          "Verify once after card insertion",
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
    "passSlotHmacSha1": MessageLookupByLibrary.simpleMessage("HMAC-SHA1"),
    "passSlotHmacSha1Key": MessageLookupByLibrary.simpleMessage(
      "20-byte HMAC-SHA1 key (hex)",
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
    "pinConfirmationMismatch": MessageLookupByLibrary.simpleMessage(
      "PIN confirmation does not match",
    ),
    "pinIncorrect": MessageLookupByLibrary.simpleMessage("Incorrect PIN."),
    "pinInvalidLength": MessageLookupByLibrary.simpleMessage("Invalid length"),
    "pinLength": MessageLookupByLibrary.simpleMessage(
      "The provided PIN is too short or too long.",
    ),
    "pinRetries": m10,
    "pivAlgorithm": MessageLookupByLibrary.simpleMessage("Current Algorithm"),
    "pivAlgorithmIds": MessageLookupByLibrary.simpleMessage("Algorithm IDs"),
    "pivAlgorithmIdsPrompt": MessageLookupByLibrary.simpleMessage(
      "Controls whether PIV extension algorithm IDs are accepted by the card.",
    ),
    "pivAlgorithmIdsTitle": MessageLookupByLibrary.simpleMessage(
      "PIV Algorithm IDs",
    ),
    "pivAlgorithmIdsUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to update PIV algorithm IDs",
    ),
    "pivAlgorithmIdsWarning": MessageLookupByLibrary.simpleMessage(
      "These values control how the card recognizes PIV extension algorithms. Keep the defaults unless you know the client and firmware expect different IDs. Wrong values can make existing extended keys appear unsupported until the IDs are restored.",
    ),
    "pivAlgorithmValue": m11,
    "pivAttestationUnavailable": MessageLookupByLibrary.simpleMessage(
      "Attestation is unavailable. The device must have an F9 attestation key and certificate.",
    ),
    "pivAuthentication": MessageLookupByLibrary.simpleMessage("Authentication"),
    "pivCardAuthentication": MessageLookupByLibrary.simpleMessage(
      "Card Authentication",
    ),
    "pivCertificate": MessageLookupByLibrary.simpleMessage("Certificate"),
    "pivCertificateCopied": MessageLookupByLibrary.simpleMessage(
      "Certificate Copied",
    ),
    "pivCertificateCreated": MessageLookupByLibrary.simpleMessage(
      "Certificate Created",
    ),
    "pivCertificateDoesNotMatchPrivateKey":
        MessageLookupByLibrary.simpleMessage(
          "The certificate public key does not match the selected private key.",
        ),
    "pivCertificateIssuer": MessageLookupByLibrary.simpleMessage("Issuer"),
    "pivCertificateKey": MessageLookupByLibrary.simpleMessage(
      "Certificate Key",
    ),
    "pivCertificateMatchesPrivateKey": MessageLookupByLibrary.simpleMessage(
      "Certificate matches the private key",
    ),
    "pivCertificateMismatchPrivateKey": MessageLookupByLibrary.simpleMessage(
      "Certificate does not match the private key",
    ),
    "pivCertificateOnlyKeepsPrivateKey": MessageLookupByLibrary.simpleMessage(
      "Certificate-only import does not change the private key. Make sure this certificate belongs to the key already on the card.",
    ),
    "pivCertificateSerial": MessageLookupByLibrary.simpleMessage("Serial"),
    "pivCertificateSize": MessageLookupByLibrary.simpleMessage(
      "Certificate Size",
    ),
    "pivCertificateSubject": MessageLookupByLibrary.simpleMessage("Subject"),
    "pivCertificateSubjectStep": MessageLookupByLibrary.simpleMessage(
      "Certificate Subject",
    ),
    "pivCertificateValidFrom": MessageLookupByLibrary.simpleMessage(
      "Valid from",
    ),
    "pivCertificateValidTo": MessageLookupByLibrary.simpleMessage("Valid to"),
    "pivCertificateWritten": m12,
    "pivChangeManagementKey": MessageLookupByLibrary.simpleMessage(
      "Change Management Key",
    ),
    "pivChangeManagementKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "New Management Key should be 24 bytes long. Please save it in a safe place.",
    ),
    "pivChangePUK": MessageLookupByLibrary.simpleMessage("Change PUK"),
    "pivChangePUKPrompt": m13,
    "pivClearSlot": MessageLookupByLibrary.simpleMessage("Clear Slot"),
    "pivClearSlotFailed": MessageLookupByLibrary.simpleMessage(
      "Clear slot failed. Make sure the firmware supports key deletion.",
    ),
    "pivClearSlotPrompt": MessageLookupByLibrary.simpleMessage(
      "This removes both the private key and certificate from this slot. Make sure you have another way to authenticate.",
    ),
    "pivClearSlotTitle": m14,
    "pivCommonName": MessageLookupByLibrary.simpleMessage("Common Name"),
    "pivCopyPem": MessageLookupByLibrary.simpleMessage("Copy PEM"),
    "pivCountryCode": MessageLookupByLibrary.simpleMessage("Country Code"),
    "pivCreateCertificate": MessageLookupByLibrary.simpleMessage(
      "Create Certificate",
    ),
    "pivCreateCertificateFailed": MessageLookupByLibrary.simpleMessage(
      "Create Certificate Failed",
    ),
    "pivCreatingSelfSignedCertificate": MessageLookupByLibrary.simpleMessage(
      "Creating a self-signed certificate",
    ),
    "pivCsrCopied": MessageLookupByLibrary.simpleMessage("CSR Copied"),
    "pivCsrGenerated": MessageLookupByLibrary.simpleMessage("CSR Generated"),
    "pivCsrGenerationPrompt": MessageLookupByLibrary.simpleMessage(
      "CSR generation signs the request with the new key on the card.",
    ),
    "pivCsrSubject": MessageLookupByLibrary.simpleMessage("CSR Subject"),
    "pivDangerZone": MessageLookupByLibrary.simpleMessage("Danger Zone"),
    "pivDelete": MessageLookupByLibrary.simpleMessage("Delete"),
    "pivDeleteSlot": m15,
    "pivDestinationSlot": MessageLookupByLibrary.simpleMessage(
      "Destination slot",
    ),
    "pivDiagnostics": MessageLookupByLibrary.simpleMessage("Key operations"),
    "pivDisablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "Return to Manual Management Key",
    ),
    "pivDisablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage(
          "Failed to return to manual management key",
        ),
    "pivDisablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage(
          "A new management key will be set before the PIN-protected copy is cleared.",
        ),
    "pivDisablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage(
          "Manual management key is now required",
        ),
    "pivDnsSans": MessageLookupByLibrary.simpleMessage(
      "DNS SANs, comma separated",
    ),
    "pivDownloadAttestation": MessageLookupByLibrary.simpleMessage(
      "Download Attestation",
    ),
    "pivEmpty": MessageLookupByLibrary.simpleMessage("Empty"),
    "pivEnablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "Use PIN-Protected Management Key",
    ),
    "pivEnablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage(
          "Failed to store a PIN-protected management key",
        ),
    "pivEnablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage(
          "A random management key will be set and stored on the card, protected by PIN.",
        ),
    "pivEnablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage(
          "Management key is now PIN-protected",
        ),
    "pivExport": MessageLookupByLibrary.simpleMessage("Export"),
    "pivExportCertificate": MessageLookupByLibrary.simpleMessage(
      "Export Certificate",
    ),
    "pivExportPublicKey": MessageLookupByLibrary.simpleMessage(
      "Export Public Key",
    ),
    "pivExtendedAlgorithmCompatibilityWarning":
        MessageLookupByLibrary.simpleMessage(
          "Check client compatibility before using this algorithm.",
        ),
    "pivFile": MessageLookupByLibrary.simpleMessage("File"),
    "pivFileSigningFailed": MessageLookupByLibrary.simpleMessage(
      "File signing failed",
    ),
    "pivGenerate": MessageLookupByLibrary.simpleMessage("Generate"),
    "pivGenerateCsr": MessageLookupByLibrary.simpleMessage("Generate CSR"),
    "pivGenerateCsrFailed": MessageLookupByLibrary.simpleMessage(
      "Generate CSR Failed",
    ),
    "pivGenerateKey": MessageLookupByLibrary.simpleMessage("Generate Key"),
    "pivGenerateKeyFailed": MessageLookupByLibrary.simpleMessage(
      "Generate Key Failed",
    ),
    "pivGenerateX25519": MessageLookupByLibrary.simpleMessage(
      "Generate X25519",
    ),
    "pivGenerateX25519Key": MessageLookupByLibrary.simpleMessage(
      "Generate X25519 Key",
    ),
    "pivGenerateX25519KeyFailed": MessageLookupByLibrary.simpleMessage(
      "Generate X25519 Key Failed",
    ),
    "pivGeneratingCsr": MessageLookupByLibrary.simpleMessage(
      "Generating a CSR",
    ),
    "pivGeneratingKey": m16,
    "pivGeneratingX25519Key": MessageLookupByLibrary.simpleMessage(
      "Generating an X25519 key",
    ),
    "pivImport": MessageLookupByLibrary.simpleMessage("Import"),
    "pivImportFailed": MessageLookupByLibrary.simpleMessage("Import failed"),
    "pivImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "Import succeeded",
    ),
    "pivImportWillReplaceCertificate": MessageLookupByLibrary.simpleMessage(
      "This import will replace the certificate currently stored in this slot.",
    ),
    "pivImportWillReplacePrivateKey": MessageLookupByLibrary.simpleMessage(
      "This import will replace the private key currently stored in this slot.",
    ),
    "pivImportingPrivateKey": MessageLookupByLibrary.simpleMessage(
      "Importing a private key",
    ),
    "pivKeyGenerated": MessageLookupByLibrary.simpleMessage("Key Generated"),
    "pivKeyManagement": MessageLookupByLibrary.simpleMessage("Key Management"),
    "pivKeyMoved": MessageLookupByLibrary.simpleMessage("Key moved"),
    "pivKeyOnlyKeepsCertificate": MessageLookupByLibrary.simpleMessage(
      "Key-only import leaves the existing certificate in place. Replace or clear the certificate if it no longer matches.",
    ),
    "pivKeyOptions": MessageLookupByLibrary.simpleMessage("Key Options"),
    "pivManagementKey": MessageLookupByLibrary.simpleMessage("Management Key"),
    "pivManagementKeyAuthentication": MessageLookupByLibrary.simpleMessage(
      "Management key authentication",
    ),
    "pivManagementKeyVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "Management Key verification failed",
    ),
    "pivManualManagementKey": MessageLookupByLibrary.simpleMessage(
      "Manual management key",
    ),
    "pivManualManagementKeyDescription": MessageLookupByLibrary.simpleMessage(
      "Enter the 24-byte management key for this operation.",
    ),
    "pivMessage": MessageLookupByLibrary.simpleMessage("Message"),
    "pivMessageSigningFailed": MessageLookupByLibrary.simpleMessage(
      "Message signing failed",
    ),
    "pivModifyWithCaution": MessageLookupByLibrary.simpleMessage(
      "Modify With Caution",
    ),
    "pivMoveKey": MessageLookupByLibrary.simpleMessage("Move Key"),
    "pivMoveKeyFailed": MessageLookupByLibrary.simpleMessage(
      "Key move failed. The destination must not contain a key.",
    ),
    "pivMoveKeyFrom": m17,
    "pivMoveKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "Only the private key is moved. Certificates remain in their current slots.",
    ),
    "pivNewManagementKey": MessageLookupByLibrary.simpleMessage(
      "New Management Key",
    ),
    "pivNewPUK": MessageLookupByLibrary.simpleMessage("New PUK"),
    "pivNoCertificate": MessageLookupByLibrary.simpleMessage("No certificate"),
    "pivNoEmptyDestinationSlot": MessageLookupByLibrary.simpleMessage(
      "No empty destination slot is available.",
    ),
    "pivNoFileSelected": MessageLookupByLibrary.simpleMessage(
      "No file selected",
    ),
    "pivNoPublicKeyAvailable": MessageLookupByLibrary.simpleMessage(
      "No public key available",
    ),
    "pivNotSelected": MessageLookupByLibrary.simpleMessage("Not selected"),
    "pivOldManagementKey": MessageLookupByLibrary.simpleMessage(
      "Current Management Key",
    ),
    "pivOldPUK": MessageLookupByLibrary.simpleMessage("Current PUK"),
    "pivOrganization": MessageLookupByLibrary.simpleMessage("Organization"),
    "pivOrganizationalUnit": MessageLookupByLibrary.simpleMessage(
      "Organizational Unit",
    ),
    "pivOrigin": MessageLookupByLibrary.simpleMessage("Origin"),
    "pivOriginGenerated": MessageLookupByLibrary.simpleMessage("Generated"),
    "pivOriginImported": MessageLookupByLibrary.simpleMessage("Imported"),
    "pivOverwrite": MessageLookupByLibrary.simpleMessage("Overwrite"),
    "pivOverwriteKey": MessageLookupByLibrary.simpleMessage("Overwrite Key"),
    "pivOverwriteKeyPrompt": m18,
    "pivPinAndTouchPolicy": MessageLookupByLibrary.simpleMessage(
      "PIN and Touch Policy",
    ),
    "pivPinManagement": MessageLookupByLibrary.simpleMessage("PIN Management"),
    "pivPinPolicy": MessageLookupByLibrary.simpleMessage("PIN Policy"),
    "pivPinPolicyAlways": MessageLookupByLibrary.simpleMessage("Always"),
    "pivPinPolicyChip": m19,
    "pivPinPolicyDefault": MessageLookupByLibrary.simpleMessage("Default"),
    "pivPinPolicyNever": MessageLookupByLibrary.simpleMessage("Never"),
    "pivPinPolicyOnce": MessageLookupByLibrary.simpleMessage("Once"),
    "pivPinProtectedKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "PIN-protected key on card",
    ),
    "pivPinProtectedManagementKeyDescription":
        MessageLookupByLibrary.simpleMessage(
          "Use the PIN to unlock the management key stored on this card.",
        ),
    "pivPinRetries": MessageLookupByLibrary.simpleMessage("PIN retries"),
    "pivPostQuantumCertificateGenerationDisabled":
        MessageLookupByLibrary.simpleMessage(
          "CSR, self-signed certificates, and attestation are unavailable for this algorithm.",
        ),
    "pivPrivateKey": MessageLookupByLibrary.simpleMessage("Private Key"),
    "pivProvisioning": MessageLookupByLibrary.simpleMessage("Provisioning"),
    "pivPublicKey": MessageLookupByLibrary.simpleMessage("Public Key"),
    "pivPukRetries": MessageLookupByLibrary.simpleMessage("PUK retries"),
    "pivRandomManagementKey": MessageLookupByLibrary.simpleMessage("Random"),
    "pivRetired1": MessageLookupByLibrary.simpleMessage("Retired 1"),
    "pivRetired2": MessageLookupByLibrary.simpleMessage("Retired 2"),
    "pivRetiredSlot": m20,
    "pivRetries": m21,
    "pivRetriesUnknown": MessageLookupByLibrary.simpleMessage(
      "Retries: unknown",
    ),
    "pivReview": MessageLookupByLibrary.simpleMessage("Review"),
    "pivSavePem": MessageLookupByLibrary.simpleMessage("Save PEM"),
    "pivSelectCertificateOrKeyFirst": MessageLookupByLibrary.simpleMessage(
      "Select a certificate or private key first.",
    ),
    "pivSelectFile": MessageLookupByLibrary.simpleMessage("Select File"),
    "pivSelectFileAndSignatureFirst": MessageLookupByLibrary.simpleMessage(
      "Select a file and signature first.",
    ),
    "pivSelectFileFirst": MessageLookupByLibrary.simpleMessage(
      "Select a file first.",
    ),
    "pivSelectFileHint": MessageLookupByLibrary.simpleMessage(
      "(Make sure the file contains a plaintext key or a certificate)",
    ),
    "pivSelectFilePrompt": MessageLookupByLibrary.simpleMessage(
      "Click to select a PEM or DER certificate/key",
    ),
    "pivSelfSign": MessageLookupByLibrary.simpleMessage("Self-sign"),
    "pivSelfSignCertificate": MessageLookupByLibrary.simpleMessage(
      "Self-sign Certificate",
    ),
    "pivSelfSignedCertificateWarning": MessageLookupByLibrary.simpleMessage(
      "Self-signed certificates are for local testing and compatibility depends on the client.",
    ),
    "pivSetPinPukRetries": MessageLookupByLibrary.simpleMessage(
      "Set PIN/PUK Retries",
    ),
    "pivSetPinPukRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "This resets PIN to 123456 and PUK to 12345678.",
    ),
    "pivSetRetriesFailed": MessageLookupByLibrary.simpleMessage(
      "Set retries failed",
    ),
    "pivSetRetriesSuccess": MessageLookupByLibrary.simpleMessage(
      "PIN/PUK retries set. PIN and PUK were reset.",
    ),
    "pivSha256Fingerprint": MessageLookupByLibrary.simpleMessage(
      "SHA-256 Fingerprint",
    ),
    "pivSign": MessageLookupByLibrary.simpleMessage("Sign"),
    "pivSignFile": MessageLookupByLibrary.simpleMessage("Sign File"),
    "pivSignFilePrompt": MessageLookupByLibrary.simpleMessage(
      "Creates a detached raw signature for the selected file.",
    ),
    "pivSignMessage": MessageLookupByLibrary.simpleMessage("Sign Message"),
    "pivSignature": MessageLookupByLibrary.simpleMessage("Digital Signature"),
    "pivSignatureAlgorithm": MessageLookupByLibrary.simpleMessage(
      "Signature Algorithm",
    ),
    "pivSignatureFile": MessageLookupByLibrary.simpleMessage("Signature"),
    "pivSignatureHex": MessageLookupByLibrary.simpleMessage("Signature (hex)"),
    "pivSignatureVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "Signature verification failed",
    ),
    "pivSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "Signature verified",
    ),
    "pivSlotAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "Authentication slot. Use a signing-capable key for login.",
    ),
    "pivSlotCardAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "Card authentication slot. PIN may be unnecessary for some uses.",
    ),
    "pivSlotCleared": MessageLookupByLibrary.simpleMessage("Slot cleared"),
    "pivSlotKeyManagementHint": MessageLookupByLibrary.simpleMessage(
      "Key management slot. X25519 can derive shared secrets only.",
    ),
    "pivSlotRetiredHint": MessageLookupByLibrary.simpleMessage(
      "Retired key management slot for old decryption keys and certificates.",
    ),
    "pivSlotSignatureHint": MessageLookupByLibrary.simpleMessage(
      "Digital signature slot. PIN policy defaults to always.",
    ),
    "pivSlots": MessageLookupByLibrary.simpleMessage("Slots"),
    "pivStoreManagementKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "Store the new management key on this card",
    ),
    "pivStoreManagementKeyOnCardPrompt": MessageLookupByLibrary.simpleMessage(
      "When enabled, future management operations can authenticate with PIN.",
    ),
    "pivTouchPolicy": MessageLookupByLibrary.simpleMessage("Touch Policy"),
    "pivTouchPolicyAlways": MessageLookupByLibrary.simpleMessage("Always"),
    "pivTouchPolicyCached": MessageLookupByLibrary.simpleMessage(
      "Cached for 15 seconds",
    ),
    "pivTouchPolicyChip": m22,
    "pivTouchPolicyDefault": MessageLookupByLibrary.simpleMessage("Default"),
    "pivTouchPolicyNever": MessageLookupByLibrary.simpleMessage("Never"),
    "pivUnblockPin": MessageLookupByLibrary.simpleMessage("Unblock PIN"),
    "pivUnblockPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Enter the current PUK and set a new PIN.",
    ),
    "pivUnsupportedImportFile": MessageLookupByLibrary.simpleMessage(
      "Unsupported file. Use PEM or DER certificate/private key files.",
    ),
    "pivUseDefaultManagementKey": MessageLookupByLibrary.simpleMessage(
      "Default",
    ),
    "pivValidityDays": MessageLookupByLibrary.simpleMessage("Validity Days"),
    "pivVerify": MessageLookupByLibrary.simpleMessage("Verify"),
    "pivVerifyFile": MessageLookupByLibrary.simpleMessage("Verify File"),
    "pivVerifyFileSignature": MessageLookupByLibrary.simpleMessage(
      "Verify File Signature",
    ),
    "pivVerifyFileSignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "Verifies a detached raw signature against this slot public key.",
    ),
    "pivVerifyManagementKey": MessageLookupByLibrary.simpleMessage(
      "Verify Management Key",
    ),
    "pivVerifyPinAndManagementKey": MessageLookupByLibrary.simpleMessage(
      "Verify PIN and Management Key",
    ),
    "pivX25519CannotUseCertificate": MessageLookupByLibrary.simpleMessage(
      "X25519 cannot be used with certificates. Import the key without a certificate.",
    ),
    "pivX25519CertificateDisabled": MessageLookupByLibrary.simpleMessage(
      "CSR and certificates are disabled for X25519.",
    ),
    "pivX25519KeyGenerated": MessageLookupByLibrary.simpleMessage(
      "X25519 Key Generated",
    ),
    "pivX25519OnlyIn9D": MessageLookupByLibrary.simpleMessage(
      "X25519 keys are only supported in the key management slot 9D.",
    ),
    "play": MessageLookupByLibrary.simpleMessage("Play"),
    "pollCanceled": MessageLookupByLibrary.simpleMessage(
      "No CanoKey is selected.",
    ),
    "pollCanoKey": MessageLookupByLibrary.simpleMessage(
      "Please read your CanoKey by clicking the refresh button",
    ),
    "readingAlertMessage": MessageLookupByLibrary.simpleMessage(
      "Hold the CanoKey until finished",
    ),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "savePinOnDevice": MessageLookupByLibrary.simpleMessage(
      "Save the PIN on this device",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "seconds": MessageLookupByLibrary.simpleMessage("seconds"),
    "select": MessageLookupByLibrary.simpleMessage("Select"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "settingsAppletStorageUsage": MessageLookupByLibrary.simpleMessage(
      "Applet Flash Usage",
    ),
    "settingsAppletSwitches": MessageLookupByLibrary.simpleMessage(
      "Applet Switches",
    ),
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
    "settingsCoreCommit": MessageLookupByLibrary.simpleMessage("Core Commit"),
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
    "settingsKeyboardLayout": MessageLookupByLibrary.simpleMessage(
      "Keyboard Layout",
    ),
    "settingsKeyboardLayoutCurrent": m23,
    "settingsKeyboardLayoutCustom": MessageLookupByLibrary.simpleMessage(
      "Custom layout",
    ),
    "settingsKeyboardLayoutDefault": MessageLookupByLibrary.simpleMessage(
      "Default / US QWERTY",
    ),
    "settingsKeyboardLayoutUnknown": MessageLookupByLibrary.simpleMessage(
      "Unknown",
    ),
    "settingsKeyboardLayoutUnknownPrompt": MessageLookupByLibrary.simpleMessage(
      "The current keymap does not match a built-in preset. Applying a preset will overwrite it.",
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
    "settingsOpenPgpCcId": MessageLookupByLibrary.simpleMessage(
      "OpenPGP (CCID)",
    ),
    "settingsOpenPgpNfc": MessageLookupByLibrary.simpleMessage("OpenPGP (NFC)"),
    "settingsOtherSettings": MessageLookupByLibrary.simpleMessage(
      "Other Settings",
    ),
    "settingsPassApplet": MessageLookupByLibrary.simpleMessage("Pass"),
    "settingsPivCcId": MessageLookupByLibrary.simpleMessage("PIV (CCID)"),
    "settingsPivNfc": MessageLookupByLibrary.simpleMessage("PIV (NFC)"),
    "settingsResetAll": MessageLookupByLibrary.simpleMessage("Reset CanoKey"),
    "settingsResetAllPrompt": MessageLookupByLibrary.simpleMessage(
      "All data will be erased. Once confirmed, the CanoKey will blink multiple times. Please touch it each time you see a blink until the success prompt appears.",
    ),
    "settingsResetApplet": m24,
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
    "settingsStorageFree": MessageLookupByLibrary.simpleMessage("Free"),
    "settingsStorageUsage": MessageLookupByLibrary.simpleMessage(
      "Storage Usage",
    ),
    "settingsWebAuthnApplet": MessageLookupByLibrary.simpleMessage("WebAuthn"),
    "settingsWebAuthnSm2Support": MessageLookupByLibrary.simpleMessage(
      "WebAuthn SM2",
    ),
    "settingsWebUSB": MessageLookupByLibrary.simpleMessage(
      "WebUSB prompt when plug-in",
    ),
    "soundCredit": MessageLookupByLibrary.simpleMessage(
      "Summer Xu is the author of NFC interaction sounds.",
    ),
    "storageFull": MessageLookupByLibrary.simpleMessage(
      "CanoKey storage is full.",
    ),
    "successfullyChanged": MessageLookupByLibrary.simpleMessage(
      "Successfully changed",
    ),
    "validationAtLeastCharacters": m25,
    "validationAtMostCharacters": m26,
    "validationExactLength": m27,
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
    "webauthnDelete": m28,
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
