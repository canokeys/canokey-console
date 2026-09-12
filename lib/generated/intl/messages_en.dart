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
      "The new PIN must contain ${min} to ${max} characters.";

  static String m2(error) => "Save failed: ${error}";

  static String m3(used, total) => "${used} of ${total} bytes";

  static String m4(error) =>
      "Could not save this record. Check the fields. Details: ${error}";

  static String m5(protocol) => "${protocol} Enterprise";

  static String m6(protocol) => "${protocol} Personal";

  static String m7(name) =>
      "Deleting ${name} permanently removes its one-time codes from CanoKey. Make sure you have another verification method or have disabled two-step verification for this service.";

  static String m8(name) =>
      "Type a code for ${name} when you touch CanoKey? This replaces the current touch output setting.";

  static String m9(keyType) => "Change ${keyType} Key\'s Touch Policy";

  static String m10(remaining) => "Retries: ${remaining}";

  static String m11(seconds) => "${seconds} sec";

  static String m12(retries) => "Incorrect PIN. ${retries} retries left.";

  static String m13(algorithm) => "Algorithm: ${algorithm}";

  static String m14(slot) =>
      "A self-signed certificate was written to slot ${slot}.";

  static String m15(min, max) =>
      "The new PUK must contain ${min} to ${max} characters.";

  static String m16(slot) => "Clear Slot ${slot}";

  static String m17(slot) =>
      "Delete the key and certificate in slot ${slot}? This cannot be undone. Make sure you have another way to sign in or decrypt your data.";

  static String m18(algorithm) => "Generating a ${algorithm} key";

  static String m19(slot) => "Check ${slot}";

  static String m20(slot) => "Recommended settings applied to ${slot}";

  static String m21(sourceSlot) => "Move Key from ${sourceSlot}";

  static String m22(count) => "${count} occupied";

  static String m23(action, slot) =>
      "${action} will replace the private key in slot ${slot}. Existing authentication or signing that depends on this key may stop working.";

  static String m24(policy) => "PIN: ${policy}";

  static String m25(index) => "Retired ${index}";

  static String m26(remaining, total) => "Retries: ${remaining}/${total}";

  static String m27(policy) => "Touch: ${policy}";

  static String m28(layout) => "Current: ${layout}";

  static String m29(applet) =>
      "Resetting ${applet} will permanently delete all its data.";

  static String m30(min) => "At least ${min} characters";

  static String m31(max) => "At most ${max} characters";

  static String m32(length) => "Enter exactly ${length} characters";

  static String m33(max) => "Enter a whole number of at most ${max}.";

  static String m34(min) => "Enter a whole number of at least ${min}.";

  static String m35(name) =>
      "Delete the sign-in credential for ${name}? This cannot be undone. Make sure you have another way to sign in.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "actions": MessageLookupByLibrary.simpleMessage("Actions"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "agreeAndContinue": MessageLookupByLibrary.simpleMessage(
      "Agree and Continue",
    ),
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
    "confirmNewPin": MessageLookupByLibrary.simpleMessage("Confirm new PIN"),
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
      "Could not connect to CanoKey over USB. Check the connection, then reopen this app. Error details:",
    ),
    "disable": MessageLookupByLibrary.simpleMessage("Disable"),
    "disableSound": MessageLookupByLibrary.simpleMessage("Sound disabled"),
    "disagreeAndExit": MessageLookupByLibrary.simpleMessage(
      "Disagree and Exit",
    ),
    "enable": MessageLookupByLibrary.simpleMessage("Enable"),
    "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
    "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
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
      "The connection was interrupted. Reconnect CanoKey. For NFC, keep it near your phone.",
    ),
    "iosAlertMessage": MessageLookupByLibrary.simpleMessage(
      "Hold your iPhone near the CanoKey",
    ),
    "iosPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "Pull down or tap refresh, then hold your iPhone near your CanoKey, or insert it into the USB port",
    ),
    "logsCopied": MessageLookupByLibrary.simpleMessage("Log copied"),
    "logsCopyFailed": MessageLookupByLibrary.simpleMessage(
      "Could not copy log",
    ),
    "logsEmpty": MessageLookupByLibrary.simpleMessage(
      "No logs in this session",
    ),
    "logsRecording": MessageLookupByLibrary.simpleMessage("Record logs"),
    "logsTitle": MessageLookupByLibrary.simpleMessage("View Logs"),
    "ndefAbsoluteUri": MessageLookupByLibrary.simpleMessage("Absolute URI"),
    "ndefAddRecord": MessageLookupByLibrary.simpleMessage("Add record"),
    "ndefAndroidApplication": MessageLookupByLibrary.simpleMessage(
      "Android app",
    ),
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
      "The content exceeds the NFC tag capacity. Remove some content and try again.",
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
      "Could not read the existing NFC tag content. To start over, reset NDEF in Settings. This deletes the existing tag content.",
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
      "Enter a full link, such as https://example.com or mailto:name@example.com.",
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
    "ndefNoRecords": MessageLookupByLibrary.simpleMessage("No records yet"),
    "ndefNoRecordsDescription": MessageLookupByLibrary.simpleMessage(
      "Add a link, text or other content for devices to read over NFC.",
    ),
    "ndefOptionalHex": MessageLookupByLibrary.simpleMessage(
      "Hexadecimal data; optional",
    ),
    "ndefOther": MessageLookupByLibrary.simpleMessage("Other"),
    "ndefPayload": MessageLookupByLibrary.simpleMessage("Record content"),
    "ndefPayloadConversionFailed": MessageLookupByLibrary.simpleMessage(
      "Could not convert the content. Check the hexadecimal format or confirm the content is valid UTF-8 text.",
    ),
    "ndefPayloadEncoding": MessageLookupByLibrary.simpleMessage(
      "Content encoding",
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
      "Fill in this field.",
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
      "Choose what other devices read when they scan CanoKey over NFC.",
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
      "The selected record format requires the type name to be empty. Clear that field.",
    ),
    "ndefTnfUnchanged": MessageLookupByLibrary.simpleMessage(
      "Same type as the previous chunk",
    ),
    "ndefTnfUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "ndefTnfWellKnown": MessageLookupByLibrary.simpleMessage(
      "NFC Forum well-known",
    ),
    "ndefTypeName": MessageLookupByLibrary.simpleMessage("Type name"),
    "ndefTypeNameFormat": MessageLookupByLibrary.simpleMessage(
      "Type name format (TNF)",
    ),
    "ndefUnsavedChanges": MessageLookupByLibrary.simpleMessage(
      "Unsaved changes",
    ),
    "ndefUri": MessageLookupByLibrary.simpleMessage("Link"),
    "ndefUriValue": MessageLookupByLibrary.simpleMessage("Link address"),
    "ndefWifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
    "ndefWifiAuthentication": MessageLookupByLibrary.simpleMessage(
      "Authentication",
    ),
    "ndefWifiEncryption": MessageLookupByLibrary.simpleMessage("Encryption"),
    "ndefWifiEnterprise": m5,
    "ndefWifiNoEncryption": MessageLookupByLibrary.simpleMessage(
      "No encryption",
    ),
    "ndefWifiOpen": MessageLookupByLibrary.simpleMessage("Open network"),
    "ndefWifiPassword": MessageLookupByLibrary.simpleMessage(
      "Network password",
    ),
    "ndefWifiPersonal": m6,
    "ndefWifiShared": MessageLookupByLibrary.simpleMessage("Shared key"),
    "ndefWritable": MessageLookupByLibrary.simpleMessage("Writable"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "Could not communicate with CanoKey. Reconnect it and try again.",
    ),
    "newPin": MessageLookupByLibrary.simpleMessage("New PIN"),
    "next": MessageLookupByLibrary.simpleMessage("Next"),
    "nfcSound": MessageLookupByLibrary.simpleMessage("NFC interaction sound"),
    "nfcSoundPrompt": MessageLookupByLibrary.simpleMessage(
      "Preview order: reading started, reading completed, reading failed",
    ),
    "noCard": MessageLookupByLibrary.simpleMessage("CanoKey not found"),
    "noCredential": MessageLookupByLibrary.simpleMessage("No credential"),
    "noMatchingCredential": MessageLookupByLibrary.simpleMessage(
      "No matching credential found",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("Not supported"),
    "notSupportedInNFC": MessageLookupByLibrary.simpleMessage(
      "Connect CanoKey over USB to use this feature.",
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
      "Use the settings provided by the service. Other settings may produce codes that do not work.",
    ),
    "oathAlgorithm": MessageLookupByLibrary.simpleMessage("Algorithm"),
    "oathCode": MessageLookupByLibrary.simpleMessage("Passphrase"),
    "oathCodeChanged": MessageLookupByLibrary.simpleMessage(
      "Passphrase Changed",
    ),
    "oathCopy": MessageLookupByLibrary.simpleMessage("Copy to Clipboard"),
    "oathCounter": MessageLookupByLibrary.simpleMessage("Counter"),
    "oathCounterMustBeNumber": MessageLookupByLibrary.simpleMessage(
      "Enter a whole number",
    ),
    "oathDelete": m7,
    "oathDescription": MessageLookupByLibrary.simpleMessage(
      "Manage one-time codes for your accounts (TOTP / HOTP).",
    ),
    "oathDigits": MessageLookupByLibrary.simpleMessage("Digits"),
    "oathDuplicated": MessageLookupByLibrary.simpleMessage(
      "Duplicated account",
    ),
    "oathInputCode": MessageLookupByLibrary.simpleMessage("Unlock CanoKey"),
    "oathInputCodePrompt": MessageLookupByLibrary.simpleMessage(
      "Enter the passphrase that protects the TOTP / HOTP accounts on this CanoKey.",
    ),
    "oathInvalidKey": MessageLookupByLibrary.simpleMessage(
      "Invalid secret key",
    ),
    "oathIssuer": MessageLookupByLibrary.simpleMessage("Issuer"),
    "oathNewCode": MessageLookupByLibrary.simpleMessage("New Passphrase"),
    "oathNewCodePrompt": MessageLookupByLibrary.simpleMessage(
      "Enter a new passphrase. Leave it empty and save to remove passphrase protection.",
    ),
    "oathNoQr": MessageLookupByLibrary.simpleMessage("No QR Code detected"),
    "oathPeriod": MessageLookupByLibrary.simpleMessage(
      "Update interval (seconds)",
    ),
    "oathRequireTouch": MessageLookupByLibrary.simpleMessage("Require Touch"),
    "oathRequired": MessageLookupByLibrary.simpleMessage("Fill in this field"),
    "oathSearch": MessageLookupByLibrary.simpleMessage(
      "Search account name or email",
    ),
    "oathSecret": MessageLookupByLibrary.simpleMessage("Secret key"),
    "oathSetCode": MessageLookupByLibrary.simpleMessage("Set Passphrase"),
    "oathSetDefault": MessageLookupByLibrary.simpleMessage(
      "Set as Touch Output",
    ),
    "oathSetDefaultPrompt": m8,
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
    "openpgpChangeInteraction": m9,
    "openpgpChangeSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "Change Signature PIN Policy",
    ),
    "openpgpChangeTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "Change Touch Cache Time",
    ),
    "openpgpCurrentAdminPin": MessageLookupByLibrary.simpleMessage(
      "Current Admin PIN",
    ),
    "openpgpDescription": MessageLookupByLibrary.simpleMessage(
      "View OpenPGP card information and manage PINs and touch confirmation.",
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
    "openpgpRetries": m10,
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
      "Set PIN and Reset Code retry limits",
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
    "openpgpTouchCacheSeconds": m11,
    "openpgpTouchCached": MessageLookupByLibrary.simpleMessage("Cached touch"),
    "openpgpTouchCachedLabel": MessageLookupByLibrary.simpleMessage(
      "Touch: Cached",
    ),
    "openpgpTouchNone": MessageLookupByLibrary.simpleMessage("No touch"),
    "openpgpTouchOffLabel": MessageLookupByLibrary.simpleMessage("Touch: Off"),
    "openpgpTouchOnLabel": MessageLookupByLibrary.simpleMessage("Touch: On"),
    "openpgpTouchPermanent": MessageLookupByLibrary.simpleMessage("Permanent"),
    "openpgpTouchPermanentCached": MessageLookupByLibrary.simpleMessage(
      "Cached touch (cannot disable)",
    ),
    "openpgpTouchPermanentCachedLabel": MessageLookupByLibrary.simpleMessage(
      "Touch: Cached, cannot disable",
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
    "operationFailed": MessageLookupByLibrary.simpleMessage(
      "The operation failed. Read CanoKey again and try again.",
    ),
    "other": MessageLookupByLibrary.simpleMessage("Other"),
    "passDescription": MessageLookupByLibrary.simpleMessage(
      "Choose the password output for a short or long press on CanoKey.",
    ),
    "passInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Enter the admin PIN used for Settings. The default is 123456.",
    ),
    "passNotSupported": MessageLookupByLibrary.simpleMessage(
      "Your CanoKey does not support Pass.",
    ),
    "passSlotConfigPrompt": MessageLookupByLibrary.simpleMessage(
      "Choose what happens when you touch CanoKey. To output HOTP codes, configure an account on the TOTP / HOTP page.",
    ),
    "passSlotConfigTitle": MessageLookupByLibrary.simpleMessage(
      "Touch output settings",
    ),
    "passSlotHmacSha1": MessageLookupByLibrary.simpleMessage("HMAC-SHA1"),
    "passSlotHmacSha1Key": MessageLookupByLibrary.simpleMessage(
      "20-byte HMAC-SHA1 key (hex)",
    ),
    "passSlotHotp": MessageLookupByLibrary.simpleMessage("HOTP"),
    "passSlotLong": MessageLookupByLibrary.simpleMessage("Long press"),
    "passSlotOff": MessageLookupByLibrary.simpleMessage("Off"),
    "passSlotShort": MessageLookupByLibrary.simpleMessage("Short press"),
    "passSlotStatic": MessageLookupByLibrary.simpleMessage("Static Password"),
    "passSlotWithEnter": MessageLookupByLibrary.simpleMessage(
      "Press Enter after typing",
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
    "pinRetries": m12,
    "pinVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "PIN verification failed. Read CanoKey again and try again.",
    ),
    "pivActionsDescription": MessageLookupByLibrary.simpleMessage(
      "Choose an operation for this slot.",
    ),
    "pivAlgorithm": MessageLookupByLibrary.simpleMessage("Key algorithm"),
    "pivAlgorithmColumn": MessageLookupByLibrary.simpleMessage("Algorithm"),
    "pivAlgorithmIds": MessageLookupByLibrary.simpleMessage("Algorithm IDs"),
    "pivAlgorithmIdsPrompt": MessageLookupByLibrary.simpleMessage(
      "Allow CanoKey to use extension algorithms.",
    ),
    "pivAlgorithmIdsTitle": MessageLookupByLibrary.simpleMessage(
      "PIV Algorithm IDs",
    ),
    "pivAlgorithmIdsUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to update PIV algorithm IDs",
    ),
    "pivAlgorithmIdsWarning": MessageLookupByLibrary.simpleMessage(
      "Keep the defaults unless your software or firmware requires different algorithm IDs. Incorrect IDs may prevent existing keys from being recognized until you restore the correct values.",
    ),
    "pivAlgorithmValue": m13,
    "pivAttestationUnavailable": MessageLookupByLibrary.simpleMessage(
      "Attestation is unavailable. The device must have an F9 attestation key and certificate.",
    ),
    "pivAuthentication": MessageLookupByLibrary.simpleMessage("Authentication"),
    "pivBasicConstraints": MessageLookupByLibrary.simpleMessage(
      "Basic constraints",
    ),
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
    "pivCertificateCustom": MessageLookupByLibrary.simpleMessage(
      "Custom settings",
    ),
    "pivCertificateDoesNotMatchPrivateKey":
        MessageLookupByLibrary.simpleMessage(
          "The certificate public key does not match the selected private key.",
        ),
    "pivCertificateExtensions": MessageLookupByLibrary.simpleMessage(
      "Certificate extensions",
    ),
    "pivCertificateInfo": MessageLookupByLibrary.simpleMessage(
      "Certificate information",
    ),
    "pivCertificateInfoDescription": MessageLookupByLibrary.simpleMessage(
      "Certificate details for this slot.",
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
    "pivCertificatePresent": MessageLookupByLibrary.simpleMessage(
      "Certificate present",
    ),
    "pivCertificateSerial": MessageLookupByLibrary.simpleMessage("Serial"),
    "pivCertificateSize": MessageLookupByLibrary.simpleMessage(
      "Certificate Size",
    ),
    "pivCertificateStatus": MessageLookupByLibrary.simpleMessage(
      "Certificate status",
    ),
    "pivCertificateSubject": MessageLookupByLibrary.simpleMessage("Subject"),
    "pivCertificateSubjectAndExtensions": MessageLookupByLibrary.simpleMessage(
      "Certificate information and extensions",
    ),
    "pivCertificateSubjectStep": MessageLookupByLibrary.simpleMessage(
      "Certificate Subject",
    ),
    "pivCertificateValidFrom": MessageLookupByLibrary.simpleMessage(
      "Valid from",
    ),
    "pivCertificateValidTo": MessageLookupByLibrary.simpleMessage("Valid to"),
    "pivCertificateWritten": m14,
    "pivChangeManagementKey": MessageLookupByLibrary.simpleMessage(
      "Change Management Key",
    ),
    "pivChangeManagementKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "New Management Key should be 24 bytes long. Please save it in a safe place.",
    ),
    "pivChangePUK": MessageLookupByLibrary.simpleMessage("Change PUK"),
    "pivChangePUKPrompt": m15,
    "pivClearSlot": MessageLookupByLibrary.simpleMessage("Clear Slot"),
    "pivClearSlotFailed": MessageLookupByLibrary.simpleMessage(
      "Clear slot failed. Make sure the firmware supports key deletion.",
    ),
    "pivClearSlotPrompt": MessageLookupByLibrary.simpleMessage(
      "This removes both the private key and certificate from this slot. Make sure you have another way to authenticate.",
    ),
    "pivClearSlotTitle": m16,
    "pivCommonName": MessageLookupByLibrary.simpleMessage("Common Name"),
    "pivCopyPem": MessageLookupByLibrary.simpleMessage("Copy PEM"),
    "pivCountryCode": MessageLookupByLibrary.simpleMessage(
      "Country or region code",
    ),
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
      "Create a certificate signing request (CSR) to send to a certificate authority. A new key will be generated on CanoKey.",
    ),
    "pivCsrSubject": MessageLookupByLibrary.simpleMessage("CSR Subject"),
    "pivDangerDescription": MessageLookupByLibrary.simpleMessage(
      "Before moving or deleting a key, make sure you have another way to sign in or decrypt your data.",
    ),
    "pivDangerZone": MessageLookupByLibrary.simpleMessage("Danger Zone"),
    "pivDelete": MessageLookupByLibrary.simpleMessage("Delete"),
    "pivDeleteSlot": m17,
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
          "A new management key will be set before the PIN-protected copy is cleared. PUK will remain blocked. To restore it, reset PIN/PUK retries after disabling this mode; this also resets the PIN.",
        ),
    "pivDisablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage(
          "Manual management key is now required",
        ),
    "pivDnsSans": MessageLookupByLibrary.simpleMessage(
      "Domain names (comma-separated)",
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
          "A random management key will be set and stored on the card, protected by PIN. PUK will be blocked and cannot recover a forgotten or blocked PIN. PIN/PUK retries cannot be reset while this mode is enabled.",
        ),
    "pivEnablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage(
          "Management key is now PIN-protected",
        ),
    "pivEndEntityConstraint": MessageLookupByLibrary.simpleMessage(
      "Mark as a non-CA certificate (CA=false)",
    ),
    "pivExport": MessageLookupByLibrary.simpleMessage("Export"),
    "pivExportCertificate": MessageLookupByLibrary.simpleMessage(
      "Export Certificate",
    ),
    "pivExportDescription": MessageLookupByLibrary.simpleMessage(
      "Save a certificate or public key to a file.",
    ),
    "pivExportPublicKey": MessageLookupByLibrary.simpleMessage(
      "Export Public Key",
    ),
    "pivExtendedAlgorithmCompatibilityWarning":
        MessageLookupByLibrary.simpleMessage(
          "Check that the software you plan to use supports this algorithm.",
        ),
    "pivExtendedKeyUsage": MessageLookupByLibrary.simpleMessage(
      "Extended Key Usage",
    ),
    "pivExtensionsDescription": MessageLookupByLibrary.simpleMessage(
      "Configure constraints, key usage and extended key usage.",
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
    "pivGeneratingKey": m18,
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
    "pivKeyOperationsDescription": MessageLookupByLibrary.simpleMessage(
      "Sign messages or files, or verify a file signature.",
    ),
    "pivKeyOptions": MessageLookupByLibrary.simpleMessage("Key Options"),
    "pivKeyUsage": MessageLookupByLibrary.simpleMessage("Key Usage"),
    "pivKeyUsageCritical": MessageLookupByLibrary.simpleMessage(
      "Require verifiers to check key usage",
    ),
    "pivMacLogin": MessageLookupByLibrary.simpleMessage("macOS login"),
    "pivMacLoginDescription": MessageLookupByLibrary.simpleMessage(
      "Sign in to macOS using your PIV certificates.",
    ),
    "pivMacOsAfterAuthentication": MessageLookupByLibrary.simpleMessage(
      "9A is configured. Next, check 9D: your Mac also needs its key and certificate to unlock your login keychain.",
    ),
    "pivMacOsAfterKeychain": MessageLookupByLibrary.simpleMessage(
      "9D is configured. Check that 9A is also configured, then reconnect CanoKey and pair it with your Mac account.",
    ),
    "pivMacOsApply": MessageLookupByLibrary.simpleMessage(
      "Apply Mac login settings",
    ),
    "pivMacOsAuthenticationSlot": MessageLookupByLibrary.simpleMessage(
      "9A · Sign in",
    ),
    "pivMacOsCheckSlot": m19,
    "pivMacOsDescription": MessageLookupByLibrary.simpleMessage(
      "Set up 9A to verify your identity when you sign in to your Mac. You also need a key and certificate in 9D to unlock your login keychain.",
    ),
    "pivMacOsGuide": MessageLookupByLibrary.simpleMessage(
      "Set up 9A to verify your identity and 9D to unlock your login keychain. Once both are configured, reconnect CanoKey and pair it with your Mac account.",
    ),
    "pivMacOsGuideTitle": MessageLookupByLibrary.simpleMessage(
      "Sign in to your Mac with CanoKey",
    ),
    "pivMacOsKeychainDescription": MessageLookupByLibrary.simpleMessage(
      "Set up 9D to unlock your Mac’s login keychain. Set up the login certificate in 9A as well.",
    ),
    "pivMacOsKeychainSlot": MessageLookupByLibrary.simpleMessage(
      "9D · Unlock keychain",
    ),
    "pivMacOsOtherSlot": MessageLookupByLibrary.simpleMessage(
      "For Mac login, set up 9A and 9D.",
    ),
    "pivMacOsSlotApplied": m20,
    "pivMacSetupConsent": MessageLookupByLibrary.simpleMessage(
      "I confirm the key or certificate replacements listed above. Replaced keys cannot be recovered.",
    ),
    "pivMacSetupCreate": MessageLookupByLibrary.simpleMessage(
      "Create key and certificate",
    ),
    "pivMacSetupCredentials": MessageLookupByLibrary.simpleMessage(
      "Enter your PIV PIN and management key.",
    ),
    "pivMacSetupDone": MessageLookupByLibrary.simpleMessage(
      "CanoKey setup is complete. Reconnect it and follow the macOS prompt to pair it with your login account.",
    ),
    "pivMacSetupError": MessageLookupByLibrary.simpleMessage(
      "Could not check or configure CanoKey. Check the connection, PIV PIN and management key, then try again. Completed changes are kept. This feature requires firmware that can report key information.",
    ),
    "pivMacSetupFinished": MessageLookupByLibrary.simpleMessage("Done"),
    "pivMacSetupInspect": MessageLookupByLibrary.simpleMessage("Check again"),
    "pivMacSetupIntro": MessageLookupByLibrary.simpleMessage(
      "Set up the keys and certificates needed for macOS login. Slots 9A and 9D will be checked, and compatible keys and certificates will be kept.",
    ),
    "pivMacSetupInvalid": MessageLookupByLibrary.simpleMessage(
      "Check the PIN and management key format.",
    ),
    "pivMacSetupIssue": MessageLookupByLibrary.simpleMessage(
      "Keep key; add certificate",
    ),
    "pivMacSetupKeep": MessageLookupByLibrary.simpleMessage(
      "Keep existing configuration",
    ),
    "pivMacSetupManagementKey": MessageLookupByLibrary.simpleMessage(
      "Management key (hex)",
    ),
    "pivMacSetupReplaceCert": MessageLookupByLibrary.simpleMessage(
      "Keep key; replace certificate",
    ),
    "pivMacSetupReplaceKey": MessageLookupByLibrary.simpleMessage(
      "Replace key and certificate",
    ),
    "pivMacSetupStart": MessageLookupByLibrary.simpleMessage(
      "Configure CanoKey",
    ),
    "pivMacSetupTitle": MessageLookupByLibrary.simpleMessage(
      "Set up macOS login",
    ),
    "pivMacSetupWorking": MessageLookupByLibrary.simpleMessage("Configuring"),
    "pivMainSlots": MessageLookupByLibrary.simpleMessage("Primary slots"),
    "pivManage": MessageLookupByLibrary.simpleMessage("Manage"),
    "pivManagementKey": MessageLookupByLibrary.simpleMessage("Management Key"),
    "pivManagementKeyAuthentication": MessageLookupByLibrary.simpleMessage(
      "Management key verification",
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
      "Could not move the key. Choose a destination slot with no key.",
    ),
    "pivMoveKeyFrom": m21,
    "pivMoveKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "Only the private key is moved. Certificates remain in their current slots.",
    ),
    "pivNameColumn": MessageLookupByLibrary.simpleMessage("Name"),
    "pivNewManagementKey": MessageLookupByLibrary.simpleMessage(
      "New Management Key",
    ),
    "pivNewPUK": MessageLookupByLibrary.simpleMessage("New PUK"),
    "pivNoCertificate": MessageLookupByLibrary.simpleMessage("No certificate"),
    "pivNoEmptyDestinationSlot": MessageLookupByLibrary.simpleMessage(
      "No empty slot is available to receive this key.",
    ),
    "pivNoFileSelected": MessageLookupByLibrary.simpleMessage(
      "No file selected",
    ),
    "pivNoPublicKeyAvailable": MessageLookupByLibrary.simpleMessage(
      "No public key available",
    ),
    "pivNotSelected": MessageLookupByLibrary.simpleMessage("Not selected"),
    "pivOccupiedSlots": m22,
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
    "pivOverwriteKeyPrompt": m23,
    "pivPageDescription": MessageLookupByLibrary.simpleMessage(
      "Manage PIV keys, certificates and PINs on CanoKey.",
    ),
    "pivPageTitle": MessageLookupByLibrary.simpleMessage("PIV"),
    "pivPinAndTouchPolicy": MessageLookupByLibrary.simpleMessage(
      "PIN and Touch Policy",
    ),
    "pivPinDescription": MessageLookupByLibrary.simpleMessage(
      "For user authentication",
    ),
    "pivPinManagement": MessageLookupByLibrary.simpleMessage("PIN Management"),
    "pivPinPolicy": MessageLookupByLibrary.simpleMessage("PIN Policy"),
    "pivPinPolicyAlways": MessageLookupByLibrary.simpleMessage("Always"),
    "pivPinPolicyChip": m24,
    "pivPinPolicyDefault": MessageLookupByLibrary.simpleMessage("Default"),
    "pivPinPolicyNever": MessageLookupByLibrary.simpleMessage("Never"),
    "pivPinPolicyOnce": MessageLookupByLibrary.simpleMessage("Once"),
    "pivPinProtectedKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "Verify with PIN",
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
    "pivProvisioningDescription": MessageLookupByLibrary.simpleMessage(
      "Generate or import keys and certificates for this slot.",
    ),
    "pivPublicKey": MessageLookupByLibrary.simpleMessage("Public Key"),
    "pivPukDescription": MessageLookupByLibrary.simpleMessage(
      "For unblocking the PIN",
    ),
    "pivPukRetries": MessageLookupByLibrary.simpleMessage("PUK retries"),
    "pivRandomManagementKey": MessageLookupByLibrary.simpleMessage(
      "Generate random",
    ),
    "pivRetired1": MessageLookupByLibrary.simpleMessage("Retired 1"),
    "pivRetired2": MessageLookupByLibrary.simpleMessage("Retired 2"),
    "pivRetiredSlot": m25,
    "pivRetiredSlots": MessageLookupByLibrary.simpleMessage(
      "Retired key slots",
    ),
    "pivRetries": m26,
    "pivRetriesRemaining": MessageLookupByLibrary.simpleMessage(
      "Attempts remaining",
    ),
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
      "Select the original file and its signature file first.",
    ),
    "pivSelectFileFirst": MessageLookupByLibrary.simpleMessage(
      "Select a file first.",
    ),
    "pivSelectFileHint": MessageLookupByLibrary.simpleMessage(
      "Private key files must not be password-protected.",
    ),
    "pivSelectFilePrompt": MessageLookupByLibrary.simpleMessage(
      "Choose a certificate or private key in PEM or DER format",
    ),
    "pivSelfSign": MessageLookupByLibrary.simpleMessage("Self-sign"),
    "pivSelfSignCertificate": MessageLookupByLibrary.simpleMessage(
      "Self-sign Certificate",
    ),
    "pivSelfSignedCertificateWarning": MessageLookupByLibrary.simpleMessage(
      "You may need to manually trust a self-signed certificate in the software that uses it. Check that the software accepts self-signed certificates.",
    ),
    "pivSetPinPukRetries": MessageLookupByLibrary.simpleMessage(
      "Set PIN/PUK Retries",
    ),
    "pivSetPinPukRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "This resets PIN to 123456 and PUK to 12345678. Disable PIN-protected management key mode first.",
    ),
    "pivSetRetriesFailed": MessageLookupByLibrary.simpleMessage(
      "Set retries failed",
    ),
    "pivSetRetriesMetadataFailed": MessageLookupByLibrary.simpleMessage(
      "Retry limits changed, but some management information could not be saved. The PIN is now 123456 and the PUK is 12345678. Read CanoKey again to check its state.",
    ),
    "pivSetRetriesSuccess": MessageLookupByLibrary.simpleMessage(
      "Retry limits changed. The PIN is now 123456 and the PUK is 12345678.",
    ),
    "pivSha256Fingerprint": MessageLookupByLibrary.simpleMessage(
      "SHA-256 Fingerprint",
    ),
    "pivSign": MessageLookupByLibrary.simpleMessage("Sign"),
    "pivSignFile": MessageLookupByLibrary.simpleMessage("Sign File"),
    "pivSignFilePrompt": MessageLookupByLibrary.simpleMessage(
      "Sign a file with this key. The signature is saved separately; the original file is not changed.",
    ),
    "pivSignMessage": MessageLookupByLibrary.simpleMessage("Sign Message"),
    "pivSignature": MessageLookupByLibrary.simpleMessage("Digital Signature"),
    "pivSignatureAlgorithm": MessageLookupByLibrary.simpleMessage(
      "Signature Algorithm",
    ),
    "pivSignatureFile": MessageLookupByLibrary.simpleMessage("Signature file"),
    "pivSignatureHex": MessageLookupByLibrary.simpleMessage("Signature (hex)"),
    "pivSignatureVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "Signature verification failed",
    ),
    "pivSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "Signature verified",
    ),
    "pivSlotAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "For sign-in verification. Choose a key algorithm that supports signing.",
    ),
    "pivSlotCardAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "For verifying the card\'s identity. Some uses do not require a PIN.",
    ),
    "pivSlotCertificateOnly": MessageLookupByLibrary.simpleMessage(
      "Certificate only",
    ),
    "pivSlotCleared": MessageLookupByLibrary.simpleMessage("Slot cleared"),
    "pivSlotColumn": MessageLookupByLibrary.simpleMessage("Slot"),
    "pivSlotKeyAndCertificate": MessageLookupByLibrary.simpleMessage(
      "Key + certificate",
    ),
    "pivSlotKeyManagementHint": MessageLookupByLibrary.simpleMessage(
      "For decryption or key agreement. X25519 supports key agreement only.",
    ),
    "pivSlotKeyOnly": MessageLookupByLibrary.simpleMessage("Key only"),
    "pivSlotRetiredHint": MessageLookupByLibrary.simpleMessage(
      "Keep old decryption keys and certificates so you can still read previously encrypted data.",
    ),
    "pivSlotSignatureHint": MessageLookupByLibrary.simpleMessage(
      "For digital signatures. By default, the PIN is required for every signature.",
    ),
    "pivSlots": MessageLookupByLibrary.simpleMessage("Slots"),
    "pivSlotsDescription": MessageLookupByLibrary.simpleMessage(
      "Each slot holds a key and certificate.",
    ),
    "pivSlotsHint": MessageLookupByLibrary.simpleMessage(
      "Select a slot to view or manage its certificate",
    ),
    "pivSlotsTitle": MessageLookupByLibrary.simpleMessage("Certificate slots"),
    "pivStatusBlocked": MessageLookupByLibrary.simpleMessage("Blocked"),
    "pivStatusConfigured": MessageLookupByLibrary.simpleMessage("Configured"),
    "pivStatusEmpty": MessageLookupByLibrary.simpleMessage("Not configured"),
    "pivStatusReady": MessageLookupByLibrary.simpleMessage("Ready"),
    "pivStatusUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "pivStoreManagementKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "Store the new management key on this card",
    ),
    "pivStoreManagementKeyOnCardPrompt": MessageLookupByLibrary.simpleMessage(
      "When enabled, future management operations can authenticate with PIN. This blocks PUK and prevents PIN recovery with PUK.",
    ),
    "pivSubjectDescription": MessageLookupByLibrary.simpleMessage(
      "Enter the certificate holder\'s name, organization and other details.",
    ),
    "pivTouchPolicy": MessageLookupByLibrary.simpleMessage("Touch Policy"),
    "pivTouchPolicyAlways": MessageLookupByLibrary.simpleMessage("Always"),
    "pivTouchPolicyCached": MessageLookupByLibrary.simpleMessage(
      "Cached for 15 seconds",
    ),
    "pivTouchPolicyChip": m27,
    "pivTouchPolicyDefault": MessageLookupByLibrary.simpleMessage("Default"),
    "pivTouchPolicyNever": MessageLookupByLibrary.simpleMessage("Never"),
    "pivTransfer": MessageLookupByLibrary.simpleMessage("Import / export"),
    "pivUnblockPin": MessageLookupByLibrary.simpleMessage("Unblock PIN"),
    "pivUnblockPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Enter the current PUK and set a new PIN.",
    ),
    "pivUnsupportedImportFile": MessageLookupByLibrary.simpleMessage(
      "Unsupported file. Use PEM or DER certificate/private key files.",
    ),
    "pivUsageClientAuth": MessageLookupByLibrary.simpleMessage(
      "Client authentication",
    ),
    "pivUsageCodeSigning": MessageLookupByLibrary.simpleMessage("Code signing"),
    "pivUsageContentCommitment": MessageLookupByLibrary.simpleMessage(
      "Content commitment",
    ),
    "pivUsageDataEncipherment": MessageLookupByLibrary.simpleMessage(
      "Data encryption",
    ),
    "pivUsageDigitalSignature": MessageLookupByLibrary.simpleMessage(
      "Digital signature",
    ),
    "pivUsageEmailProtection": MessageLookupByLibrary.simpleMessage(
      "Email protection",
    ),
    "pivUsageKeyAgreement": MessageLookupByLibrary.simpleMessage(
      "Key agreement",
    ),
    "pivUsageKeyEncipherment": MessageLookupByLibrary.simpleMessage(
      "Key encryption",
    ),
    "pivUsageOmitted": MessageLookupByLibrary.simpleMessage(
      "Leave all options unchecked to omit this usage restriction.",
    ),
    "pivUsageServerAuth": MessageLookupByLibrary.simpleMessage(
      "Server authentication",
    ),
    "pivUsageSmartCardLogon": MessageLookupByLibrary.simpleMessage(
      "Smart card login",
    ),
    "pivUseDefaultManagementKey": MessageLookupByLibrary.simpleMessage(
      "Use default",
    ),
    "pivValidityDays": MessageLookupByLibrary.simpleMessage("Validity Days"),
    "pivVerify": MessageLookupByLibrary.simpleMessage("Verify"),
    "pivVerifyFile": MessageLookupByLibrary.simpleMessage("Verify File"),
    "pivVerifyFileSignature": MessageLookupByLibrary.simpleMessage(
      "Verify File Signature",
    ),
    "pivVerifyFileSignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "Select the original file and its signature file to verify the signature using this slot\'s public key.",
    ),
    "pivVerifyManagementKey": MessageLookupByLibrary.simpleMessage(
      "Verify Management Key",
    ),
    "pivVerifyPinAndManagementKey": MessageLookupByLibrary.simpleMessage(
      "Enter PIN and management key",
    ),
    "pivViewCertificate": MessageLookupByLibrary.simpleMessage(
      "View certificate",
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
    "privacyConsentAfterLink": MessageLookupByLibrary.simpleMessage(
      " before continuing. We collect, use, and protect your personal information in accordance with the policy.",
    ),
    "privacyConsentBeforeLink": MessageLookupByLibrary.simpleMessage(
      "Thank you for using CanoKey Console. Please read and agree to our ",
    ),
    "privacyConsentTitle": MessageLookupByLibrary.simpleMessage(
      "Privacy Policy",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "readingAlertMessage": MessageLookupByLibrary.simpleMessage(
      "Keep CanoKey near your phone until reading finishes.",
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
      "Storage used by each applet",
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
    "settingsCoreCommit": MessageLookupByLibrary.simpleMessage(
      "Firmware source revision",
    ),
    "settingsDescription": MessageLookupByLibrary.simpleMessage(
      "View CanoKey information and change device and app settings.",
    ),
    "settingsDeviceActions": MessageLookupByLibrary.simpleMessage(
      "Device Actions",
    ),
    "settingsDeviceSettings": MessageLookupByLibrary.simpleMessage(
      "Device Settings",
    ),
    "settingsFirmwareVersion": MessageLookupByLibrary.simpleMessage(
      "Firmware Version",
    ),
    "settingsFixNFC": MessageLookupByLibrary.simpleMessage("Fix NFC"),
    "settingsFixNFCSuccess": MessageLookupByLibrary.simpleMessage(
      "NFC is successfully fixed",
    ),
    "settingsHotp": MessageLookupByLibrary.simpleMessage("Type HOTP on touch"),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("CanoKey Info"),
    "settingsInputPin": MessageLookupByLibrary.simpleMessage(
      "PIN Verification",
    ),
    "settingsInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Enter the admin PIN used for Settings. The default is 123456. It is separate from the PINs for OpenPGP, PIV and other applets.",
    ),
    "settingsKeyboardLayout": MessageLookupByLibrary.simpleMessage(
      "Keyboard Layout",
    ),
    "settingsKeyboardLayoutCurrent": m28,
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
      "Your current keyboard layout is custom. Selecting a built-in layout will replace it.",
    ),
    "settingsKeyboardWithReturn": MessageLookupByLibrary.simpleMessage(
      "Press Enter after typing an OTP",
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
    "settingsResetApplet": m29,
    "settingsResetConditionNotSatisfying": MessageLookupByLibrary.simpleMessage(
      "Cannot reset while the PIN is not blocked.",
    ),
    "settingsResetFailed": MessageLookupByLibrary.simpleMessage(
      "Reset failed. Check the device connection and try again.",
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
      "CanoKey was not touched in time. Try again and touch it when the light flashes.",
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
      "Show WebUSB prompt when connected",
    ),
    "sm2AlgorithmId": MessageLookupByLibrary.simpleMessage("Algorithm ID"),
    "sm2CurveId": MessageLookupByLibrary.simpleMessage("Curve ID"),
    "sm2ReservedId": MessageLookupByLibrary.simpleMessage(
      "This ID is reserved for another algorithm or curve. Choose a different value.",
    ),
    "soundCredit": MessageLookupByLibrary.simpleMessage(
      "NFC sounds by Summer Xu.",
    ),
    "storageFull": MessageLookupByLibrary.simpleMessage(
      "CanoKey storage is full.",
    ),
    "successfullyChanged": MessageLookupByLibrary.simpleMessage(
      "Successfully changed",
    ),
    "validationAtLeastCharacters": m30,
    "validationAtMostCharacters": m31,
    "validationExactLength": m32,
    "validationHexString": MessageLookupByLibrary.simpleMessage(
      "Please input a valid hexadecimal string.",
    ),
    "validationNumber": MessageLookupByLibrary.simpleMessage(
      "Enter a whole number.",
    ),
    "validationNumberMax": m33,
    "validationNumberMin": m34,
    "viewUserId": MessageLookupByLibrary.simpleMessage("View User ID"),
    "warning": MessageLookupByLibrary.simpleMessage("Warning"),
    "webAuthnCredentials": MessageLookupByLibrary.simpleMessage(
      "WebAuthn Credentials",
    ),
    "webAuthnDescription": MessageLookupByLibrary.simpleMessage(
      "Manage WebAuthn sign-in credentials stored on your CanoKey.",
    ),
    "webAuthnMissingCredentials": MessageLookupByLibrary.simpleMessage(
      "Why can\'t I see my credentials?",
    ),
    "webAuthnMissingCredentialsExplanation": MessageLookupByLibrary.simpleMessage(
      "This list shows credentials CanoKey can find on its own. Some credentials can only be identified when a website starts sign-in, so they do not appear here. You can still use them to sign in.",
    ),
    "webAuthnSearch": MessageLookupByLibrary.simpleMessage(
      "Search WebAuthn credentials…",
    ),
    "webPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "Insert your CanoKey into the USB port and click the refresh button",
    ),
    "webauthnChangePinFailed": MessageLookupByLibrary.simpleMessage(
      "Could not change the WebAuthn PIN. Read CanoKey again and try again.",
    ),
    "webauthnClientPinNotSupported": MessageLookupByLibrary.simpleMessage(
      "This CanoKey does not support a WebAuthn PIN.",
    ),
    "webauthnDelete": m35,
    "webauthnInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Please input your WebAuthn PIN.",
    ),
    "webauthnInputPinTitle": MessageLookupByLibrary.simpleMessage(
      "Unlock WebAuthn",
    ),
    "webauthnPinAuthBlocked": MessageLookupByLibrary.simpleMessage(
      "The WebAuthn PIN is temporarily blocked. Reconnect CanoKey and try again.",
    ),
    "webauthnPinBlocked": MessageLookupByLibrary.simpleMessage(
      "The WebAuthn PIN is blocked. Reset WebAuthn to use it again. Resetting deletes all WebAuthn credentials.",
    ),
    "webauthnPinRequired": MessageLookupByLibrary.simpleMessage(
      "Refresh the page and enter your WebAuthn PIN before trying this operation again.",
    ),
    "webauthnSetPinFailed": MessageLookupByLibrary.simpleMessage(
      "Could not set the WebAuthn PIN. Read CanoKey again and try again.",
    ),
    "webauthnSetPinPrompt": MessageLookupByLibrary.simpleMessage(
      "Set a WebAuthn PIN to manage sign-in credentials. Use 4 to 63 characters.",
    ),
    "webauthnSetPinTitle": MessageLookupByLibrary.simpleMessage(
      "Set WebAuthn PIN",
    ),
  };
}
