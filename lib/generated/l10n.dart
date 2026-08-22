// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Applets`
  String get applets {
    return Intl.message('Applets', name: 'applets', desc: '', args: []);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Other`
  String get other {
    return Intl.message('Other', name: 'other', desc: '', args: []);
  }

  /// `About`
  String get about {
    return Intl.message('About', name: 'about', desc: '', args: []);
  }

  /// `CanoKey Console`
  String get homeScreenTitle {
    return Intl.message(
      'CanoKey Console',
      name: 'homeScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Press`
  String get homePress {
    return Intl.message('Press', name: 'homePress', desc: '', args: []);
  }

  /// `to select an applet`
  String get homeSelect {
    return Intl.message(
      'to select an applet',
      name: 'homeSelect',
      desc: '',
      args: [],
    );
  }

  /// `Select an applet to start`
  String get homeDirectlySelect {
    return Intl.message(
      'Select an applet to start',
      name: 'homeDirectlySelect',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Close`
  String get close {
    return Intl.message('Close', name: 'close', desc: '', args: []);
  }

  /// `Please read your CanoKey by clicking the refresh button`
  String get pollCanoKey {
    return Intl.message(
      'Please read your CanoKey by clicking the refresh button',
      name: 'pollCanoKey',
      desc: '',
      args: [],
    );
  }

  /// `Tap your CanoKey or insert it into the USB port`
  String get androidPollCanoKeyPrompt {
    return Intl.message(
      'Tap your CanoKey or insert it into the USB port',
      name: 'androidPollCanoKeyPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Insert your CanoKey into the USB port`
  String get desktopPollCanoKeyPrompt {
    return Intl.message(
      'Insert your CanoKey into the USB port',
      name: 'desktopPollCanoKeyPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Tap the refresh button and tap your CanoKey or insert it into the USB port`
  String get iosPollCanoKeyPrompt {
    return Intl.message(
      'Tap the refresh button and tap your CanoKey or insert it into the USB port',
      name: 'iosPollCanoKeyPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Insert your CanoKey into the USB port and click the refresh button`
  String get webPollCanoKeyPrompt {
    return Intl.message(
      'Insert your CanoKey into the USB port and click the refresh button',
      name: 'webPollCanoKeyPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Error finding CanoKey connected via USB. Please fix the problem and restart this app:`
  String get desktopPollError {
    return Intl.message(
      'Error finding CanoKey connected via USB. Please fix the problem and restart this app:',
      name: 'desktopPollError',
      desc: '',
      args: [],
    );
  }

  /// `No CanoKey is selected.`
  String get pollCanceled {
    return Intl.message(
      'No CanoKey is selected.',
      name: 'pollCanceled',
      desc: '',
      args: [],
    );
  }

  /// `CanoKey is busy. Replug it, wait for a moment, and retry.`
  String get networkError {
    return Intl.message(
      'CanoKey is busy. Replug it, wait for a moment, and retry.',
      name: 'networkError',
      desc: '',
      args: [],
    );
  }

  /// `CanoKey storage is full.`
  String get storageFull {
    return Intl.message(
      'CanoKey storage is full.',
      name: 'storageFull',
      desc: '',
      args: [],
    );
  }

  /// `This applet has been locked.`
  String get appletLocked {
    return Intl.message(
      'This applet has been locked.',
      name: 'appletLocked',
      desc: '',
      args: [],
    );
  }

  /// `{applet} is disabled. Enable it in Settings first.`
  String appletDisabled(Object applet) {
    return Intl.message(
      '$applet is disabled. Enable it in Settings first.',
      name: 'appletDisabled',
      desc: '',
      args: [applet],
    );
  }

  /// `Incorrect PIN.`
  String get pinIncorrect {
    return Intl.message(
      'Incorrect PIN.',
      name: 'pinIncorrect',
      desc: '',
      args: [],
    );
  }

  /// `Incorrect PIN. {retries} retries left.`
  String pinRetries(Object retries) {
    return Intl.message(
      'Incorrect PIN. $retries retries left.',
      name: 'pinRetries',
      desc: '',
      args: [retries],
    );
  }

  /// `The provided PIN is too short or too long.`
  String get pinLength {
    return Intl.message(
      'The provided PIN is too short or too long.',
      name: 'pinLength',
      desc: '',
      args: [],
    );
  }

  /// `seconds`
  String get seconds {
    return Intl.message('seconds', name: 'seconds', desc: '', args: []);
  }

  /// `Change`
  String get change {
    return Intl.message('Change', name: 'change', desc: '', args: []);
  }

  /// `Current PIN`
  String get oldPin {
    return Intl.message('Current PIN', name: 'oldPin', desc: '', args: []);
  }

  /// `New PIN`
  String get newPin {
    return Intl.message('New PIN', name: 'newPin', desc: '', args: []);
  }

  /// `Actions`
  String get actions {
    return Intl.message('Actions', name: 'actions', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Confirm`
  String get confirm {
    return Intl.message('Confirm', name: 'confirm', desc: '', args: []);
  }

  /// `On`
  String get on {
    return Intl.message('On', name: 'on', desc: '', args: []);
  }

  /// `Off`
  String get off {
    return Intl.message('Off', name: 'off', desc: '', args: []);
  }

  /// `Successfully changed`
  String get successfullyChanged {
    return Intl.message(
      'Successfully changed',
      name: 'successfullyChanged',
      desc: '',
      args: [],
    );
  }

  /// `Change PIN`
  String get changePin {
    return Intl.message('Change PIN', name: 'changePin', desc: '', args: []);
  }

  /// `New PIN should be at least {min} characters long. The maximum length is {max}.`
  String changePinPrompt(Object min, Object max) {
    return Intl.message(
      'New PIN should be at least $min characters long. The maximum length is $max.',
      name: 'changePinPrompt',
      desc: '',
      args: [min, max],
    );
  }

  /// `PIN has been successfully changed.`
  String get pinChanged {
    return Intl.message(
      'PIN has been successfully changed.',
      name: 'pinChanged',
      desc: '',
      args: [],
    );
  }

  /// `Invalid length`
  String get pinInvalidLength {
    return Intl.message(
      'Invalid length',
      name: 'pinInvalidLength',
      desc: '',
      args: [],
    );
  }

  /// `Warning`
  String get warning {
    return Intl.message('Warning', name: 'warning', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Successfully deleted`
  String get deleted {
    return Intl.message(
      'Successfully deleted',
      name: 'deleted',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Reset`
  String get reset {
    return Intl.message('Reset', name: 'reset', desc: '', args: []);
  }

  /// `Please connect your CanoKey first.`
  String get connectFirst {
    return Intl.message(
      'Please connect your CanoKey first.',
      name: 'connectFirst',
      desc: '',
      args: [],
    );
  }

  /// `Copied`
  String get copied {
    return Intl.message('Copied', name: 'copied', desc: '', args: []);
  }

  /// `Enabled`
  String get enabled {
    return Intl.message('Enabled', name: 'enabled', desc: '', args: []);
  }

  /// `No credential`
  String get noCredential {
    return Intl.message(
      'No credential',
      name: 'noCredential',
      desc: '',
      args: [],
    );
  }

  /// `No matching credential found`
  String get noMatchingCredential {
    return Intl.message(
      'No matching credential found',
      name: 'noMatchingCredential',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get search {
    return Intl.message('Search', name: 'search', desc: '', args: []);
  }

  /// `Hold your iPhone near the CanoKey`
  String get iosAlertMessage {
    return Intl.message(
      'Hold your iPhone near the CanoKey',
      name: 'iosAlertMessage',
      desc: '',
      args: [],
    );
  }

  /// `Touch your CanoKey`
  String get androidAlertTitle {
    return Intl.message(
      'Touch your CanoKey',
      name: 'androidAlertTitle',
      desc: '',
      args: [],
    );
  }

  /// `Hold the CanoKey until finished`
  String get readingAlertMessage {
    return Intl.message(
      'Hold the CanoKey until finished',
      name: 'readingAlertMessage',
      desc: '',
      args: [],
    );
  }

  /// `Communication interrupted. Try to hold the CanoKey until finished.`
  String get interrupted {
    return Intl.message(
      'Communication interrupted. Try to hold the CanoKey until finished.',
      name: 'interrupted',
      desc: '',
      args: [],
    );
  }

  /// `CanoKey not found`
  String get noCard {
    return Intl.message(
      'CanoKey not found',
      name: 'noCard',
      desc: '',
      args: [],
    );
  }

  /// `Your browser does not support WebUSB`
  String get browserNotSupported {
    return Intl.message(
      'Your browser does not support WebUSB',
      name: 'browserNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `Not supported`
  String get notSupported {
    return Intl.message(
      'Not supported',
      name: 'notSupported',
      desc: '',
      args: [],
    );
  }

  /// `Not supported in NFC mode`
  String get notSupportedInNFC {
    return Intl.message(
      'Not supported in NFC mode',
      name: 'notSupportedInNFC',
      desc: '',
      args: [],
    );
  }

  /// `Card Info`
  String get openpgpCardInfo {
    return Intl.message(
      'Card Info',
      name: 'openpgpCardInfo',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get openpgpVersion {
    return Intl.message('Version', name: 'openpgpVersion', desc: '', args: []);
  }

  /// `Manufacturer`
  String get openpgpManufacturer {
    return Intl.message(
      'Manufacturer',
      name: 'openpgpManufacturer',
      desc: '',
      args: [],
    );
  }

  /// `Serial Number`
  String get openpgpSN {
    return Intl.message('Serial Number', name: 'openpgpSN', desc: '', args: []);
  }

  /// `Card Holder`
  String get openpgpCardHolder {
    return Intl.message(
      'Card Holder',
      name: 'openpgpCardHolder',
      desc: '',
      args: [],
    );
  }

  /// `Public Key URL`
  String get openpgpPubkeyUrl {
    return Intl.message(
      'Public Key URL',
      name: 'openpgpPubkeyUrl',
      desc: '',
      args: [],
    );
  }

  /// `Keys`
  String get openpgpKeys {
    return Intl.message('Keys', name: 'openpgpKeys', desc: '', args: []);
  }

  /// `Signature`
  String get openpgpSignature {
    return Intl.message(
      'Signature',
      name: 'openpgpSignature',
      desc: '',
      args: [],
    );
  }

  /// `Encryption`
  String get openpgpEncryption {
    return Intl.message(
      'Encryption',
      name: 'openpgpEncryption',
      desc: '',
      args: [],
    );
  }

  /// `Authentication`
  String get openpgpAuthentication {
    return Intl.message(
      'Authentication',
      name: 'openpgpAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `Touch Policies`
  String get openpgpUIF {
    return Intl.message(
      'Touch Policies',
      name: 'openpgpUIF',
      desc: '',
      args: [],
    );
  }

  /// `Off`
  String get openpgpUifOff {
    return Intl.message('Off', name: 'openpgpUifOff', desc: '', args: []);
  }

  /// `On`
  String get openpgpUifOn {
    return Intl.message('On', name: 'openpgpUifOn', desc: '', args: []);
  }

  /// `Permanent (Cannot turn off)`
  String get openpgpUifPermanent {
    return Intl.message(
      'Permanent (Cannot turn off)',
      name: 'openpgpUifPermanent',
      desc: '',
      args: [],
    );
  }

  /// `Touch Cache Time`
  String get openpgpUifCacheTime {
    return Intl.message(
      'Touch Cache Time',
      name: 'openpgpUifCacheTime',
      desc: '',
      args: [],
    );
  }

  /// `Change Admin PIN`
  String get openpgpChangeAdminPin {
    return Intl.message(
      'Change Admin PIN',
      name: 'openpgpChangeAdminPin',
      desc: '',
      args: [],
    );
  }

  /// `Change Touch Cache Time`
  String get openpgpChangeTouchCacheTime {
    return Intl.message(
      'Change Touch Cache Time',
      name: 'openpgpChangeTouchCacheTime',
      desc: '',
      args: [],
    );
  }

  /// `Touch policy has been successfully changed.`
  String get openpgpUifChanged {
    return Intl.message(
      'Touch policy has been successfully changed.',
      name: 'openpgpUifChanged',
      desc: '',
      args: [],
    );
  }

  /// `Touch cache time has been successfully changed.`
  String get openpgpUifCacheTimeChanged {
    return Intl.message(
      'Touch cache time has been successfully changed.',
      name: 'openpgpUifCacheTimeChanged',
      desc: '',
      args: [],
    );
  }

  /// `Change {keyType} Key's Touch Policy`
  String openpgpChangeInteraction(Object keyType) {
    return Intl.message(
      'Change $keyType Key\'s Touch Policy',
      name: 'openpgpChangeInteraction',
      desc: '',
      args: [keyType],
    );
  }

  /// `[none]`
  String get openpgpKeyNone {
    return Intl.message('[none]', name: 'openpgpKeyNone', desc: '', args: []);
  }

  /// `CanoKey Info`
  String get settingsInfo {
    return Intl.message(
      'CanoKey Info',
      name: 'settingsInfo',
      desc: '',
      args: [],
    );
  }

  /// `Other Settings`
  String get settingsOtherSettings {
    return Intl.message(
      'Other Settings',
      name: 'settingsOtherSettings',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get settingsLanguage {
    return Intl.message(
      'Language',
      name: 'settingsLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Model`
  String get settingsModel {
    return Intl.message('Model', name: 'settingsModel', desc: '', args: []);
  }

  /// `Firmware Version`
  String get settingsFirmwareVersion {
    return Intl.message(
      'Firmware Version',
      name: 'settingsFirmwareVersion',
      desc: '',
      args: [],
    );
  }

  /// `Core Commit`
  String get settingsCoreCommit {
    return Intl.message(
      'Core Commit',
      name: 'settingsCoreCommit',
      desc: '',
      args: [],
    );
  }

  /// `Serial Number`
  String get settingsSN {
    return Intl.message(
      'Serial Number',
      name: 'settingsSN',
      desc: '',
      args: [],
    );
  }

  /// `Chip ID`
  String get settingsChipId {
    return Intl.message('Chip ID', name: 'settingsChipId', desc: '', args: []);
  }

  /// `Storage Usage`
  String get settingsStorageUsage {
    return Intl.message(
      'Storage Usage',
      name: 'settingsStorageUsage',
      desc: '',
      args: [],
    );
  }

  /// `Applet Flash Usage`
  String get settingsAppletStorageUsage {
    return Intl.message(
      'Applet Flash Usage',
      name: 'settingsAppletStorageUsage',
      desc: '',
      args: [],
    );
  }

  /// `Free`
  String get settingsStorageFree {
    return Intl.message(
      'Free',
      name: 'settingsStorageFree',
      desc: '',
      args: [],
    );
  }

  /// `PIN Verification`
  String get settingsInputPin {
    return Intl.message(
      'PIN Verification',
      name: 'settingsInputPin',
      desc: '',
      args: [],
    );
  }

  /// `Please input your admin PIN. The default value is 123456. This PIN is irrelevant to other applets.`
  String get settingsInputPinPrompt {
    return Intl.message(
      'Please input your admin PIN. The default value is 123456. This PIN is irrelevant to other applets.',
      name: 'settingsInputPinPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Input HOTP when touching`
  String get settingsHotp {
    return Intl.message(
      'Input HOTP when touching',
      name: 'settingsHotp',
      desc: '',
      args: [],
    );
  }

  /// `WebUSB prompt when plug-in`
  String get settingsWebUSB {
    return Intl.message(
      'WebUSB prompt when plug-in',
      name: 'settingsWebUSB',
      desc: '',
      args: [],
    );
  }

  /// `Applet Switches`
  String get settingsAppletSwitches {
    return Intl.message(
      'Applet Switches',
      name: 'settingsAppletSwitches',
      desc: '',
      args: [],
    );
  }

  /// `Pass`
  String get settingsPassApplet {
    return Intl.message('Pass', name: 'settingsPassApplet', desc: '', args: []);
  }

  /// `OpenPGP (CCID)`
  String get settingsOpenPgpCcId {
    return Intl.message(
      'OpenPGP (CCID)',
      name: 'settingsOpenPgpCcId',
      desc: '',
      args: [],
    );
  }

  /// `OpenPGP (NFC)`
  String get settingsOpenPgpNfc {
    return Intl.message(
      'OpenPGP (NFC)',
      name: 'settingsOpenPgpNfc',
      desc: '',
      args: [],
    );
  }

  /// `PIV (CCID)`
  String get settingsPivCcId {
    return Intl.message(
      'PIV (CCID)',
      name: 'settingsPivCcId',
      desc: '',
      args: [],
    );
  }

  /// `PIV (NFC)`
  String get settingsPivNfc {
    return Intl.message(
      'PIV (NFC)',
      name: 'settingsPivNfc',
      desc: '',
      args: [],
    );
  }

  /// `WebAuthn`
  String get settingsWebAuthnApplet {
    return Intl.message(
      'WebAuthn',
      name: 'settingsWebAuthnApplet',
      desc: '',
      args: [],
    );
  }

  /// `NFC Tag Mode (NDEF)`
  String get settingsNDEF {
    return Intl.message(
      'NFC Tag Mode (NDEF)',
      name: 'settingsNDEF',
      desc: '',
      args: [],
    );
  }

  /// `NFC Tag Readonly`
  String get settingsNDEFReadonly {
    return Intl.message(
      'NFC Tag Readonly',
      name: 'settingsNDEFReadonly',
      desc: '',
      args: [],
    );
  }

  /// `NFC tag content`
  String get ndefTagContent {
    return Intl.message(
      'NFC tag content',
      name: 'ndefTagContent',
      desc: '',
      args: [],
    );
  }

  /// `Configure the records shared when another device scans this CanoKey.`
  String get ndefTagContentDescription {
    return Intl.message(
      'Configure the records shared when another device scans this CanoKey.',
      name: 'ndefTagContentDescription',
      desc: '',
      args: [],
    );
  }

  /// `Records`
  String get ndefRecords {
    return Intl.message('Records', name: 'ndefRecords', desc: '', args: []);
  }

  /// `Add record`
  String get ndefAddRecord {
    return Intl.message(
      'Add record',
      name: 'ndefAddRecord',
      desc: '',
      args: [],
    );
  }

  /// `URI`
  String get ndefUri {
    return Intl.message('URI', name: 'ndefUri', desc: '', args: []);
  }

  /// `Text`
  String get ndefText {
    return Intl.message('Text', name: 'ndefText', desc: '', args: []);
  }

  /// `URI`
  String get ndefUriValue {
    return Intl.message('URI', name: 'ndefUriValue', desc: '', args: []);
  }

  /// `Text content`
  String get ndefTextValue {
    return Intl.message(
      'Text content',
      name: 'ndefTextValue',
      desc: '',
      args: [],
    );
  }

  /// `Language code`
  String get ndefLanguage {
    return Intl.message(
      'Language code',
      name: 'ndefLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Text encoding`
  String get ndefEncoding {
    return Intl.message(
      'Text encoding',
      name: 'ndefEncoding',
      desc: '',
      args: [],
    );
  }

  /// `Enter a URI with a scheme, such as https:// or mailto:.`
  String get ndefInvalidUri {
    return Intl.message(
      'Enter a URI with a scheme, such as https:// or mailto:.',
      name: 'ndefInvalidUri',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid language code, such as en or zh-Hans.`
  String get ndefInvalidLanguage {
    return Intl.message(
      'Enter a valid language code, such as en or zh-Hans.',
      name: 'ndefInvalidLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Edit record`
  String get ndefEditRecord {
    return Intl.message(
      'Edit record',
      name: 'ndefEditRecord',
      desc: '',
      args: [],
    );
  }

  /// `Move up`
  String get ndefMoveUp {
    return Intl.message('Move up', name: 'ndefMoveUp', desc: '', args: []);
  }

  /// `Move down`
  String get ndefMoveDown {
    return Intl.message('Move down', name: 'ndefMoveDown', desc: '', args: []);
  }

  /// `No NDEF records`
  String get ndefNoRecords {
    return Intl.message(
      'No NDEF records',
      name: 'ndefNoRecords',
      desc: '',
      args: [],
    );
  }

  /// `Add a URI or text record to make the tag discoverable.`
  String get ndefNoRecordsDescription {
    return Intl.message(
      'Add a URI or text record to make the tag discoverable.',
      name: 'ndefNoRecordsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Capacity`
  String get ndefCapacity {
    return Intl.message('Capacity', name: 'ndefCapacity', desc: '', args: []);
  }

  /// `{used} of {total} bytes`
  String ndefBytesUsed(Object used, Object total) {
    return Intl.message(
      '$used of $total bytes',
      name: 'ndefBytesUsed',
      desc: '',
      args: [used, total],
    );
  }

  /// `Writable`
  String get ndefWritable {
    return Intl.message('Writable', name: 'ndefWritable', desc: '', args: []);
  }

  /// `Read-only`
  String get ndefReadOnlyStatus {
    return Intl.message(
      'Read-only',
      name: 'ndefReadOnlyStatus',
      desc: '',
      args: [],
    );
  }

  /// `The NDEF tag is read-only.`
  String get ndefReadOnly {
    return Intl.message(
      'The NDEF tag is read-only.',
      name: 'ndefReadOnly',
      desc: '',
      args: [],
    );
  }

  /// `Writing is disabled. Turn off NFC Tag Readonly in Settings to edit these records.`
  String get ndefReadOnlyDescription {
    return Intl.message(
      'Writing is disabled. Turn off NFC Tag Readonly in Settings to edit these records.',
      name: 'ndefReadOnlyDescription',
      desc: '',
      args: [],
    );
  }

  /// `The stored message is not valid NDEF data. Reset NDEF in Settings before editing it.`
  String get ndefInvalidMessage {
    return Intl.message(
      'The stored message is not valid NDEF data. Reset NDEF in Settings before editing it.',
      name: 'ndefInvalidMessage',
      desc: '',
      args: [],
    );
  }

  /// `The message exceeds the NDEF capacity.`
  String get ndefCapacityExceeded {
    return Intl.message(
      'The message exceeds the NDEF capacity.',
      name: 'ndefCapacityExceeded',
      desc: '',
      args: [],
    );
  }

  /// `NDEF records saved`
  String get ndefSaved {
    return Intl.message(
      'NDEF records saved',
      name: 'ndefSaved',
      desc: '',
      args: [],
    );
  }

  /// `Save to CanoKey`
  String get ndefSaveToKey {
    return Intl.message(
      'Save to CanoKey',
      name: 'ndefSaveToKey',
      desc: '',
      args: [],
    );
  }

  /// `Unsaved changes`
  String get ndefUnsavedChanges {
    return Intl.message(
      'Unsaved changes',
      name: 'ndefUnsavedChanges',
      desc: '',
      args: [],
    );
  }

  /// `Record type`
  String get ndefRecordType {
    return Intl.message(
      'Record type',
      name: 'ndefRecordType',
      desc: '',
      args: [],
    );
  }

  /// `Smart Poster`
  String get ndefSmartPoster {
    return Intl.message(
      'Smart Poster',
      name: 'ndefSmartPoster',
      desc: '',
      args: [],
    );
  }

  /// `MIME`
  String get ndefMime {
    return Intl.message('MIME', name: 'ndefMime', desc: '', args: []);
  }

  /// `Wi-Fi`
  String get ndefWifi {
    return Intl.message('Wi-Fi', name: 'ndefWifi', desc: '', args: []);
  }

  /// `Bluetooth Classic`
  String get ndefBluetoothClassic {
    return Intl.message(
      'Bluetooth Classic',
      name: 'ndefBluetoothClassic',
      desc: '',
      args: [],
    );
  }

  /// `Bluetooth Low Energy`
  String get ndefBluetoothLowEnergy {
    return Intl.message(
      'Bluetooth Low Energy',
      name: 'ndefBluetoothLowEnergy',
      desc: '',
      args: [],
    );
  }

  /// `Absolute URI`
  String get ndefAbsoluteUri {
    return Intl.message(
      'Absolute URI',
      name: 'ndefAbsoluteUri',
      desc: '',
      args: [],
    );
  }

  /// `External type`
  String get ndefExternal {
    return Intl.message(
      'External type',
      name: 'ndefExternal',
      desc: '',
      args: [],
    );
  }

  /// `AAR`
  String get ndefAndroidApplication {
    return Intl.message(
      'AAR',
      name: 'ndefAndroidApplication',
      desc: '',
      args: [],
    );
  }

  /// `Device Information`
  String get ndefDeviceInformation {
    return Intl.message(
      'Device Information',
      name: 'ndefDeviceInformation',
      desc: '',
      args: [],
    );
  }

  /// `Signature`
  String get ndefSignature {
    return Intl.message('Signature', name: 'ndefSignature', desc: '', args: []);
  }

  /// `Connection Handover`
  String get ndefHandover {
    return Intl.message(
      'Connection Handover',
      name: 'ndefHandover',
      desc: '',
      args: [],
    );
  }

  /// `Custom record`
  String get ndefCustom {
    return Intl.message(
      'Custom record',
      name: 'ndefCustom',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get ndefPhone {
    return Intl.message('Phone', name: 'ndefPhone', desc: '', args: []);
  }

  /// `Contact`
  String get ndefContact {
    return Intl.message('Contact', name: 'ndefContact', desc: '', args: []);
  }

  /// `Other`
  String get ndefOther {
    return Intl.message('Other', name: 'ndefOther', desc: '', args: []);
  }

  /// `Phone number`
  String get ndefPhoneNumber {
    return Intl.message(
      'Phone number',
      name: 'ndefPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get ndefContactName {
    return Intl.message('Name', name: 'ndefContactName', desc: '', args: []);
  }

  /// `Email (optional)`
  String get ndefContactEmail {
    return Intl.message(
      'Email (optional)',
      name: 'ndefContactEmail',
      desc: '',
      args: [],
    );
  }

  /// `Organization (optional)`
  String get ndefContactOrganization {
    return Intl.message(
      'Organization (optional)',
      name: 'ndefContactOrganization',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid phone number.`
  String get ndefInvalidPhoneNumber {
    return Intl.message(
      'Enter a valid phone number.',
      name: 'ndefInvalidPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid email address.`
  String get ndefInvalidEmail {
    return Intl.message(
      'Enter a valid email address.',
      name: 'ndefInvalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Record ID (optional, hex)`
  String get ndefRecordId {
    return Intl.message(
      'Record ID (optional, hex)',
      name: 'ndefRecordId',
      desc: '',
      args: [],
    );
  }

  /// `Optional hexadecimal bytes`
  String get ndefOptionalHex {
    return Intl.message(
      'Optional hexadecimal bytes',
      name: 'ndefOptionalHex',
      desc: '',
      args: [],
    );
  }

  /// `Title (optional)`
  String get ndefSmartPosterTitle {
    return Intl.message(
      'Title (optional)',
      name: 'ndefSmartPosterTitle',
      desc: '',
      args: [],
    );
  }

  /// `Suggested action`
  String get ndefSmartPosterAction {
    return Intl.message(
      'Suggested action',
      name: 'ndefSmartPosterAction',
      desc: '',
      args: [],
    );
  }

  /// `Open`
  String get ndefSmartPosterActionOpen {
    return Intl.message(
      'Open',
      name: 'ndefSmartPosterActionOpen',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get ndefSmartPosterActionSave {
    return Intl.message(
      'Save',
      name: 'ndefSmartPosterActionSave',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get ndefSmartPosterActionEdit {
    return Intl.message(
      'Edit',
      name: 'ndefSmartPosterActionEdit',
      desc: '',
      args: [],
    );
  }

  /// `MIME type`
  String get ndefMimeType {
    return Intl.message('MIME type', name: 'ndefMimeType', desc: '', args: []);
  }

  /// `Network password`
  String get ndefWifiPassword {
    return Intl.message(
      'Network password',
      name: 'ndefWifiPassword',
      desc: '',
      args: [],
    );
  }

  /// `Authentication`
  String get ndefWifiAuthentication {
    return Intl.message(
      'Authentication',
      name: 'ndefWifiAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `Encryption`
  String get ndefWifiEncryption {
    return Intl.message(
      'Encryption',
      name: 'ndefWifiEncryption',
      desc: '',
      args: [],
    );
  }

  /// `MAC address`
  String get ndefMacAddress {
    return Intl.message(
      'MAC address',
      name: 'ndefMacAddress',
      desc: '',
      args: [],
    );
  }

  /// `Device name (optional)`
  String get ndefDeviceName {
    return Intl.message(
      'Device name (optional)',
      name: 'ndefDeviceName',
      desc: '',
      args: [],
    );
  }

  /// `Address type`
  String get ndefBluetoothAddressType {
    return Intl.message(
      'Address type',
      name: 'ndefBluetoothAddressType',
      desc: '',
      args: [],
    );
  }

  /// `Public`
  String get ndefBluetoothPublicAddress {
    return Intl.message(
      'Public',
      name: 'ndefBluetoothPublicAddress',
      desc: '',
      args: [],
    );
  }

  /// `Random`
  String get ndefBluetoothRandomAddress {
    return Intl.message(
      'Random',
      name: 'ndefBluetoothRandomAddress',
      desc: '',
      args: [],
    );
  }

  /// `Type name`
  String get ndefTypeName {
    return Intl.message('Type name', name: 'ndefTypeName', desc: '', args: []);
  }

  /// `Handover record type`
  String get ndefHandoverType {
    return Intl.message(
      'Handover record type',
      name: 'ndefHandoverType',
      desc: '',
      args: [],
    );
  }

  /// `External type name`
  String get ndefExternalType {
    return Intl.message(
      'External type name',
      name: 'ndefExternalType',
      desc: '',
      args: [],
    );
  }

  /// `Android package name`
  String get ndefAndroidPackage {
    return Intl.message(
      'Android package name',
      name: 'ndefAndroidPackage',
      desc: '',
      args: [],
    );
  }

  /// `Vendor`
  String get ndefDeviceVendor {
    return Intl.message('Vendor', name: 'ndefDeviceVendor', desc: '', args: []);
  }

  /// `Model`
  String get ndefDeviceModel {
    return Intl.message('Model', name: 'ndefDeviceModel', desc: '', args: []);
  }

  /// `Unique name (optional)`
  String get ndefDeviceUniqueName {
    return Intl.message(
      'Unique name (optional)',
      name: 'ndefDeviceUniqueName',
      desc: '',
      args: [],
    );
  }

  /// `Version (optional)`
  String get ndefDeviceVersion {
    return Intl.message(
      'Version (optional)',
      name: 'ndefDeviceVersion',
      desc: '',
      args: [],
    );
  }

  /// `Payload`
  String get ndefPayload {
    return Intl.message('Payload', name: 'ndefPayload', desc: '', args: []);
  }

  /// `Payload encoding`
  String get ndefPayloadEncoding {
    return Intl.message(
      'Payload encoding',
      name: 'ndefPayloadEncoding',
      desc: '',
      args: [],
    );
  }

  /// `Text`
  String get ndefPayloadText {
    return Intl.message('Text', name: 'ndefPayloadText', desc: '', args: []);
  }

  /// `Hex`
  String get ndefPayloadHex {
    return Intl.message('Hex', name: 'ndefPayloadHex', desc: '', args: []);
  }

  /// `The payload cannot be converted between UTF-8 text and hexadecimal bytes.`
  String get ndefPayloadConversionFailed {
    return Intl.message(
      'The payload cannot be converted between UTF-8 text and hexadecimal bytes.',
      name: 'ndefPayloadConversionFailed',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid MIME type, such as text/plain.`
  String get ndefInvalidMimeType {
    return Intl.message(
      'Enter a valid MIME type, such as text/plain.',
      name: 'ndefInvalidMimeType',
      desc: '',
      args: [],
    );
  }

  /// `Enter a lowercase external type, such as example.com:record.`
  String get ndefInvalidExternalType {
    return Intl.message(
      'Enter a lowercase external type, such as example.com:record.',
      name: 'ndefInvalidExternalType',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid Android package name, such as com.example.app.`
  String get ndefInvalidPackageName {
    return Intl.message(
      'Enter a valid Android package name, such as com.example.app.',
      name: 'ndefInvalidPackageName',
      desc: '',
      args: [],
    );
  }

  /// `Enter a MAC address such as AA:BB:CC:DD:EE:FF.`
  String get ndefInvalidMacAddress {
    return Intl.message(
      'Enter a MAC address such as AA:BB:CC:DD:EE:FF.',
      name: 'ndefInvalidMacAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter a UUID in canonical form.`
  String get ndefInvalidUuid {
    return Intl.message(
      'Enter a UUID in canonical form.',
      name: 'ndefInvalidUuid',
      desc: '',
      args: [],
    );
  }

  /// `The ndef library rejected this record: {error}`
  String ndefInvalidRecord(Object error) {
    return Intl.message(
      'The ndef library rejected this record: $error',
      name: 'ndefInvalidRecord',
      desc: '',
      args: [error],
    );
  }

  /// `This field is required.`
  String get ndefRequiredField {
    return Intl.message(
      'This field is required.',
      name: 'ndefRequiredField',
      desc: '',
      args: [],
    );
  }

  /// `This TNF requires an empty type name.`
  String get ndefTnfRequiresEmptyType {
    return Intl.message(
      'This TNF requires an empty type name.',
      name: 'ndefTnfRequiresEmptyType',
      desc: '',
      args: [],
    );
  }

  /// `Empty`
  String get ndefTnfEmpty {
    return Intl.message('Empty', name: 'ndefTnfEmpty', desc: '', args: []);
  }

  /// `NFC Forum well-known`
  String get ndefTnfWellKnown {
    return Intl.message(
      'NFC Forum well-known',
      name: 'ndefTnfWellKnown',
      desc: '',
      args: [],
    );
  }

  /// `Media (MIME)`
  String get ndefTnfMedia {
    return Intl.message(
      'Media (MIME)',
      name: 'ndefTnfMedia',
      desc: '',
      args: [],
    );
  }

  /// `Absolute URI`
  String get ndefTnfAbsoluteUri {
    return Intl.message(
      'Absolute URI',
      name: 'ndefTnfAbsoluteUri',
      desc: '',
      args: [],
    );
  }

  /// `NFC Forum external`
  String get ndefTnfExternal {
    return Intl.message(
      'NFC Forum external',
      name: 'ndefTnfExternal',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get ndefTnfUnknown {
    return Intl.message('Unknown', name: 'ndefTnfUnknown', desc: '', args: []);
  }

  /// `Reset OpenPGP`
  String get settingsResetOpenPGP {
    return Intl.message(
      'Reset OpenPGP',
      name: 'settingsResetOpenPGP',
      desc: '',
      args: [],
    );
  }

  /// `Reset PIV`
  String get settingsResetPIV {
    return Intl.message(
      'Reset PIV',
      name: 'settingsResetPIV',
      desc: '',
      args: [],
    );
  }

  /// `Reset TOTP/HOTP`
  String get settingsResetOATH {
    return Intl.message(
      'Reset TOTP/HOTP',
      name: 'settingsResetOATH',
      desc: '',
      args: [],
    );
  }

  /// `Reset NDEF`
  String get settingsResetNDEF {
    return Intl.message(
      'Reset NDEF',
      name: 'settingsResetNDEF',
      desc: '',
      args: [],
    );
  }

  /// `Reset WebAuthn`
  String get settingsResetWebAuthn {
    return Intl.message(
      'Reset WebAuthn',
      name: 'settingsResetWebAuthn',
      desc: '',
      args: [],
    );
  }

  /// `Reset Pass`
  String get settingsResetPass {
    return Intl.message(
      'Reset Pass',
      name: 'settingsResetPass',
      desc: '',
      args: [],
    );
  }

  /// `This operation will RESET all data of {applet}!`
  String settingsResetApplet(Object applet) {
    return Intl.message(
      'This operation will RESET all data of $applet!',
      name: 'settingsResetApplet',
      desc: '',
      args: [applet],
    );
  }

  /// `Reset CanoKey`
  String get settingsResetAll {
    return Intl.message(
      'Reset CanoKey',
      name: 'settingsResetAll',
      desc: '',
      args: [],
    );
  }

  /// `All data will be erased. Once confirmed, the CanoKey will blink multiple times. Please touch it each time you see a blink until the success prompt appears.`
  String get settingsResetAllPrompt {
    return Intl.message(
      'All data will be erased. Once confirmed, the CanoKey will blink multiple times. Please touch it each time you see a blink until the success prompt appears.',
      name: 'settingsResetAllPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Successfully reset`
  String get settingsResetSuccess {
    return Intl.message(
      'Successfully reset',
      name: 'settingsResetSuccess',
      desc: '',
      args: [],
    );
  }

  /// `PIN has not been locked yet`
  String get settingsResetConditionNotSatisfying {
    return Intl.message(
      'PIN has not been locked yet',
      name: 'settingsResetConditionNotSatisfying',
      desc: '',
      args: [],
    );
  }

  /// `You did not touch the pad in time`
  String get settingsResetPresenceTestFailed {
    return Intl.message(
      'You did not touch the pad in time',
      name: 'settingsResetPresenceTestFailed',
      desc: '',
      args: [],
    );
  }

  /// `Change Language`
  String get settingsChangeLanguage {
    return Intl.message(
      'Change Language',
      name: 'settingsChangeLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Fix NFC`
  String get settingsFixNFC {
    return Intl.message('Fix NFC', name: 'settingsFixNFC', desc: '', args: []);
  }

  /// `NFC is successfully fixed`
  String get settingsFixNFCSuccess {
    return Intl.message(
      'NFC is successfully fixed',
      name: 'settingsFixNFCSuccess',
      desc: '',
      args: [],
    );
  }

  /// `The output of OTP value comes with enter`
  String get settingsKeyboardWithReturn {
    return Intl.message(
      'The output of OTP value comes with enter',
      name: 'settingsKeyboardWithReturn',
      desc: '',
      args: [],
    );
  }

  /// `Keyboard Layout`
  String get settingsKeyboardLayout {
    return Intl.message(
      'Keyboard Layout',
      name: 'settingsKeyboardLayout',
      desc: '',
      args: [],
    );
  }

  /// `Default / US QWERTY`
  String get settingsKeyboardLayoutDefault {
    return Intl.message(
      'Default / US QWERTY',
      name: 'settingsKeyboardLayoutDefault',
      desc: '',
      args: [],
    );
  }

  /// `Custom layout`
  String get settingsKeyboardLayoutCustom {
    return Intl.message(
      'Custom layout',
      name: 'settingsKeyboardLayoutCustom',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get settingsKeyboardLayoutUnknown {
    return Intl.message(
      'Unknown',
      name: 'settingsKeyboardLayoutUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Current: {layout}`
  String settingsKeyboardLayoutCurrent(Object layout) {
    return Intl.message(
      'Current: $layout',
      name: 'settingsKeyboardLayoutCurrent',
      desc: '',
      args: [layout],
    );
  }

  /// `The current keymap does not match a built-in preset. Applying a preset will overwrite it.`
  String get settingsKeyboardLayoutUnknownPrompt {
    return Intl.message(
      'The current keymap does not match a built-in preset. Applying a preset will overwrite it.',
      name: 'settingsKeyboardLayoutUnknownPrompt',
      desc: '',
      args: [],
    );
  }

  /// `WebAuthn SM2`
  String get settingsWebAuthnSm2Support {
    return Intl.message(
      'WebAuthn SM2',
      name: 'settingsWebAuthnSm2Support',
      desc: '',
      args: [],
    );
  }

  /// `Start Page`
  String get settingsStartPage {
    return Intl.message(
      'Start Page',
      name: 'settingsStartPage',
      desc: '',
      args: [],
    );
  }

  /// `This action will delete the account {name} from your CanoKey. Make sure 2FA has been disabled on the web service.`
  String oathDelete(Object name) {
    return Intl.message(
      'This action will delete the account $name from your CanoKey. Make sure 2FA has been disabled on the web service.',
      name: 'oathDelete',
      desc: '',
      args: [name],
    );
  }

  /// `Do you want to set the account {name} as the default output when touching? Be careful, the original configuration will be overwritten.`
  String oathSetDefaultPrompt(Object name) {
    return Intl.message(
      'Do you want to set the account $name as the default output when touching? Be careful, the original configuration will be overwritten.',
      name: 'oathSetDefaultPrompt',
      desc: '',
      args: [name],
    );
  }

  /// `Copy to Clipboard`
  String get oathCopy {
    return Intl.message(
      'Copy to Clipboard',
      name: 'oathCopy',
      desc: '',
      args: [],
    );
  }

  /// `Set as Touch Output`
  String get oathSetDefault {
    return Intl.message(
      'Set as Touch Output',
      name: 'oathSetDefault',
      desc: '',
      args: [],
    );
  }

  /// `Add Account`
  String get oathAddAccount {
    return Intl.message(
      'Add Account',
      name: 'oathAddAccount',
      desc: '',
      args: [],
    );
  }

  /// `Issuer`
  String get oathIssuer {
    return Intl.message('Issuer', name: 'oathIssuer', desc: '', args: []);
  }

  /// `Account name`
  String get oathAccount {
    return Intl.message(
      'Account name',
      name: 'oathAccount',
      desc: '',
      args: [],
    );
  }

  /// `Secret key`
  String get oathSecret {
    return Intl.message('Secret key', name: 'oathSecret', desc: '', args: []);
  }

  /// `Type`
  String get oathType {
    return Intl.message('Type', name: 'oathType', desc: '', args: []);
  }

  /// `Algorithm`
  String get oathAlgorithm {
    return Intl.message('Algorithm', name: 'oathAlgorithm', desc: '', args: []);
  }

  /// `Digits`
  String get oathDigits {
    return Intl.message('Digits', name: 'oathDigits', desc: '', args: []);
  }

  /// `Period`
  String get oathPeriod {
    return Intl.message('Period', name: 'oathPeriod', desc: '', args: []);
  }

  /// `Require Touch`
  String get oathRequireTouch {
    return Intl.message(
      'Require Touch',
      name: 'oathRequireTouch',
      desc: '',
      args: [],
    );
  }

  /// `Required`
  String get oathRequired {
    return Intl.message('Required', name: 'oathRequired', desc: '', args: []);
  }

  /// `Too long`
  String get oathTooLong {
    return Intl.message('Too long', name: 'oathTooLong', desc: '', args: []);
  }

  /// `Counter`
  String get oathCounter {
    return Intl.message('Counter', name: 'oathCounter', desc: '', args: []);
  }

  /// `Not a number`
  String get oathCounterMustBeNumber {
    return Intl.message(
      'Not a number',
      name: 'oathCounterMustBeNumber',
      desc: '',
      args: [],
    );
  }

  /// `Invalid secret key`
  String get oathInvalidKey {
    return Intl.message(
      'Invalid secret key',
      name: 'oathInvalidKey',
      desc: '',
      args: [],
    );
  }

  /// `Successfully added`
  String get oathAdded {
    return Intl.message(
      'Successfully added',
      name: 'oathAdded',
      desc: '',
      args: [],
    );
  }

  /// `Duplicated account`
  String get oathDuplicated {
    return Intl.message(
      'Duplicated account',
      name: 'oathDuplicated',
      desc: '',
      args: [],
    );
  }

  /// `Unlock CanoKey`
  String get oathInputCode {
    return Intl.message(
      'Unlock CanoKey',
      name: 'oathInputCode',
      desc: '',
      args: [],
    );
  }

  /// `To prevent unauthorized access, this CanoKey is protected with a passphrase.`
  String get oathInputCodePrompt {
    return Intl.message(
      'To prevent unauthorized access, this CanoKey is protected with a passphrase.',
      name: 'oathInputCodePrompt',
      desc: '',
      args: [],
    );
  }

  /// `Passphrase`
  String get oathCode {
    return Intl.message('Passphrase', name: 'oathCode', desc: '', args: []);
  }

  /// `Set Passphrase`
  String get oathSetCode {
    return Intl.message(
      'Set Passphrase',
      name: 'oathSetCode',
      desc: '',
      args: [],
    );
  }

  /// `New Passphrase`
  String get oathNewCode {
    return Intl.message(
      'New Passphrase',
      name: 'oathNewCode',
      desc: '',
      args: [],
    );
  }

  /// `Passphrase Changed`
  String get oathCodeChanged {
    return Intl.message(
      'Passphrase Changed',
      name: 'oathCodeChanged',
      desc: '',
      args: [],
    );
  }

  /// `Enter a new passphrase. Leave it empty to disable current passphrase.`
  String get oathNewCodePrompt {
    return Intl.message(
      'Enter a new passphrase. Leave it empty to disable current passphrase.',
      name: 'oathNewCodePrompt',
      desc: '',
      args: [],
    );
  }

  /// `Advanced Settings. Think well before changing them. You could lock yourself out!`
  String get oathAdvancedSettings {
    return Intl.message(
      'Advanced Settings. Think well before changing them. You could lock yourself out!',
      name: 'oathAdvancedSettings',
      desc: '',
      args: [],
    );
  }

  /// `Slot`
  String get oathSlot {
    return Intl.message('Slot', name: 'oathSlot', desc: '', args: []);
  }

  /// `Scan QR Code`
  String get oathAddByScanning {
    return Intl.message(
      'Scan QR Code',
      name: 'oathAddByScanning',
      desc: '',
      args: [],
    );
  }

  /// `Add Manually`
  String get oathAddManually {
    return Intl.message(
      'Add Manually',
      name: 'oathAddManually',
      desc: '',
      args: [],
    );
  }

  /// `Scan QR Code on Screen`
  String get oathAddByScreen {
    return Intl.message(
      'Scan QR Code on Screen',
      name: 'oathAddByScreen',
      desc: '',
      args: [],
    );
  }

  /// `No QR Code detected`
  String get oathNoQr {
    return Intl.message(
      'No QR Code detected',
      name: 'oathNoQr',
      desc: '',
      args: [],
    );
  }

  /// `Please input your Setting PIN. The default value is 123456.`
  String get passInputPinPrompt {
    return Intl.message(
      'Please input your Setting PIN. The default value is 123456.',
      name: 'passInputPinPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Slot Configuration`
  String get passSlotConfigTitle {
    return Intl.message(
      'Slot Configuration',
      name: 'passSlotConfigTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please select a slot type to configure. If you want to use HOTP, set it in the HOTP applet.`
  String get passSlotConfigPrompt {
    return Intl.message(
      'Please select a slot type to configure. If you want to use HOTP, set it in the HOTP applet.',
      name: 'passSlotConfigPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Slot Short`
  String get passSlotShort {
    return Intl.message(
      'Slot Short',
      name: 'passSlotShort',
      desc: '',
      args: [],
    );
  }

  /// `Slot Long`
  String get passSlotLong {
    return Intl.message('Slot Long', name: 'passSlotLong', desc: '', args: []);
  }

  /// `Status`
  String get passStatus {
    return Intl.message('Status', name: 'passStatus', desc: '', args: []);
  }

  /// `Off`
  String get passSlotOff {
    return Intl.message('Off', name: 'passSlotOff', desc: '', args: []);
  }

  /// `HOTP`
  String get passSlotHotp {
    return Intl.message('HOTP', name: 'passSlotHotp', desc: '', args: []);
  }

  /// `Static Password`
  String get passSlotStatic {
    return Intl.message(
      'Static Password',
      name: 'passSlotStatic',
      desc: '',
      args: [],
    );
  }

  /// `HMAC-SHA1`
  String get passSlotHmacSha1 {
    return Intl.message(
      'HMAC-SHA1',
      name: 'passSlotHmacSha1',
      desc: '',
      args: [],
    );
  }

  /// `20-byte HMAC-SHA1 key (hex)`
  String get passSlotHmacSha1Key {
    return Intl.message(
      '20-byte HMAC-SHA1 key (hex)',
      name: 'passSlotHmacSha1Key',
      desc: '',
      args: [],
    );
  }

  /// `The output comes with Enter`
  String get passSlotWithEnter {
    return Intl.message(
      'The output comes with Enter',
      name: 'passSlotWithEnter',
      desc: '',
      args: [],
    );
  }

  /// `This key does not support WebAuthn PIN.`
  String get webauthnClientPinNotSupported {
    return Intl.message(
      'This key does not support WebAuthn PIN.',
      name: 'webauthnClientPinNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `Set WebAuthn PIN`
  String get webauthnSetPinTitle {
    return Intl.message(
      'Set WebAuthn PIN',
      name: 'webauthnSetPinTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please set your WebAuthn PIN to enable management of credentials. The length of PIN should be between 4 and 63.`
  String get webauthnSetPinPrompt {
    return Intl.message(
      'Please set your WebAuthn PIN to enable management of credentials. The length of PIN should be between 4 and 63.',
      name: 'webauthnSetPinPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Unlock WebAuthn`
  String get webauthnInputPinTitle {
    return Intl.message(
      'Unlock WebAuthn',
      name: 'webauthnInputPinTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please input your WebAuthn PIN.`
  String get webauthnInputPinPrompt {
    return Intl.message(
      'Please input your WebAuthn PIN.',
      name: 'webauthnInputPinPrompt',
      desc: '',
      args: [],
    );
  }

  /// `This action will delete the account {name} from your CanoKey. Make sure you have other ways to log in.`
  String webauthnDelete(Object name) {
    return Intl.message(
      'This action will delete the account $name from your CanoKey. Make sure you have other ways to log in.',
      name: 'webauthnDelete',
      desc: '',
      args: [name],
    );
  }

  /// `PIN authentication is blocked. Please reinsert you CanoKey to retry.`
  String get webauthnPinAuthBlocked {
    return Intl.message(
      'PIN authentication is blocked. Please reinsert you CanoKey to retry.',
      name: 'webauthnPinAuthBlocked',
      desc: '',
      args: [],
    );
  }

  /// `PIN authentication is blocked. Please reset WebAuthn.`
  String get webauthnPinBlocked {
    return Intl.message(
      'PIN authentication is blocked. Please reset WebAuthn.',
      name: 'webauthnPinBlocked',
      desc: '',
      args: [],
    );
  }

  /// `PIN Management`
  String get pivPinManagement {
    return Intl.message(
      'PIN Management',
      name: 'pivPinManagement',
      desc: '',
      args: [],
    );
  }

  /// `Change PUK`
  String get pivChangePUK {
    return Intl.message('Change PUK', name: 'pivChangePUK', desc: '', args: []);
  }

  /// `Current PUK`
  String get pivOldPUK {
    return Intl.message('Current PUK', name: 'pivOldPUK', desc: '', args: []);
  }

  /// `New PUK`
  String get pivNewPUK {
    return Intl.message('New PUK', name: 'pivNewPUK', desc: '', args: []);
  }

  /// `New PUK should be at least {min} characters long. The maximum length is {max}.`
  String pivChangePUKPrompt(Object min, Object max) {
    return Intl.message(
      'New PUK should be at least $min characters long. The maximum length is $max.',
      name: 'pivChangePUKPrompt',
      desc: '',
      args: [min, max],
    );
  }

  /// `Change Management Key`
  String get pivChangeManagementKey {
    return Intl.message(
      'Change Management Key',
      name: 'pivChangeManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `New Management Key should be 24 bytes long. Please save it in a safe place.`
  String get pivChangeManagementKeyPrompt {
    return Intl.message(
      'New Management Key should be 24 bytes long. Please save it in a safe place.',
      name: 'pivChangeManagementKeyPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Current Management Key`
  String get pivOldManagementKey {
    return Intl.message(
      'Current Management Key',
      name: 'pivOldManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `New Management Key`
  String get pivNewManagementKey {
    return Intl.message(
      'New Management Key',
      name: 'pivNewManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `Management Key`
  String get pivManagementKey {
    return Intl.message(
      'Management Key',
      name: 'pivManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get pivUseDefaultManagementKey {
    return Intl.message(
      'Default',
      name: 'pivUseDefaultManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `Random`
  String get pivRandomManagementKey {
    return Intl.message(
      'Random',
      name: 'pivRandomManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `Management Key verification failed`
  String get pivManagementKeyVerificationFailed {
    return Intl.message(
      'Management Key verification failed',
      name: 'pivManagementKeyVerificationFailed',
      desc: '',
      args: [],
    );
  }

  /// `Slots`
  String get pivSlots {
    return Intl.message('Slots', name: 'pivSlots', desc: '', args: []);
  }

  /// `Empty`
  String get pivEmpty {
    return Intl.message('Empty', name: 'pivEmpty', desc: '', args: []);
  }

  /// `Authentication`
  String get pivAuthentication {
    return Intl.message(
      'Authentication',
      name: 'pivAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `Digital Signature`
  String get pivSignature {
    return Intl.message(
      'Digital Signature',
      name: 'pivSignature',
      desc: '',
      args: [],
    );
  }

  /// `Key Management`
  String get pivKeyManagement {
    return Intl.message(
      'Key Management',
      name: 'pivKeyManagement',
      desc: '',
      args: [],
    );
  }

  /// `Card Authentication`
  String get pivCardAuthentication {
    return Intl.message(
      'Card Authentication',
      name: 'pivCardAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `Retired 1`
  String get pivRetired1 {
    return Intl.message('Retired 1', name: 'pivRetired1', desc: '', args: []);
  }

  /// `Retired 2`
  String get pivRetired2 {
    return Intl.message('Retired 2', name: 'pivRetired2', desc: '', args: []);
  }

  /// `Current Algorithm`
  String get pivAlgorithm {
    return Intl.message(
      'Current Algorithm',
      name: 'pivAlgorithm',
      desc: '',
      args: [],
    );
  }

  /// `PIN Policy`
  String get pivPinPolicy {
    return Intl.message('PIN Policy', name: 'pivPinPolicy', desc: '', args: []);
  }

  /// `Default`
  String get pivPinPolicyDefault {
    return Intl.message(
      'Default',
      name: 'pivPinPolicyDefault',
      desc: '',
      args: [],
    );
  }

  /// `Never`
  String get pivPinPolicyNever {
    return Intl.message('Never', name: 'pivPinPolicyNever', desc: '', args: []);
  }

  /// `Once`
  String get pivPinPolicyOnce {
    return Intl.message('Once', name: 'pivPinPolicyOnce', desc: '', args: []);
  }

  /// `Always`
  String get pivPinPolicyAlways {
    return Intl.message(
      'Always',
      name: 'pivPinPolicyAlways',
      desc: '',
      args: [],
    );
  }

  /// `Touch Policy`
  String get pivTouchPolicy {
    return Intl.message(
      'Touch Policy',
      name: 'pivTouchPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get pivTouchPolicyDefault {
    return Intl.message(
      'Default',
      name: 'pivTouchPolicyDefault',
      desc: '',
      args: [],
    );
  }

  /// `Never`
  String get pivTouchPolicyNever {
    return Intl.message(
      'Never',
      name: 'pivTouchPolicyNever',
      desc: '',
      args: [],
    );
  }

  /// `Always`
  String get pivTouchPolicyAlways {
    return Intl.message(
      'Always',
      name: 'pivTouchPolicyAlways',
      desc: '',
      args: [],
    );
  }

  /// `Cached for 15 seconds`
  String get pivTouchPolicyCached {
    return Intl.message(
      'Cached for 15 seconds',
      name: 'pivTouchPolicyCached',
      desc: '',
      args: [],
    );
  }

  /// `Origin`
  String get pivOrigin {
    return Intl.message('Origin', name: 'pivOrigin', desc: '', args: []);
  }

  /// `Generated`
  String get pivOriginGenerated {
    return Intl.message(
      'Generated',
      name: 'pivOriginGenerated',
      desc: '',
      args: [],
    );
  }

  /// `Imported`
  String get pivOriginImported {
    return Intl.message(
      'Imported',
      name: 'pivOriginImported',
      desc: '',
      args: [],
    );
  }

  /// `Certificate`
  String get pivCertificate {
    return Intl.message(
      'Certificate',
      name: 'pivCertificate',
      desc: '',
      args: [],
    );
  }

  /// `No certificate`
  String get pivNoCertificate {
    return Intl.message(
      'No certificate',
      name: 'pivNoCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get pivImport {
    return Intl.message('Import', name: 'pivImport', desc: '', args: []);
  }

  /// `Generate`
  String get pivGenerate {
    return Intl.message('Generate', name: 'pivGenerate', desc: '', args: []);
  }

  /// `Export`
  String get pivExport {
    return Intl.message('Export', name: 'pivExport', desc: '', args: []);
  }

  /// `Delete`
  String get pivDelete {
    return Intl.message('Delete', name: 'pivDelete', desc: '', args: []);
  }

  /// `Export Certificate`
  String get pivExportCertificate {
    return Intl.message(
      'Export Certificate',
      name: 'pivExportCertificate',
      desc: '',
      args: [],
    );
  }

  /// `This action will delete the slot {slot} from your CanoKey. Make sure you have other ways to authenticate.`
  String pivDeleteSlot(Object slot) {
    return Intl.message(
      'This action will delete the slot $slot from your CanoKey. Make sure you have other ways to authenticate.',
      name: 'pivDeleteSlot',
      desc: '',
      args: [slot],
    );
  }

  /// `Verify Management Key`
  String get pivVerifyManagementKey {
    return Intl.message(
      'Verify Management Key',
      name: 'pivVerifyManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `Management key authentication`
  String get pivManagementKeyAuthentication {
    return Intl.message(
      'Management key authentication',
      name: 'pivManagementKeyAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `PIN-protected key on card`
  String get pivPinProtectedKeyOnCard {
    return Intl.message(
      'PIN-protected key on card',
      name: 'pivPinProtectedKeyOnCard',
      desc: '',
      args: [],
    );
  }

  /// `Manual management key`
  String get pivManualManagementKey {
    return Intl.message(
      'Manual management key',
      name: 'pivManualManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `X25519 keys are only supported in the key management slot 9D.`
  String get pivX25519OnlyIn9D {
    return Intl.message(
      'X25519 keys are only supported in the key management slot 9D.',
      name: 'pivX25519OnlyIn9D',
      desc: '',
      args: [],
    );
  }

  /// `The certificate public key does not match the selected private key.`
  String get pivCertificateDoesNotMatchPrivateKey {
    return Intl.message(
      'The certificate public key does not match the selected private key.',
      name: 'pivCertificateDoesNotMatchPrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `X25519 cannot be used with certificates. Import the key without a certificate.`
  String get pivX25519CannotUseCertificate {
    return Intl.message(
      'X25519 cannot be used with certificates. Import the key without a certificate.',
      name: 'pivX25519CannotUseCertificate',
      desc: '',
      args: [],
    );
  }

  /// `This import will replace the private key currently stored in this slot.`
  String get pivImportWillReplacePrivateKey {
    return Intl.message(
      'This import will replace the private key currently stored in this slot.',
      name: 'pivImportWillReplacePrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `This import will replace the certificate currently stored in this slot.`
  String get pivImportWillReplaceCertificate {
    return Intl.message(
      'This import will replace the certificate currently stored in this slot.',
      name: 'pivImportWillReplaceCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Certificate-only import does not change the private key. Make sure this certificate belongs to the key already on the card.`
  String get pivCertificateOnlyKeepsPrivateKey {
    return Intl.message(
      'Certificate-only import does not change the private key. Make sure this certificate belongs to the key already on the card.',
      name: 'pivCertificateOnlyKeepsPrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `Key-only import leaves the existing certificate in place. Replace or clear the certificate if it no longer matches.`
  String get pivKeyOnlyKeepsCertificate {
    return Intl.message(
      'Key-only import leaves the existing certificate in place. Replace or clear the certificate if it no longer matches.',
      name: 'pivKeyOnlyKeepsCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get refresh {
    return Intl.message('Refresh', name: 'refresh', desc: '', args: []);
  }

  /// `Enable`
  String get enable {
    return Intl.message('Enable', name: 'enable', desc: '', args: []);
  }

  /// `Disable`
  String get disable {
    return Intl.message('Disable', name: 'disable', desc: '', args: []);
  }

  /// `Select`
  String get select {
    return Intl.message('Select', name: 'select', desc: '', args: []);
  }

  /// `Next`
  String get next {
    return Intl.message('Next', name: 'next', desc: '', args: []);
  }

  /// `Back`
  String get back {
    return Intl.message('Back', name: 'back', desc: '', args: []);
  }

  /// `Copy`
  String get copy {
    return Intl.message('Copy', name: 'copy', desc: '', args: []);
  }

  /// `Saved`
  String get fileSaved {
    return Intl.message('Saved', name: 'fileSaved', desc: '', args: []);
  }

  /// `Failed to save file`
  String get fileSaveFailed {
    return Intl.message(
      'Failed to save file',
      name: 'fileSaveFailed',
      desc: '',
      args: [],
    );
  }

  /// `Save failed: {error}`
  String fileSaveFailedWithError(Object error) {
    return Intl.message(
      'Save failed: $error',
      name: 'fileSaveFailedWithError',
      desc: '',
      args: [error],
    );
  }

  /// `Authentication slot. Use a signing-capable key for login.`
  String get pivSlotAuthenticationHint {
    return Intl.message(
      'Authentication slot. Use a signing-capable key for login.',
      name: 'pivSlotAuthenticationHint',
      desc: '',
      args: [],
    );
  }

  /// `Digital signature slot. PIN policy defaults to always.`
  String get pivSlotSignatureHint {
    return Intl.message(
      'Digital signature slot. PIN policy defaults to always.',
      name: 'pivSlotSignatureHint',
      desc: '',
      args: [],
    );
  }

  /// `Key management slot. X25519 can derive shared secrets only.`
  String get pivSlotKeyManagementHint {
    return Intl.message(
      'Key management slot. X25519 can derive shared secrets only.',
      name: 'pivSlotKeyManagementHint',
      desc: '',
      args: [],
    );
  }

  /// `Card authentication slot. PIN may be unnecessary for some uses.`
  String get pivSlotCardAuthenticationHint {
    return Intl.message(
      'Card authentication slot. PIN may be unnecessary for some uses.',
      name: 'pivSlotCardAuthenticationHint',
      desc: '',
      args: [],
    );
  }

  /// `Retired key management slot for old decryption keys and certificates.`
  String get pivSlotRetiredHint {
    return Intl.message(
      'Retired key management slot for old decryption keys and certificates.',
      name: 'pivSlotRetiredHint',
      desc: '',
      args: [],
    );
  }

  /// `CSR and certificates are disabled for X25519.`
  String get pivX25519CertificateDisabled {
    return Intl.message(
      'CSR and certificates are disabled for X25519.',
      name: 'pivX25519CertificateDisabled',
      desc: '',
      args: [],
    );
  }

  /// `CSR, self-signed certificates, and attestation are unavailable for this algorithm.`
  String get pivPostQuantumCertificateGenerationDisabled {
    return Intl.message(
      'CSR, self-signed certificates, and attestation are unavailable for this algorithm.',
      name: 'pivPostQuantumCertificateGenerationDisabled',
      desc: '',
      args: [],
    );
  }

  /// `Check client compatibility before using this algorithm.`
  String get pivExtendedAlgorithmCompatibilityWarning {
    return Intl.message(
      'Check client compatibility before using this algorithm.',
      name: 'pivExtendedAlgorithmCompatibilityWarning',
      desc: '',
      args: [],
    );
  }

  /// `Overwrite Key`
  String get pivOverwriteKey {
    return Intl.message(
      'Overwrite Key',
      name: 'pivOverwriteKey',
      desc: '',
      args: [],
    );
  }

  /// `{action} will replace the private key in slot {slot}. Existing authentication or signing that depends on this key may stop working.`
  String pivOverwriteKeyPrompt(Object action, Object slot) {
    return Intl.message(
      '$action will replace the private key in slot $slot. Existing authentication or signing that depends on this key may stop working.',
      name: 'pivOverwriteKeyPrompt',
      desc: '',
      args: [action, slot],
    );
  }

  /// `Overwrite`
  String get pivOverwrite {
    return Intl.message('Overwrite', name: 'pivOverwrite', desc: '', args: []);
  }

  /// `Algorithm IDs`
  String get pivAlgorithmIds {
    return Intl.message(
      'Algorithm IDs',
      name: 'pivAlgorithmIds',
      desc: '',
      args: [],
    );
  }

  /// `Unblock PIN`
  String get pivUnblockPin {
    return Intl.message(
      'Unblock PIN',
      name: 'pivUnblockPin',
      desc: '',
      args: [],
    );
  }

  /// `Enter the current PUK and set a new PIN.`
  String get pivUnblockPinPrompt {
    return Intl.message(
      'Enter the current PUK and set a new PIN.',
      name: 'pivUnblockPinPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Retries: unknown`
  String get pivRetriesUnknown {
    return Intl.message(
      'Retries: unknown',
      name: 'pivRetriesUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Retries: {remaining}/{total}`
  String pivRetries(Object remaining, Object total) {
    return Intl.message(
      'Retries: $remaining/$total',
      name: 'pivRetries',
      desc: '',
      args: [remaining, total],
    );
  }

  /// `Use the PIN to unlock the management key stored on this card.`
  String get pivPinProtectedManagementKeyDescription {
    return Intl.message(
      'Use the PIN to unlock the management key stored on this card.',
      name: 'pivPinProtectedManagementKeyDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enter the 24-byte management key for this operation.`
  String get pivManualManagementKeyDescription {
    return Intl.message(
      'Enter the 24-byte management key for this operation.',
      name: 'pivManualManagementKeyDescription',
      desc: '',
      args: [],
    );
  }

  /// `PIV Algorithm IDs`
  String get pivAlgorithmIdsTitle {
    return Intl.message(
      'PIV Algorithm IDs',
      name: 'pivAlgorithmIdsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Controls whether PIV extension algorithm IDs are accepted by the card.`
  String get pivAlgorithmIdsPrompt {
    return Intl.message(
      'Controls whether PIV extension algorithm IDs are accepted by the card.',
      name: 'pivAlgorithmIdsPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Failed to update PIV algorithm IDs`
  String get pivAlgorithmIdsUpdateFailed {
    return Intl.message(
      'Failed to update PIV algorithm IDs',
      name: 'pivAlgorithmIdsUpdateFailed',
      desc: '',
      args: [],
    );
  }

  /// `Modify With Caution`
  String get pivModifyWithCaution {
    return Intl.message(
      'Modify With Caution',
      name: 'pivModifyWithCaution',
      desc: '',
      args: [],
    );
  }

  /// `These values control how the card recognizes PIV extension algorithms. Keep the defaults unless you know the client and firmware expect different IDs. Wrong values can make existing extended keys appear unsupported until the IDs are restored.`
  String get pivAlgorithmIdsWarning {
    return Intl.message(
      'These values control how the card recognizes PIV extension algorithms. Keep the defaults unless you know the client and firmware expect different IDs. Wrong values can make existing extended keys appear unsupported until the IDs are restored.',
      name: 'pivAlgorithmIdsWarning',
      desc: '',
      args: [],
    );
  }

  /// `Set PIN/PUK Retries`
  String get pivSetPinPukRetries {
    return Intl.message(
      'Set PIN/PUK Retries',
      name: 'pivSetPinPukRetries',
      desc: '',
      args: [],
    );
  }

  /// `This resets PIN to 123456 and PUK to 12345678.`
  String get pivSetPinPukRetriesPrompt {
    return Intl.message(
      'This resets PIN to 123456 and PUK to 12345678.',
      name: 'pivSetPinPukRetriesPrompt',
      desc: '',
      args: [],
    );
  }

  /// `PIN retries`
  String get pivPinRetries {
    return Intl.message(
      'PIN retries',
      name: 'pivPinRetries',
      desc: '',
      args: [],
    );
  }

  /// `PUK retries`
  String get pivPukRetries {
    return Intl.message(
      'PUK retries',
      name: 'pivPukRetries',
      desc: '',
      args: [],
    );
  }

  /// `Set retries failed`
  String get pivSetRetriesFailed {
    return Intl.message(
      'Set retries failed',
      name: 'pivSetRetriesFailed',
      desc: '',
      args: [],
    );
  }

  /// `PIN/PUK retries set. PIN and PUK were reset.`
  String get pivSetRetriesSuccess {
    return Intl.message(
      'PIN/PUK retries set. PIN and PUK were reset.',
      name: 'pivSetRetriesSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Use PIN-Protected Management Key`
  String get pivEnablePinProtectedManagementKey {
    return Intl.message(
      'Use PIN-Protected Management Key',
      name: 'pivEnablePinProtectedManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `A random management key will be set and stored on the card, protected by PIN.`
  String get pivEnablePinProtectedManagementKeyPrompt {
    return Intl.message(
      'A random management key will be set and stored on the card, protected by PIN.',
      name: 'pivEnablePinProtectedManagementKeyPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Failed to store a PIN-protected management key`
  String get pivEnablePinProtectedManagementKeyFailed {
    return Intl.message(
      'Failed to store a PIN-protected management key',
      name: 'pivEnablePinProtectedManagementKeyFailed',
      desc: '',
      args: [],
    );
  }

  /// `Management key is now PIN-protected`
  String get pivEnablePinProtectedManagementKeySuccess {
    return Intl.message(
      'Management key is now PIN-protected',
      name: 'pivEnablePinProtectedManagementKeySuccess',
      desc: '',
      args: [],
    );
  }

  /// `Return to Manual Management Key`
  String get pivDisablePinProtectedManagementKey {
    return Intl.message(
      'Return to Manual Management Key',
      name: 'pivDisablePinProtectedManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `A new management key will be set before the PIN-protected copy is cleared.`
  String get pivDisablePinProtectedManagementKeyPrompt {
    return Intl.message(
      'A new management key will be set before the PIN-protected copy is cleared.',
      name: 'pivDisablePinProtectedManagementKeyPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Failed to return to manual management key`
  String get pivDisablePinProtectedManagementKeyFailed {
    return Intl.message(
      'Failed to return to manual management key',
      name: 'pivDisablePinProtectedManagementKeyFailed',
      desc: '',
      args: [],
    );
  }

  /// `Manual management key is now required`
  String get pivDisablePinProtectedManagementKeySuccess {
    return Intl.message(
      'Manual management key is now required',
      name: 'pivDisablePinProtectedManagementKeySuccess',
      desc: '',
      args: [],
    );
  }

  /// `Store the new management key on this card`
  String get pivStoreManagementKeyOnCard {
    return Intl.message(
      'Store the new management key on this card',
      name: 'pivStoreManagementKeyOnCard',
      desc: '',
      args: [],
    );
  }

  /// `When enabled, future management operations can authenticate with PIN.`
  String get pivStoreManagementKeyOnCardPrompt {
    return Intl.message(
      'When enabled, future management operations can authenticate with PIN.',
      name: 'pivStoreManagementKeyOnCardPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Retired {index}`
  String pivRetiredSlot(Object index) {
    return Intl.message(
      'Retired $index',
      name: 'pivRetiredSlot',
      desc: '',
      args: [index],
    );
  }

  /// `Download Attestation`
  String get pivDownloadAttestation {
    return Intl.message(
      'Download Attestation',
      name: 'pivDownloadAttestation',
      desc: '',
      args: [],
    );
  }

  /// `Generate CSR`
  String get pivGenerateCsr {
    return Intl.message(
      'Generate CSR',
      name: 'pivGenerateCsr',
      desc: '',
      args: [],
    );
  }

  /// `Self-sign`
  String get pivSelfSign {
    return Intl.message('Self-sign', name: 'pivSelfSign', desc: '', args: []);
  }

  /// `Generate X25519 Key`
  String get pivGenerateX25519Key {
    return Intl.message(
      'Generate X25519 Key',
      name: 'pivGenerateX25519Key',
      desc: '',
      args: [],
    );
  }

  /// `Generate Key`
  String get pivGenerateKey {
    return Intl.message(
      'Generate Key',
      name: 'pivGenerateKey',
      desc: '',
      args: [],
    );
  }

  /// `Generating a {algorithm} key`
  String pivGeneratingKey(Object algorithm) {
    return Intl.message(
      'Generating a $algorithm key',
      name: 'pivGeneratingKey',
      desc: '',
      args: [algorithm],
    );
  }

  /// `Generate Key Failed`
  String get pivGenerateKeyFailed {
    return Intl.message(
      'Generate Key Failed',
      name: 'pivGenerateKeyFailed',
      desc: '',
      args: [],
    );
  }

  /// `Key Generated`
  String get pivKeyGenerated {
    return Intl.message(
      'Key Generated',
      name: 'pivKeyGenerated',
      desc: '',
      args: [],
    );
  }

  /// `Export Public Key`
  String get pivExportPublicKey {
    return Intl.message(
      'Export Public Key',
      name: 'pivExportPublicKey',
      desc: '',
      args: [],
    );
  }

  /// `Sign Message`
  String get pivSignMessage {
    return Intl.message(
      'Sign Message',
      name: 'pivSignMessage',
      desc: '',
      args: [],
    );
  }

  /// `No public key available`
  String get pivNoPublicKeyAvailable {
    return Intl.message(
      'No public key available',
      name: 'pivNoPublicKeyAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Algorithm: {algorithm}`
  String pivAlgorithmValue(Object algorithm) {
    return Intl.message(
      'Algorithm: $algorithm',
      name: 'pivAlgorithmValue',
      desc: '',
      args: [algorithm],
    );
  }

  /// `Message`
  String get pivMessage {
    return Intl.message('Message', name: 'pivMessage', desc: '', args: []);
  }

  /// `Signature (hex)`
  String get pivSignatureHex {
    return Intl.message(
      'Signature (hex)',
      name: 'pivSignatureHex',
      desc: '',
      args: [],
    );
  }

  /// `Message signing failed`
  String get pivMessageSigningFailed {
    return Intl.message(
      'Message signing failed',
      name: 'pivMessageSigningFailed',
      desc: '',
      args: [],
    );
  }

  /// `Sign File`
  String get pivSignFile {
    return Intl.message('Sign File', name: 'pivSignFile', desc: '', args: []);
  }

  /// `Verify File`
  String get pivVerifyFile {
    return Intl.message(
      'Verify File',
      name: 'pivVerifyFile',
      desc: '',
      args: [],
    );
  }

  /// `Clear Slot`
  String get pivClearSlot {
    return Intl.message('Clear Slot', name: 'pivClearSlot', desc: '', args: []);
  }

  /// `Move Key`
  String get pivMoveKey {
    return Intl.message('Move Key', name: 'pivMoveKey', desc: '', args: []);
  }

  /// `Public Key`
  String get pivPublicKey {
    return Intl.message('Public Key', name: 'pivPublicKey', desc: '', args: []);
  }

  /// `Signature Algorithm`
  String get pivSignatureAlgorithm {
    return Intl.message(
      'Signature Algorithm',
      name: 'pivSignatureAlgorithm',
      desc: '',
      args: [],
    );
  }

  /// `SHA-256 Fingerprint`
  String get pivSha256Fingerprint {
    return Intl.message(
      'SHA-256 Fingerprint',
      name: 'pivSha256Fingerprint',
      desc: '',
      args: [],
    );
  }

  /// `Certificate Size`
  String get pivCertificateSize {
    return Intl.message(
      'Certificate Size',
      name: 'pivCertificateSize',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get pivCertificateSubject {
    return Intl.message(
      'Subject',
      name: 'pivCertificateSubject',
      desc: '',
      args: [],
    );
  }

  /// `Issuer`
  String get pivCertificateIssuer {
    return Intl.message(
      'Issuer',
      name: 'pivCertificateIssuer',
      desc: '',
      args: [],
    );
  }

  /// `Serial`
  String get pivCertificateSerial {
    return Intl.message(
      'Serial',
      name: 'pivCertificateSerial',
      desc: '',
      args: [],
    );
  }

  /// `Valid from`
  String get pivCertificateValidFrom {
    return Intl.message(
      'Valid from',
      name: 'pivCertificateValidFrom',
      desc: '',
      args: [],
    );
  }

  /// `Valid to`
  String get pivCertificateValidTo {
    return Intl.message(
      'Valid to',
      name: 'pivCertificateValidTo',
      desc: '',
      args: [],
    );
  }

  /// `Provisioning`
  String get pivProvisioning {
    return Intl.message(
      'Provisioning',
      name: 'pivProvisioning',
      desc: '',
      args: [],
    );
  }

  /// `Key operations`
  String get pivDiagnostics {
    return Intl.message(
      'Key operations',
      name: 'pivDiagnostics',
      desc: '',
      args: [],
    );
  }

  /// `Danger Zone`
  String get pivDangerZone {
    return Intl.message(
      'Danger Zone',
      name: 'pivDangerZone',
      desc: '',
      args: [],
    );
  }

  /// `Creates a detached raw signature for the selected file.`
  String get pivSignFilePrompt {
    return Intl.message(
      'Creates a detached raw signature for the selected file.',
      name: 'pivSignFilePrompt',
      desc: '',
      args: [],
    );
  }

  /// `No file selected`
  String get pivNoFileSelected {
    return Intl.message(
      'No file selected',
      name: 'pivNoFileSelected',
      desc: '',
      args: [],
    );
  }

  /// `Select a file first.`
  String get pivSelectFileFirst {
    return Intl.message(
      'Select a file first.',
      name: 'pivSelectFileFirst',
      desc: '',
      args: [],
    );
  }

  /// `File signing failed`
  String get pivFileSigningFailed {
    return Intl.message(
      'File signing failed',
      name: 'pivFileSigningFailed',
      desc: '',
      args: [],
    );
  }

  /// `Sign`
  String get pivSign {
    return Intl.message('Sign', name: 'pivSign', desc: '', args: []);
  }

  /// `Verify File Signature`
  String get pivVerifyFileSignature {
    return Intl.message(
      'Verify File Signature',
      name: 'pivVerifyFileSignature',
      desc: '',
      args: [],
    );
  }

  /// `Verifies a detached raw signature against this slot public key.`
  String get pivVerifyFileSignaturePrompt {
    return Intl.message(
      'Verifies a detached raw signature against this slot public key.',
      name: 'pivVerifyFileSignaturePrompt',
      desc: '',
      args: [],
    );
  }

  /// `File`
  String get pivFile {
    return Intl.message('File', name: 'pivFile', desc: '', args: []);
  }

  /// `Signature`
  String get pivSignatureFile {
    return Intl.message(
      'Signature',
      name: 'pivSignatureFile',
      desc: '',
      args: [],
    );
  }

  /// `Signature verified`
  String get pivSignatureVerified {
    return Intl.message(
      'Signature verified',
      name: 'pivSignatureVerified',
      desc: '',
      args: [],
    );
  }

  /// `Select a file and signature first.`
  String get pivSelectFileAndSignatureFirst {
    return Intl.message(
      'Select a file and signature first.',
      name: 'pivSelectFileAndSignatureFirst',
      desc: '',
      args: [],
    );
  }

  /// `Signature verification failed`
  String get pivSignatureVerificationFailed {
    return Intl.message(
      'Signature verification failed',
      name: 'pivSignatureVerificationFailed',
      desc: '',
      args: [],
    );
  }

  /// `Verify`
  String get pivVerify {
    return Intl.message('Verify', name: 'pivVerify', desc: '', args: []);
  }

  /// `Not selected`
  String get pivNotSelected {
    return Intl.message(
      'Not selected',
      name: 'pivNotSelected',
      desc: '',
      args: [],
    );
  }

  /// `Select a certificate or private key first.`
  String get pivSelectCertificateOrKeyFirst {
    return Intl.message(
      'Select a certificate or private key first.',
      name: 'pivSelectCertificateOrKeyFirst',
      desc: '',
      args: [],
    );
  }

  /// `Importing a private key`
  String get pivImportingPrivateKey {
    return Intl.message(
      'Importing a private key',
      name: 'pivImportingPrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `Import failed`
  String get pivImportFailed {
    return Intl.message(
      'Import failed',
      name: 'pivImportFailed',
      desc: '',
      args: [],
    );
  }

  /// `Import succeeded`
  String get pivImportSucceeded {
    return Intl.message(
      'Import succeeded',
      name: 'pivImportSucceeded',
      desc: '',
      args: [],
    );
  }

  /// `Unsupported file. Use PEM or DER certificate/private key files.`
  String get pivUnsupportedImportFile {
    return Intl.message(
      'Unsupported file. Use PEM or DER certificate/private key files.',
      name: 'pivUnsupportedImportFile',
      desc: '',
      args: [],
    );
  }

  /// `Verify PIN and Management Key`
  String get pivVerifyPinAndManagementKey {
    return Intl.message(
      'Verify PIN and Management Key',
      name: 'pivVerifyPinAndManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `Select File`
  String get pivSelectFile {
    return Intl.message(
      'Select File',
      name: 'pivSelectFile',
      desc: '',
      args: [],
    );
  }

  /// `Click to select a PEM or DER certificate/key`
  String get pivSelectFilePrompt {
    return Intl.message(
      'Click to select a PEM or DER certificate/key',
      name: 'pivSelectFilePrompt',
      desc: '',
      args: [],
    );
  }

  /// `(Make sure the file contains a plaintext key or a certificate)`
  String get pivSelectFileHint {
    return Intl.message(
      '(Make sure the file contains a plaintext key or a certificate)',
      name: 'pivSelectFileHint',
      desc: '',
      args: [],
    );
  }

  /// `PIN and Touch Policy`
  String get pivPinAndTouchPolicy {
    return Intl.message(
      'PIN and Touch Policy',
      name: 'pivPinAndTouchPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Review`
  String get pivReview {
    return Intl.message('Review', name: 'pivReview', desc: '', args: []);
  }

  /// `Private Key`
  String get pivPrivateKey {
    return Intl.message(
      'Private Key',
      name: 'pivPrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `Certificate Key`
  String get pivCertificateKey {
    return Intl.message(
      'Certificate Key',
      name: 'pivCertificateKey',
      desc: '',
      args: [],
    );
  }

  /// `Certificate matches the private key`
  String get pivCertificateMatchesPrivateKey {
    return Intl.message(
      'Certificate matches the private key',
      name: 'pivCertificateMatchesPrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `Certificate does not match the private key`
  String get pivCertificateMismatchPrivateKey {
    return Intl.message(
      'Certificate does not match the private key',
      name: 'pivCertificateMismatchPrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `Creating a self-signed certificate`
  String get pivCreatingSelfSignedCertificate {
    return Intl.message(
      'Creating a self-signed certificate',
      name: 'pivCreatingSelfSignedCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Generating a CSR`
  String get pivGeneratingCsr {
    return Intl.message(
      'Generating a CSR',
      name: 'pivGeneratingCsr',
      desc: '',
      args: [],
    );
  }

  /// `Create Certificate Failed`
  String get pivCreateCertificateFailed {
    return Intl.message(
      'Create Certificate Failed',
      name: 'pivCreateCertificateFailed',
      desc: '',
      args: [],
    );
  }

  /// `Certificate Created`
  String get pivCertificateCreated {
    return Intl.message(
      'Certificate Created',
      name: 'pivCertificateCreated',
      desc: '',
      args: [],
    );
  }

  /// `Generate CSR Failed`
  String get pivGenerateCsrFailed {
    return Intl.message(
      'Generate CSR Failed',
      name: 'pivGenerateCsrFailed',
      desc: '',
      args: [],
    );
  }

  /// `CSR Generated`
  String get pivCsrGenerated {
    return Intl.message(
      'CSR Generated',
      name: 'pivCsrGenerated',
      desc: '',
      args: [],
    );
  }

  /// `Self-sign Certificate`
  String get pivSelfSignCertificate {
    return Intl.message(
      'Self-sign Certificate',
      name: 'pivSelfSignCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Create Certificate`
  String get pivCreateCertificate {
    return Intl.message(
      'Create Certificate',
      name: 'pivCreateCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Key Options`
  String get pivKeyOptions {
    return Intl.message(
      'Key Options',
      name: 'pivKeyOptions',
      desc: '',
      args: [],
    );
  }

  /// `Certificate Subject`
  String get pivCertificateSubjectStep {
    return Intl.message(
      'Certificate Subject',
      name: 'pivCertificateSubjectStep',
      desc: '',
      args: [],
    );
  }

  /// `CSR Subject`
  String get pivCsrSubject {
    return Intl.message(
      'CSR Subject',
      name: 'pivCsrSubject',
      desc: '',
      args: [],
    );
  }

  /// `Common Name`
  String get pivCommonName {
    return Intl.message(
      'Common Name',
      name: 'pivCommonName',
      desc: '',
      args: [],
    );
  }

  /// `Organization`
  String get pivOrganization {
    return Intl.message(
      'Organization',
      name: 'pivOrganization',
      desc: '',
      args: [],
    );
  }

  /// `Organizational Unit`
  String get pivOrganizationalUnit {
    return Intl.message(
      'Organizational Unit',
      name: 'pivOrganizationalUnit',
      desc: '',
      args: [],
    );
  }

  /// `Country Code`
  String get pivCountryCode {
    return Intl.message(
      'Country Code',
      name: 'pivCountryCode',
      desc: '',
      args: [],
    );
  }

  /// `DNS SANs, comma separated`
  String get pivDnsSans {
    return Intl.message(
      'DNS SANs, comma separated',
      name: 'pivDnsSans',
      desc: '',
      args: [],
    );
  }

  /// `Validity Days`
  String get pivValidityDays {
    return Intl.message(
      'Validity Days',
      name: 'pivValidityDays',
      desc: '',
      args: [],
    );
  }

  /// `Self-signed certificates are for local testing and compatibility depends on the client.`
  String get pivSelfSignedCertificateWarning {
    return Intl.message(
      'Self-signed certificates are for local testing and compatibility depends on the client.',
      name: 'pivSelfSignedCertificateWarning',
      desc: '',
      args: [],
    );
  }

  /// `CSR generation signs the request with the new key on the card.`
  String get pivCsrGenerationPrompt {
    return Intl.message(
      'CSR generation signs the request with the new key on the card.',
      name: 'pivCsrGenerationPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Generating an X25519 key`
  String get pivGeneratingX25519Key {
    return Intl.message(
      'Generating an X25519 key',
      name: 'pivGeneratingX25519Key',
      desc: '',
      args: [],
    );
  }

  /// `Generate X25519 Key Failed`
  String get pivGenerateX25519KeyFailed {
    return Intl.message(
      'Generate X25519 Key Failed',
      name: 'pivGenerateX25519KeyFailed',
      desc: '',
      args: [],
    );
  }

  /// `X25519 Key Generated`
  String get pivX25519KeyGenerated {
    return Intl.message(
      'X25519 Key Generated',
      name: 'pivX25519KeyGenerated',
      desc: '',
      args: [],
    );
  }

  /// `Generate X25519`
  String get pivGenerateX25519 {
    return Intl.message(
      'Generate X25519',
      name: 'pivGenerateX25519',
      desc: '',
      args: [],
    );
  }

  /// `CSR Copied`
  String get pivCsrCopied {
    return Intl.message('CSR Copied', name: 'pivCsrCopied', desc: '', args: []);
  }

  /// `A self-signed certificate was written to slot {slot}.`
  String pivCertificateWritten(Object slot) {
    return Intl.message(
      'A self-signed certificate was written to slot $slot.',
      name: 'pivCertificateWritten',
      desc: '',
      args: [slot],
    );
  }

  /// `Certificate Copied`
  String get pivCertificateCopied {
    return Intl.message(
      'Certificate Copied',
      name: 'pivCertificateCopied',
      desc: '',
      args: [],
    );
  }

  /// `Copy PEM`
  String get pivCopyPem {
    return Intl.message('Copy PEM', name: 'pivCopyPem', desc: '', args: []);
  }

  /// `Save PEM`
  String get pivSavePem {
    return Intl.message('Save PEM', name: 'pivSavePem', desc: '', args: []);
  }

  /// `Attestation is unavailable. The device must have an F9 attestation key and certificate.`
  String get pivAttestationUnavailable {
    return Intl.message(
      'Attestation is unavailable. The device must have an F9 attestation key and certificate.',
      name: 'pivAttestationUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `No empty destination slot is available.`
  String get pivNoEmptyDestinationSlot {
    return Intl.message(
      'No empty destination slot is available.',
      name: 'pivNoEmptyDestinationSlot',
      desc: '',
      args: [],
    );
  }

  /// `Move Key from {sourceSlot}`
  String pivMoveKeyFrom(Object sourceSlot) {
    return Intl.message(
      'Move Key from $sourceSlot',
      name: 'pivMoveKeyFrom',
      desc: '',
      args: [sourceSlot],
    );
  }

  /// `Only the private key is moved. Certificates remain in their current slots.`
  String get pivMoveKeyPrompt {
    return Intl.message(
      'Only the private key is moved. Certificates remain in their current slots.',
      name: 'pivMoveKeyPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Destination slot`
  String get pivDestinationSlot {
    return Intl.message(
      'Destination slot',
      name: 'pivDestinationSlot',
      desc: '',
      args: [],
    );
  }

  /// `Key move failed. The destination must not contain a key.`
  String get pivMoveKeyFailed {
    return Intl.message(
      'Key move failed. The destination must not contain a key.',
      name: 'pivMoveKeyFailed',
      desc: '',
      args: [],
    );
  }

  /// `Key moved`
  String get pivKeyMoved {
    return Intl.message('Key moved', name: 'pivKeyMoved', desc: '', args: []);
  }

  /// `Clear Slot {slot}`
  String pivClearSlotTitle(Object slot) {
    return Intl.message(
      'Clear Slot $slot',
      name: 'pivClearSlotTitle',
      desc: '',
      args: [slot],
    );
  }

  /// `This removes both the private key and certificate from this slot. Make sure you have another way to authenticate.`
  String get pivClearSlotPrompt {
    return Intl.message(
      'This removes both the private key and certificate from this slot. Make sure you have another way to authenticate.',
      name: 'pivClearSlotPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Clear slot failed. Make sure the firmware supports key deletion.`
  String get pivClearSlotFailed {
    return Intl.message(
      'Clear slot failed. Make sure the firmware supports key deletion.',
      name: 'pivClearSlotFailed',
      desc: '',
      args: [],
    );
  }

  /// `Slot cleared`
  String get pivSlotCleared {
    return Intl.message(
      'Slot cleared',
      name: 'pivSlotCleared',
      desc: '',
      args: [],
    );
  }

  /// `PIN: {policy}`
  String pivPinPolicyChip(Object policy) {
    return Intl.message(
      'PIN: $policy',
      name: 'pivPinPolicyChip',
      desc: '',
      args: [policy],
    );
  }

  /// `Touch: {policy}`
  String pivTouchPolicyChip(Object policy) {
    return Intl.message(
      'Touch: $policy',
      name: 'pivTouchPolicyChip',
      desc: '',
      args: [policy],
    );
  }

  /// `At least {min} characters`
  String validationAtLeastCharacters(Object min) {
    return Intl.message(
      'At least $min characters',
      name: 'validationAtLeastCharacters',
      desc: '',
      args: [min],
    );
  }

  /// `At most {max} characters`
  String validationAtMostCharacters(Object max) {
    return Intl.message(
      'At most $max characters',
      name: 'validationAtMostCharacters',
      desc: '',
      args: [max],
    );
  }

  /// `PIN confirmation does not match`
  String get pinConfirmationMismatch {
    return Intl.message(
      'PIN confirmation does not match',
      name: 'pinConfirmationMismatch',
      desc: '',
      args: [],
    );
  }

  /// `User PIN length must be between 6 and 64 characters.`
  String get openpgpUserPinLength {
    return Intl.message(
      'User PIN length must be between 6 and 64 characters.',
      name: 'openpgpUserPinLength',
      desc: '',
      args: [],
    );
  }

  /// `Current Admin PIN`
  String get openpgpCurrentAdminPin {
    return Intl.message(
      'Current Admin PIN',
      name: 'openpgpCurrentAdminPin',
      desc: '',
      args: [],
    );
  }

  /// `New Admin PIN`
  String get openpgpNewAdminPin {
    return Intl.message(
      'New Admin PIN',
      name: 'openpgpNewAdminPin',
      desc: '',
      args: [],
    );
  }

  /// `Admin PIN length must be between 8 and 64 characters.`
  String get openpgpAdminPinLength {
    return Intl.message(
      'Admin PIN length must be between 8 and 64 characters.',
      name: 'openpgpAdminPinLength',
      desc: '',
      args: [],
    );
  }

  /// `Imported`
  String get openpgpKeyImported {
    return Intl.message(
      'Imported',
      name: 'openpgpKeyImported',
      desc: '',
      args: [],
    );
  }

  /// `Empty`
  String get openpgpKeyEmpty {
    return Intl.message('Empty', name: 'openpgpKeyEmpty', desc: '', args: []);
  }

  /// `Touch: Off`
  String get openpgpTouchOffLabel {
    return Intl.message(
      'Touch: Off',
      name: 'openpgpTouchOffLabel',
      desc: '',
      args: [],
    );
  }

  /// `Touch: On`
  String get openpgpTouchOnLabel {
    return Intl.message(
      'Touch: On',
      name: 'openpgpTouchOnLabel',
      desc: '',
      args: [],
    );
  }

  /// `Touch: Permanent`
  String get openpgpTouchPermanentLabel {
    return Intl.message(
      'Touch: Permanent',
      name: 'openpgpTouchPermanentLabel',
      desc: '',
      args: [],
    );
  }

  /// `Touch: Cached`
  String get openpgpTouchCachedLabel {
    return Intl.message(
      'Touch: Cached',
      name: 'openpgpTouchCachedLabel',
      desc: '',
      args: [],
    );
  }

  /// `Touch: Permanent cached`
  String get openpgpTouchPermanentCachedLabel {
    return Intl.message(
      'Touch: Permanent cached',
      name: 'openpgpTouchPermanentCachedLabel',
      desc: '',
      args: [],
    );
  }

  /// `0 sec (off)`
  String get openpgpTouchCacheOff {
    return Intl.message(
      '0 sec (off)',
      name: 'openpgpTouchCacheOff',
      desc: '',
      args: [],
    );
  }

  /// `{seconds} sec`
  String openpgpTouchCacheSeconds(Object seconds) {
    return Intl.message(
      '$seconds sec',
      name: 'openpgpTouchCacheSeconds',
      desc: '',
      args: [seconds],
    );
  }

  /// `No touch`
  String get openpgpTouchNone {
    return Intl.message(
      'No touch',
      name: 'openpgpTouchNone',
      desc: '',
      args: [],
    );
  }

  /// `Requires touch`
  String get openpgpTouchRequired {
    return Intl.message(
      'Requires touch',
      name: 'openpgpTouchRequired',
      desc: '',
      args: [],
    );
  }

  /// `Permanent`
  String get openpgpTouchPermanent {
    return Intl.message(
      'Permanent',
      name: 'openpgpTouchPermanent',
      desc: '',
      args: [],
    );
  }

  /// `Cached touch`
  String get openpgpTouchCached {
    return Intl.message(
      'Cached touch',
      name: 'openpgpTouchCached',
      desc: '',
      args: [],
    );
  }

  /// `Permanent cached`
  String get openpgpTouchPermanentCached {
    return Intl.message(
      'Permanent cached',
      name: 'openpgpTouchPermanentCached',
      desc: '',
      args: [],
    );
  }

  /// `Reset Code`
  String get openpgpResetCode {
    return Intl.message(
      'Reset Code',
      name: 'openpgpResetCode',
      desc: '',
      args: [],
    );
  }

  /// `Signature PIN`
  String get openpgpSignaturePin {
    return Intl.message(
      'Signature PIN',
      name: 'openpgpSignaturePin',
      desc: '',
      args: [],
    );
  }

  /// `Verify every signature`
  String get openpgpVerifyEverySignature {
    return Intl.message(
      'Verify every signature',
      name: 'openpgpVerifyEverySignature',
      desc: '',
      args: [],
    );
  }

  /// `Verify once after insertion`
  String get openpgpVerifyOnceAfterInsertion {
    return Intl.message(
      'Verify once after insertion',
      name: 'openpgpVerifyOnceAfterInsertion',
      desc: '',
      args: [],
    );
  }

  /// `Retries: unknown`
  String get openpgpRetriesUnknown {
    return Intl.message(
      'Retries: unknown',
      name: 'openpgpRetriesUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Retries: {remaining}`
  String openpgpRetries(Object remaining) {
    return Intl.message(
      'Retries: $remaining',
      name: 'openpgpRetries',
      desc: '',
      args: [remaining],
    );
  }

  /// `Unblock User PIN`
  String get openpgpUnblockUserPin {
    return Intl.message(
      'Unblock User PIN',
      name: 'openpgpUnblockUserPin',
      desc: '',
      args: [],
    );
  }

  /// `Set Reset Code`
  String get openpgpSetResetCode {
    return Intl.message(
      'Set Reset Code',
      name: 'openpgpSetResetCode',
      desc: '',
      args: [],
    );
  }

  /// `Set PIN Retries`
  String get openpgpSetPinRetries {
    return Intl.message(
      'Set PIN Retries',
      name: 'openpgpSetPinRetries',
      desc: '',
      args: [],
    );
  }

  /// `Signature PIN Policy`
  String get openpgpSignaturePinPolicy {
    return Intl.message(
      'Signature PIN Policy',
      name: 'openpgpSignaturePinPolicy',
      desc: '',
      args: [],
    );
  }

  /// `I understand this makes touch permanently enabled for this key.`
  String get openpgpPermanentTouchConfirmation {
    return Intl.message(
      'I understand this makes touch permanently enabled for this key.',
      name: 'openpgpPermanentTouchConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Set Touch Cache Time`
  String get openpgpSetTouchCacheTime {
    return Intl.message(
      'Set Touch Cache Time',
      name: 'openpgpSetTouchCacheTime',
      desc: '',
      args: [],
    );
  }

  /// `Set how long one touch confirmation can be reused. 0 means every operation needs a new touch. Admin PIN is required.`
  String get openpgpSetTouchCacheTimePrompt {
    return Intl.message(
      'Set how long one touch confirmation can be reused. 0 means every operation needs a new touch. Admin PIN is required.',
      name: 'openpgpSetTouchCacheTimePrompt',
      desc: '',
      args: [],
    );
  }

  /// `Cache seconds`
  String get openpgpCacheSeconds {
    return Intl.message(
      'Cache seconds',
      name: 'openpgpCacheSeconds',
      desc: '',
      args: [],
    );
  }

  /// `Reset Code must be between 8 and 64 characters. Admin PIN is required.`
  String get openpgpSetResetCodePrompt {
    return Intl.message(
      'Reset Code must be between 8 and 64 characters. Admin PIN is required.',
      name: 'openpgpSetResetCodePrompt',
      desc: '',
      args: [],
    );
  }

  /// `Change Signature PIN Policy`
  String get openpgpChangeSignaturePinPolicy {
    return Intl.message(
      'Change Signature PIN Policy',
      name: 'openpgpChangeSignaturePinPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Verify User PIN for every signature`
  String get openpgpVerifyEverySignaturePrompt {
    return Intl.message(
      'Verify User PIN for every signature',
      name: 'openpgpVerifyEverySignaturePrompt',
      desc: '',
      args: [],
    );
  }

  /// `Verify once after card insertion`
  String get openpgpVerifyOnceAfterInsertionPrompt {
    return Intl.message(
      'Verify once after card insertion',
      name: 'openpgpVerifyOnceAfterInsertionPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Set PIN/Reset/Admin PIN Retries`
  String get openpgpSetPinRetriesTitle {
    return Intl.message(
      'Set PIN/Reset/Admin PIN Retries',
      name: 'openpgpSetPinRetriesTitle',
      desc: '',
      args: [],
    );
  }

  /// `This resets User PIN to 123456 and Admin PIN to 12345678.`
  String get openpgpSetPinRetriesPrompt {
    return Intl.message(
      'This resets User PIN to 123456 and Admin PIN to 12345678.',
      name: 'openpgpSetPinRetriesPrompt',
      desc: '',
      args: [],
    );
  }

  /// `User PIN`
  String get openpgpUserPin {
    return Intl.message('User PIN', name: 'openpgpUserPin', desc: '', args: []);
  }

  /// `Admin PIN`
  String get openpgpAdminPin {
    return Intl.message(
      'Admin PIN',
      name: 'openpgpAdminPin',
      desc: '',
      args: [],
    );
  }

  /// `Use Admin PIN`
  String get openpgpUseAdminPin {
    return Intl.message(
      'Use Admin PIN',
      name: 'openpgpUseAdminPin',
      desc: '',
      args: [],
    );
  }

  /// `Use Reset Code`
  String get openpgpUseResetCode {
    return Intl.message(
      'Use Reset Code',
      name: 'openpgpUseResetCode',
      desc: '',
      args: [],
    );
  }

  /// `Please input a valid hexadecimal string.`
  String get validationHexString {
    return Intl.message(
      'Please input a valid hexadecimal string.',
      name: 'validationHexString',
      desc: '',
      args: [],
    );
  }

  /// `Need exact {length} characters`
  String validationExactLength(Object length) {
    return Intl.message(
      'Need exact $length characters',
      name: 'validationExactLength',
      desc: '',
      args: [length],
    );
  }

  /// `Passkey`
  String get passkey {
    return Intl.message('Passkey', name: 'passkey', desc: '', args: []);
  }

  /// `View User ID`
  String get viewUserId {
    return Intl.message('View User ID', name: 'viewUserId', desc: '', args: []);
  }

  /// `Save the PIN on this device`
  String get savePinOnDevice {
    return Intl.message(
      'Save the PIN on this device',
      name: 'savePinOnDevice',
      desc: '',
      args: [],
    );
  }

  /// `Clear Saved PINs`
  String get settingsClearPinCache {
    return Intl.message(
      'Clear Saved PINs',
      name: 'settingsClearPinCache',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to clear all saved PINs from this device?`
  String get settingsClearPinCachePrompt {
    return Intl.message(
      'Are you sure you want to clear all saved PINs from this device?',
      name: 'settingsClearPinCachePrompt',
      desc: '',
      args: [],
    );
  }

  /// `Your CanoKey does not support Pass.`
  String get passNotSupported {
    return Intl.message(
      'Your CanoKey does not support Pass.',
      name: 'passNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `CanoKey Console is the console app for CanoKey, an open-source security key.`
  String get appDescription {
    return Intl.message(
      'CanoKey Console is the console app for CanoKey, an open-source security key.',
      name: 'appDescription',
      desc: '',
      args: [],
    );
  }

  /// `Summer Xu is the author of NFC interaction sounds.`
  String get soundCredit {
    return Intl.message(
      'Summer Xu is the author of NFC interaction sounds.',
      name: 'soundCredit',
      desc: '',
      args: [],
    );
  }

  /// `Source code available on GitHub: `
  String get beforeSourceLink {
    return Intl.message(
      'Source code available on GitHub: ',
      name: 'beforeSourceLink',
      desc: '',
      args: [],
    );
  }

  /// `NFC interaction sound`
  String get nfcSound {
    return Intl.message(
      'NFC interaction sound',
      name: 'nfcSound',
      desc: '',
      args: [],
    );
  }

  /// `Sound disabled`
  String get disableSound {
    return Intl.message(
      'Sound disabled',
      name: 'disableSound',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get play {
    return Intl.message('Play', name: 'play', desc: '', args: []);
  }

  /// `Playing in order: poll, finish, error`
  String get nfcSoundPrompt {
    return Intl.message(
      'Playing in order: poll, finish, error',
      name: 'nfcSoundPrompt',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
