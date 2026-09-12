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
    final name = (locale.countryCode?.isEmpty ?? false)
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

  /// `Pull down or tap refresh, then hold your iPhone near your CanoKey, or insert it into the USB port`
  String get iosPollCanoKeyPrompt {
    return Intl.message(
      'Pull down or tap refresh, then hold your iPhone near your CanoKey, or insert it into the USB port',
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

  /// `Could not connect to CanoKey over USB. Check the connection, then reopen this app. Error details:`
  String get desktopPollError {
    return Intl.message(
      'Could not connect to CanoKey over USB. Check the connection, then reopen this app. Error details:',
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

  /// `Could not communicate with CanoKey. Reconnect it and try again.`
  String get networkError {
    return Intl.message(
      'Could not communicate with CanoKey. Reconnect it and try again.',
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

  /// `The new PIN must contain {min} to {max} characters.`
  String changePinPrompt(Object min, Object max) {
    return Intl.message(
      'The new PIN must contain $min to $max characters.',
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

  /// `Keep CanoKey near your phone until reading finishes.`
  String get readingAlertMessage {
    return Intl.message(
      'Keep CanoKey near your phone until reading finishes.',
      name: 'readingAlertMessage',
      desc: '',
      args: [],
    );
  }

  /// `The connection was interrupted. Reconnect CanoKey. For NFC, keep it near your phone.`
  String get interrupted {
    return Intl.message(
      'The connection was interrupted. Reconnect CanoKey. For NFC, keep it near your phone.',
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

  /// `Connect CanoKey over USB to use this feature.`
  String get notSupportedInNFC {
    return Intl.message(
      'Connect CanoKey over USB to use this feature.',
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

  /// `Firmware source revision`
  String get settingsCoreCommit {
    return Intl.message(
      'Firmware source revision',
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

  /// `Storage used by each applet`
  String get settingsAppletStorageUsage {
    return Intl.message(
      'Storage used by each applet',
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

  /// `Enter the admin PIN used for Settings. The default is 123456. It is separate from the PINs for OpenPGP, PIV and other applets.`
  String get settingsInputPinPrompt {
    return Intl.message(
      'Enter the admin PIN used for Settings. The default is 123456. It is separate from the PINs for OpenPGP, PIV and other applets.',
      name: 'settingsInputPinPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Type HOTP on touch`
  String get settingsHotp {
    return Intl.message(
      'Type HOTP on touch',
      name: 'settingsHotp',
      desc: '',
      args: [],
    );
  }

  /// `Show WebUSB prompt when connected`
  String get settingsWebUSB {
    return Intl.message(
      'Show WebUSB prompt when connected',
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

  /// `NFC Tag Mode`
  String get settingsNDEF {
    return Intl.message(
      'NFC Tag Mode',
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

  /// `Choose what other devices read when they scan CanoKey over NFC.`
  String get ndefTagContentDescription {
    return Intl.message(
      'Choose what other devices read when they scan CanoKey over NFC.',
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

  /// `Link`
  String get ndefUri {
    return Intl.message('Link', name: 'ndefUri', desc: '', args: []);
  }

  /// `Text`
  String get ndefText {
    return Intl.message('Text', name: 'ndefText', desc: '', args: []);
  }

  /// `Link address`
  String get ndefUriValue {
    return Intl.message(
      'Link address',
      name: 'ndefUriValue',
      desc: '',
      args: [],
    );
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

  /// `Enter a full link, such as https://example.com or mailto:name@example.com.`
  String get ndefInvalidUri {
    return Intl.message(
      'Enter a full link, such as https://example.com or mailto:name@example.com.',
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

  /// `No records yet`
  String get ndefNoRecords {
    return Intl.message(
      'No records yet',
      name: 'ndefNoRecords',
      desc: '',
      args: [],
    );
  }

  /// `Add a link, text or other content for devices to read over NFC.`
  String get ndefNoRecordsDescription {
    return Intl.message(
      'Add a link, text or other content for devices to read over NFC.',
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

  /// `The NFC tag is read-only.`
  String get ndefReadOnly {
    return Intl.message(
      'The NFC tag is read-only.',
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

  /// `Could not read the existing NFC tag content. To start over, reset NFC Tag in Settings. This deletes the existing tag content.`
  String get ndefInvalidMessage {
    return Intl.message(
      'Could not read the existing NFC tag content. To start over, reset NFC Tag in Settings. This deletes the existing tag content.',
      name: 'ndefInvalidMessage',
      desc: '',
      args: [],
    );
  }

  /// `The content exceeds the NFC tag capacity. Remove some content and try again.`
  String get ndefCapacityExceeded {
    return Intl.message(
      'The content exceeds the NFC tag capacity. Remove some content and try again.',
      name: 'ndefCapacityExceeded',
      desc: '',
      args: [],
    );
  }

  /// `NFC tag records saved`
  String get ndefSaved {
    return Intl.message(
      'NFC tag records saved',
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

  /// `Android app`
  String get ndefAndroidApplication {
    return Intl.message(
      'Android app',
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

  /// `Hexadecimal data; optional`
  String get ndefOptionalHex {
    return Intl.message(
      'Hexadecimal data; optional',
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

  /// `Record content`
  String get ndefPayload {
    return Intl.message(
      'Record content',
      name: 'ndefPayload',
      desc: '',
      args: [],
    );
  }

  /// `Content encoding`
  String get ndefPayloadEncoding {
    return Intl.message(
      'Content encoding',
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

  /// `Could not convert the content. Check the hexadecimal format or confirm the content is valid UTF-8 text.`
  String get ndefPayloadConversionFailed {
    return Intl.message(
      'Could not convert the content. Check the hexadecimal format or confirm the content is valid UTF-8 text.',
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

  /// `Could not save this record. Check the fields. Details: {error}`
  String ndefInvalidRecord(Object error) {
    return Intl.message(
      'Could not save this record. Check the fields. Details: $error',
      name: 'ndefInvalidRecord',
      desc: '',
      args: [error],
    );
  }

  /// `Fill in this field.`
  String get ndefRequiredField {
    return Intl.message(
      'Fill in this field.',
      name: 'ndefRequiredField',
      desc: '',
      args: [],
    );
  }

  /// `The selected record format requires the type name to be empty. Clear that field.`
  String get ndefTnfRequiresEmptyType {
    return Intl.message(
      'The selected record format requires the type name to be empty. Clear that field.',
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

  /// `Reset OTP`
  String get settingsResetOATH {
    return Intl.message(
      'Reset OTP',
      name: 'settingsResetOATH',
      desc: '',
      args: [],
    );
  }

  /// `Reset NFC Tag`
  String get settingsResetNDEF {
    return Intl.message(
      'Reset NFC Tag',
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

  /// `Resetting {applet} will permanently delete all its data.`
  String settingsResetApplet(Object applet) {
    return Intl.message(
      'Resetting $applet will permanently delete all its data.',
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

  /// `Cannot reset while the PIN is not blocked.`
  String get settingsResetConditionNotSatisfying {
    return Intl.message(
      'Cannot reset while the PIN is not blocked.',
      name: 'settingsResetConditionNotSatisfying',
      desc: '',
      args: [],
    );
  }

  /// `CanoKey was not touched in time. Try again and touch it when the light flashes.`
  String get settingsResetPresenceTestFailed {
    return Intl.message(
      'CanoKey was not touched in time. Try again and touch it when the light flashes.',
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

  /// `Press Enter after typing an OTP`
  String get settingsKeyboardWithReturn {
    return Intl.message(
      'Press Enter after typing an OTP',
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

  /// `Your current keyboard layout is custom. Selecting a built-in layout will replace it.`
  String get settingsKeyboardLayoutUnknownPrompt {
    return Intl.message(
      'Your current keyboard layout is custom. Selecting a built-in layout will replace it.',
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

  /// `Deleting {name} permanently removes its one-time codes from CanoKey. Make sure you have another verification method or have disabled two-step verification for this service.`
  String oathDelete(Object name) {
    return Intl.message(
      'Deleting $name permanently removes its one-time codes from CanoKey. Make sure you have another verification method or have disabled two-step verification for this service.',
      name: 'oathDelete',
      desc: '',
      args: [name],
    );
  }

  /// `Type a code for {name} when you touch CanoKey? This replaces the current touch output setting.`
  String oathSetDefaultPrompt(Object name) {
    return Intl.message(
      'Type a code for $name when you touch CanoKey? This replaces the current touch output setting.',
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

  /// `Update interval (seconds)`
  String get oathPeriod {
    return Intl.message(
      'Update interval (seconds)',
      name: 'oathPeriod',
      desc: '',
      args: [],
    );
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

  /// `Fill in this field`
  String get oathRequired {
    return Intl.message(
      'Fill in this field',
      name: 'oathRequired',
      desc: '',
      args: [],
    );
  }

  /// `Too long`
  String get oathTooLong {
    return Intl.message('Too long', name: 'oathTooLong', desc: '', args: []);
  }

  /// `Counter`
  String get oathCounter {
    return Intl.message('Counter', name: 'oathCounter', desc: '', args: []);
  }

  /// `Enter a whole number`
  String get oathCounterMustBeNumber {
    return Intl.message(
      'Enter a whole number',
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

  /// `Enter the passphrase that protects the OTP accounts on this CanoKey.`
  String get oathInputCodePrompt {
    return Intl.message(
      'Enter the passphrase that protects the OTP accounts on this CanoKey.',
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

  /// `Enter a new passphrase. Leave it empty and save to remove passphrase protection.`
  String get oathNewCodePrompt {
    return Intl.message(
      'Enter a new passphrase. Leave it empty and save to remove passphrase protection.',
      name: 'oathNewCodePrompt',
      desc: '',
      args: [],
    );
  }

  /// `Use the settings provided by the service. Other settings may produce codes that do not work.`
  String get oathAdvancedSettings {
    return Intl.message(
      'Use the settings provided by the service. Other settings may produce codes that do not work.',
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

  /// `Enter the admin PIN used for Settings. The default is 123456.`
  String get passInputPinPrompt {
    return Intl.message(
      'Enter the admin PIN used for Settings. The default is 123456.',
      name: 'passInputPinPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Touch output settings`
  String get passSlotConfigTitle {
    return Intl.message(
      'Touch output settings',
      name: 'passSlotConfigTitle',
      desc: '',
      args: [],
    );
  }

  /// `Choose what happens when you touch CanoKey. To output HOTP codes, configure an account on the OTP page.`
  String get passSlotConfigPrompt {
    return Intl.message(
      'Choose what happens when you touch CanoKey. To output HOTP codes, configure an account on the OTP page.',
      name: 'passSlotConfigPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Short press`
  String get passSlotShort {
    return Intl.message(
      'Short press',
      name: 'passSlotShort',
      desc: '',
      args: [],
    );
  }

  /// `Long press`
  String get passSlotLong {
    return Intl.message('Long press', name: 'passSlotLong', desc: '', args: []);
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

  /// `Press Enter after typing`
  String get passSlotWithEnter {
    return Intl.message(
      'Press Enter after typing',
      name: 'passSlotWithEnter',
      desc: '',
      args: [],
    );
  }

  /// `This CanoKey does not support a WebAuthn PIN.`
  String get webauthnClientPinNotSupported {
    return Intl.message(
      'This CanoKey does not support a WebAuthn PIN.',
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

  /// `Set a WebAuthn PIN to manage sign-in credentials. Use 4 to 63 characters.`
  String get webauthnSetPinPrompt {
    return Intl.message(
      'Set a WebAuthn PIN to manage sign-in credentials. Use 4 to 63 characters.',
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

  /// `Delete the sign-in credential for {name}? This cannot be undone. Make sure you have another way to sign in.`
  String webauthnDelete(Object name) {
    return Intl.message(
      'Delete the sign-in credential for $name? This cannot be undone. Make sure you have another way to sign in.',
      name: 'webauthnDelete',
      desc: '',
      args: [name],
    );
  }

  /// `The WebAuthn PIN is temporarily blocked. Reconnect CanoKey and try again.`
  String get webauthnPinAuthBlocked {
    return Intl.message(
      'The WebAuthn PIN is temporarily blocked. Reconnect CanoKey and try again.',
      name: 'webauthnPinAuthBlocked',
      desc: '',
      args: [],
    );
  }

  /// `The WebAuthn PIN is blocked. Reset WebAuthn to use it again. Resetting deletes all WebAuthn credentials.`
  String get webauthnPinBlocked {
    return Intl.message(
      'The WebAuthn PIN is blocked. Reset WebAuthn to use it again. Resetting deletes all WebAuthn credentials.',
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

  /// `The new PUK must contain {min} to {max} characters.`
  String pivChangePUKPrompt(Object min, Object max) {
    return Intl.message(
      'The new PUK must contain $min to $max characters.',
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

  /// `Use default`
  String get pivUseDefaultManagementKey {
    return Intl.message(
      'Use default',
      name: 'pivUseDefaultManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `Generate random`
  String get pivRandomManagementKey {
    return Intl.message(
      'Generate random',
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

  /// `Key algorithm`
  String get pivAlgorithm {
    return Intl.message(
      'Key algorithm',
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

  /// `Delete the key and certificate in slot {slot}? This cannot be undone. Make sure you have another way to sign in or decrypt your data.`
  String pivDeleteSlot(Object slot) {
    return Intl.message(
      'Delete the key and certificate in slot $slot? This cannot be undone. Make sure you have another way to sign in or decrypt your data.',
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

  /// `Management key verification`
  String get pivManagementKeyAuthentication {
    return Intl.message(
      'Management key verification',
      name: 'pivManagementKeyAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `Verify with PIN`
  String get pivPinProtectedKeyOnCard {
    return Intl.message(
      'Verify with PIN',
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

  /// `For sign-in verification. Choose a key algorithm that supports signing.`
  String get pivSlotAuthenticationHint {
    return Intl.message(
      'For sign-in verification. Choose a key algorithm that supports signing.',
      name: 'pivSlotAuthenticationHint',
      desc: '',
      args: [],
    );
  }

  /// `For digital signatures. By default, the PIN is required for every signature.`
  String get pivSlotSignatureHint {
    return Intl.message(
      'For digital signatures. By default, the PIN is required for every signature.',
      name: 'pivSlotSignatureHint',
      desc: '',
      args: [],
    );
  }

  /// `For decryption or key agreement. X25519 supports key agreement only.`
  String get pivSlotKeyManagementHint {
    return Intl.message(
      'For decryption or key agreement. X25519 supports key agreement only.',
      name: 'pivSlotKeyManagementHint',
      desc: '',
      args: [],
    );
  }

  /// `For verifying the card's identity. Some uses do not require a PIN.`
  String get pivSlotCardAuthenticationHint {
    return Intl.message(
      'For verifying the card\'s identity. Some uses do not require a PIN.',
      name: 'pivSlotCardAuthenticationHint',
      desc: '',
      args: [],
    );
  }

  /// `Keep old decryption keys and certificates so you can still read previously encrypted data.`
  String get pivSlotRetiredHint {
    return Intl.message(
      'Keep old decryption keys and certificates so you can still read previously encrypted data.',
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

  /// `Check that the software you plan to use supports this algorithm.`
  String get pivExtendedAlgorithmCompatibilityWarning {
    return Intl.message(
      'Check that the software you plan to use supports this algorithm.',
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

  /// `Allow CanoKey to use extension algorithms.`
  String get pivAlgorithmIdsPrompt {
    return Intl.message(
      'Allow CanoKey to use extension algorithms.',
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

  /// `Keep the defaults unless your software or firmware requires different algorithm IDs. Incorrect IDs may prevent existing keys from being recognized until you restore the correct values.`
  String get pivAlgorithmIdsWarning {
    return Intl.message(
      'Keep the defaults unless your software or firmware requires different algorithm IDs. Incorrect IDs may prevent existing keys from being recognized until you restore the correct values.',
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

  /// `This resets PIN to 123456 and PUK to 12345678. Disable PIN-protected management key mode first.`
  String get pivSetPinPukRetriesPrompt {
    return Intl.message(
      'This resets PIN to 123456 and PUK to 12345678. Disable PIN-protected management key mode first.',
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

  /// `Retry limits changed, but some management information could not be saved. The PIN is now 123456 and the PUK is 12345678. Read CanoKey again to check its state.`
  String get pivSetRetriesMetadataFailed {
    return Intl.message(
      'Retry limits changed, but some management information could not be saved. The PIN is now 123456 and the PUK is 12345678. Read CanoKey again to check its state.',
      name: 'pivSetRetriesMetadataFailed',
      desc: '',
      args: [],
    );
  }

  /// `Retry limits changed. The PIN is now 123456 and the PUK is 12345678.`
  String get pivSetRetriesSuccess {
    return Intl.message(
      'Retry limits changed. The PIN is now 123456 and the PUK is 12345678.',
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

  /// `A random management key will be set and stored on the card, protected by PIN. PUK will be blocked and cannot recover a forgotten or blocked PIN. PIN/PUK retries cannot be reset while this mode is enabled.`
  String get pivEnablePinProtectedManagementKeyPrompt {
    return Intl.message(
      'A random management key will be set and stored on the card, protected by PIN. PUK will be blocked and cannot recover a forgotten or blocked PIN. PIN/PUK retries cannot be reset while this mode is enabled.',
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

  /// `A new management key will be set before the PIN-protected copy is cleared. PUK will remain blocked. To restore it, reset PIN/PUK retries after disabling this mode; this also resets the PIN.`
  String get pivDisablePinProtectedManagementKeyPrompt {
    return Intl.message(
      'A new management key will be set before the PIN-protected copy is cleared. PUK will remain blocked. To restore it, reset PIN/PUK retries after disabling this mode; this also resets the PIN.',
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

  /// `When enabled, future management operations can authenticate with PIN. This blocks PUK and prevents PIN recovery with PUK.`
  String get pivStoreManagementKeyOnCardPrompt {
    return Intl.message(
      'When enabled, future management operations can authenticate with PIN. This blocks PUK and prevents PIN recovery with PUK.',
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

  /// `Sign a file with this key. The signature is saved separately; the original file is not changed.`
  String get pivSignFilePrompt {
    return Intl.message(
      'Sign a file with this key. The signature is saved separately; the original file is not changed.',
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

  /// `Select the original file and its signature file to verify the signature using this slot's public key.`
  String get pivVerifyFileSignaturePrompt {
    return Intl.message(
      'Select the original file and its signature file to verify the signature using this slot\'s public key.',
      name: 'pivVerifyFileSignaturePrompt',
      desc: '',
      args: [],
    );
  }

  /// `File`
  String get pivFile {
    return Intl.message('File', name: 'pivFile', desc: '', args: []);
  }

  /// `Signature file`
  String get pivSignatureFile {
    return Intl.message(
      'Signature file',
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

  /// `Select the original file and its signature file first.`
  String get pivSelectFileAndSignatureFirst {
    return Intl.message(
      'Select the original file and its signature file first.',
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

  /// `Enter PIN and management key`
  String get pivVerifyPinAndManagementKey {
    return Intl.message(
      'Enter PIN and management key',
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

  /// `Choose a certificate or private key in PEM or DER format`
  String get pivSelectFilePrompt {
    return Intl.message(
      'Choose a certificate or private key in PEM or DER format',
      name: 'pivSelectFilePrompt',
      desc: '',
      args: [],
    );
  }

  /// `Private key files must not be password-protected.`
  String get pivSelectFileHint {
    return Intl.message(
      'Private key files must not be password-protected.',
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

  /// `Country or region code`
  String get pivCountryCode {
    return Intl.message(
      'Country or region code',
      name: 'pivCountryCode',
      desc: '',
      args: [],
    );
  }

  /// `Domain names (comma-separated)`
  String get pivDnsSans {
    return Intl.message(
      'Domain names (comma-separated)',
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

  /// `You may need to manually trust a self-signed certificate in the software that uses it. Check that the software accepts self-signed certificates.`
  String get pivSelfSignedCertificateWarning {
    return Intl.message(
      'You may need to manually trust a self-signed certificate in the software that uses it. Check that the software accepts self-signed certificates.',
      name: 'pivSelfSignedCertificateWarning',
      desc: '',
      args: [],
    );
  }

  /// `Create a certificate signing request (CSR) to send to a certificate authority. A new key will be generated on CanoKey.`
  String get pivCsrGenerationPrompt {
    return Intl.message(
      'Create a certificate signing request (CSR) to send to a certificate authority. A new key will be generated on CanoKey.',
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

  /// `No empty slot is available to receive this key.`
  String get pivNoEmptyDestinationSlot {
    return Intl.message(
      'No empty slot is available to receive this key.',
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

  /// `Could not move the key. Choose a destination slot with no key.`
  String get pivMoveKeyFailed {
    return Intl.message(
      'Could not move the key. Choose a destination slot with no key.',
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

  /// `Touch: Cached, cannot disable`
  String get openpgpTouchPermanentCachedLabel {
    return Intl.message(
      'Touch: Cached, cannot disable',
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

  /// `Cached touch (cannot disable)`
  String get openpgpTouchPermanentCached {
    return Intl.message(
      'Cached touch (cannot disable)',
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

  /// `Set PIN and Reset Code retry limits`
  String get openpgpSetPinRetriesTitle {
    return Intl.message(
      'Set PIN and Reset Code retry limits',
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

  /// `Enter exactly {length} characters`
  String validationExactLength(Object length) {
    return Intl.message(
      'Enter exactly $length characters',
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

  /// `NFC sounds by Summer Xu.`
  String get soundCredit {
    return Intl.message(
      'NFC sounds by Summer Xu.',
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

  /// `Preview order: reading started, reading completed, reading failed`
  String get nfcSoundPrompt {
    return Intl.message(
      'Preview order: reading started, reading completed, reading failed',
      name: 'nfcSoundPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get feedback {
    return Intl.message('Feedback', name: 'feedback', desc: '', args: []);
  }

  /// `Privacy Policy`
  String get privacyConsentTitle {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyConsentTitle',
      desc: '',
      args: [],
    );
  }

  /// `Thank you for using CanoKey Console. Please read and agree to our `
  String get privacyConsentBeforeLink {
    return Intl.message(
      'Thank you for using CanoKey Console. Please read and agree to our ',
      name: 'privacyConsentBeforeLink',
      desc: '',
      args: [],
    );
  }

  /// ` before continuing. We collect, use, and protect your personal information in accordance with the policy.`
  String get privacyConsentAfterLink {
    return Intl.message(
      ' before continuing. We collect, use, and protect your personal information in accordance with the policy.',
      name: 'privacyConsentAfterLink',
      desc: '',
      args: [],
    );
  }

  /// `Agree and Continue`
  String get agreeAndContinue {
    return Intl.message(
      'Agree and Continue',
      name: 'agreeAndContinue',
      desc: '',
      args: [],
    );
  }

  /// `Disagree and Exit`
  String get disagreeAndExit {
    return Intl.message(
      'Disagree and Exit',
      name: 'disagreeAndExit',
      desc: '',
      args: [],
    );
  }

  /// `View Logs`
  String get logsTitle {
    return Intl.message('View Logs', name: 'logsTitle', desc: '', args: []);
  }

  /// `Record logs`
  String get logsRecording {
    return Intl.message(
      'Record logs',
      name: 'logsRecording',
      desc: '',
      args: [],
    );
  }

  /// `No logs in this session`
  String get logsEmpty {
    return Intl.message(
      'No logs in this session',
      name: 'logsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Log copied`
  String get logsCopied {
    return Intl.message('Log copied', name: 'logsCopied', desc: '', args: []);
  }

  /// `Could not copy log`
  String get logsCopyFailed {
    return Intl.message(
      'Could not copy log',
      name: 'logsCopyFailed',
      desc: '',
      args: [],
    );
  }

  /// `Apply Mac login settings`
  String get pivMacOsApply {
    return Intl.message(
      'Apply Mac login settings',
      name: 'pivMacOsApply',
      desc: '',
      args: [],
    );
  }

  /// `Set up 9A to verify your identity when you sign in to your Mac. You also need a key and certificate in 9D to unlock your login keychain.`
  String get pivMacOsDescription {
    return Intl.message(
      'Set up 9A to verify your identity when you sign in to your Mac. You also need a key and certificate in 9D to unlock your login keychain.',
      name: 'pivMacOsDescription',
      desc: '',
      args: [],
    );
  }

  /// `For Mac login, set up 9A and 9D.`
  String get pivMacOsOtherSlot {
    return Intl.message(
      'For Mac login, set up 9A and 9D.',
      name: 'pivMacOsOtherSlot',
      desc: '',
      args: [],
    );
  }

  /// `Custom settings`
  String get pivCertificateCustom {
    return Intl.message(
      'Custom settings',
      name: 'pivCertificateCustom',
      desc: '',
      args: [],
    );
  }

  /// `Certificate extensions`
  String get pivCertificateExtensions {
    return Intl.message(
      'Certificate extensions',
      name: 'pivCertificateExtensions',
      desc: '',
      args: [],
    );
  }

  /// `Mark as a non-CA certificate (CA=false)`
  String get pivEndEntityConstraint {
    return Intl.message(
      'Mark as a non-CA certificate (CA=false)',
      name: 'pivEndEntityConstraint',
      desc: '',
      args: [],
    );
  }

  /// `Key Usage`
  String get pivKeyUsage {
    return Intl.message('Key Usage', name: 'pivKeyUsage', desc: '', args: []);
  }

  /// `Require verifiers to check key usage`
  String get pivKeyUsageCritical {
    return Intl.message(
      'Require verifiers to check key usage',
      name: 'pivKeyUsageCritical',
      desc: '',
      args: [],
    );
  }

  /// `Extended Key Usage`
  String get pivExtendedKeyUsage {
    return Intl.message(
      'Extended Key Usage',
      name: 'pivExtendedKeyUsage',
      desc: '',
      args: [],
    );
  }

  /// `Leave all options unchecked to omit this usage restriction.`
  String get pivUsageOmitted {
    return Intl.message(
      'Leave all options unchecked to omit this usage restriction.',
      name: 'pivUsageOmitted',
      desc: '',
      args: [],
    );
  }

  /// `Primary slots`
  String get pivMainSlots {
    return Intl.message(
      'Primary slots',
      name: 'pivMainSlots',
      desc: '',
      args: [],
    );
  }

  /// `Retired key slots`
  String get pivRetiredSlots {
    return Intl.message(
      'Retired key slots',
      name: 'pivRetiredSlots',
      desc: '',
      args: [],
    );
  }

  /// `Key only`
  String get pivSlotKeyOnly {
    return Intl.message('Key only', name: 'pivSlotKeyOnly', desc: '', args: []);
  }

  /// `Certificate only`
  String get pivSlotCertificateOnly {
    return Intl.message(
      'Certificate only',
      name: 'pivSlotCertificateOnly',
      desc: '',
      args: [],
    );
  }

  /// `Key + certificate`
  String get pivSlotKeyAndCertificate {
    return Intl.message(
      'Key + certificate',
      name: 'pivSlotKeyAndCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Certificate information and extensions`
  String get pivCertificateSubjectAndExtensions {
    return Intl.message(
      'Certificate information and extensions',
      name: 'pivCertificateSubjectAndExtensions',
      desc: '',
      args: [],
    );
  }

  /// `{count} occupied`
  String pivOccupiedSlots(int count) {
    return Intl.message(
      '$count occupied',
      name: 'pivOccupiedSlots',
      desc: '',
      args: [count],
    );
  }

  /// `Set up 9D to unlock your Mac’s login keychain. Set up the login certificate in 9A as well.`
  String get pivMacOsKeychainDescription {
    return Intl.message(
      'Set up 9D to unlock your Mac’s login keychain. Set up the login certificate in 9A as well.',
      name: 'pivMacOsKeychainDescription',
      desc: '',
      args: [],
    );
  }

  /// `Recommended settings applied to {slot}`
  String pivMacOsSlotApplied(String slot) {
    return Intl.message(
      'Recommended settings applied to $slot',
      name: 'pivMacOsSlotApplied',
      desc: '',
      args: [slot],
    );
  }

  /// `Sign in to your Mac with CanoKey`
  String get pivMacOsGuideTitle {
    return Intl.message(
      'Sign in to your Mac with CanoKey',
      name: 'pivMacOsGuideTitle',
      desc: '',
      args: [],
    );
  }

  /// `Set up 9A to verify your identity and 9D to unlock your login keychain. Once both are configured, reconnect CanoKey and pair it with your Mac account.`
  String get pivMacOsGuide {
    return Intl.message(
      'Set up 9A to verify your identity and 9D to unlock your login keychain. Once both are configured, reconnect CanoKey and pair it with your Mac account.',
      name: 'pivMacOsGuide',
      desc: '',
      args: [],
    );
  }

  /// `9A · Sign in`
  String get pivMacOsAuthenticationSlot {
    return Intl.message(
      '9A · Sign in',
      name: 'pivMacOsAuthenticationSlot',
      desc: '',
      args: [],
    );
  }

  /// `9D · Unlock keychain`
  String get pivMacOsKeychainSlot {
    return Intl.message(
      '9D · Unlock keychain',
      name: 'pivMacOsKeychainSlot',
      desc: '',
      args: [],
    );
  }

  /// `9A is configured. Next, check 9D: your Mac also needs its key and certificate to unlock your login keychain.`
  String get pivMacOsAfterAuthentication {
    return Intl.message(
      '9A is configured. Next, check 9D: your Mac also needs its key and certificate to unlock your login keychain.',
      name: 'pivMacOsAfterAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `9D is configured. Check that 9A is also configured, then reconnect CanoKey and pair it with your Mac account.`
  String get pivMacOsAfterKeychain {
    return Intl.message(
      '9D is configured. Check that 9A is also configured, then reconnect CanoKey and pair it with your Mac account.',
      name: 'pivMacOsAfterKeychain',
      desc: '',
      args: [],
    );
  }

  /// `Check {slot}`
  String pivMacOsCheckSlot(String slot) {
    return Intl.message(
      'Check $slot',
      name: 'pivMacOsCheckSlot',
      desc: '',
      args: [slot],
    );
  }

  /// `Set up macOS login`
  String get pivMacSetupTitle {
    return Intl.message(
      'Set up macOS login',
      name: 'pivMacSetupTitle',
      desc: '',
      args: [],
    );
  }

  /// `Set up the keys and certificates needed for macOS login. Slots 9A and 9D will be checked, and compatible keys and certificates will be kept.`
  String get pivMacSetupIntro {
    return Intl.message(
      'Set up the keys and certificates needed for macOS login. Slots 9A and 9D will be checked, and compatible keys and certificates will be kept.',
      name: 'pivMacSetupIntro',
      desc: '',
      args: [],
    );
  }

  /// `Check again`
  String get pivMacSetupInspect {
    return Intl.message(
      'Check again',
      name: 'pivMacSetupInspect',
      desc: '',
      args: [],
    );
  }

  /// `Could not check or configure CanoKey. Check the connection, PIV PIN and management key, then try again. Completed changes are kept. This feature requires firmware that can report key information.`
  String get pivMacSetupError {
    return Intl.message(
      'Could not check or configure CanoKey. Check the connection, PIV PIN and management key, then try again. Completed changes are kept. This feature requires firmware that can report key information.',
      name: 'pivMacSetupError',
      desc: '',
      args: [],
    );
  }

  /// `Keep existing configuration`
  String get pivMacSetupKeep {
    return Intl.message(
      'Keep existing configuration',
      name: 'pivMacSetupKeep',
      desc: '',
      args: [],
    );
  }

  /// `Create key and certificate`
  String get pivMacSetupCreate {
    return Intl.message(
      'Create key and certificate',
      name: 'pivMacSetupCreate',
      desc: '',
      args: [],
    );
  }

  /// `Keep key; add certificate`
  String get pivMacSetupIssue {
    return Intl.message(
      'Keep key; add certificate',
      name: 'pivMacSetupIssue',
      desc: '',
      args: [],
    );
  }

  /// `Keep key; replace certificate`
  String get pivMacSetupReplaceCert {
    return Intl.message(
      'Keep key; replace certificate',
      name: 'pivMacSetupReplaceCert',
      desc: '',
      args: [],
    );
  }

  /// `Replace key and certificate`
  String get pivMacSetupReplaceKey {
    return Intl.message(
      'Replace key and certificate',
      name: 'pivMacSetupReplaceKey',
      desc: '',
      args: [],
    );
  }

  /// `I confirm the key or certificate replacements listed above. Replaced keys cannot be recovered.`
  String get pivMacSetupConsent {
    return Intl.message(
      'I confirm the key or certificate replacements listed above. Replaced keys cannot be recovered.',
      name: 'pivMacSetupConsent',
      desc: '',
      args: [],
    );
  }

  /// `Configure CanoKey`
  String get pivMacSetupStart {
    return Intl.message(
      'Configure CanoKey',
      name: 'pivMacSetupStart',
      desc: '',
      args: [],
    );
  }

  /// `CanoKey setup is complete. Reconnect it and follow the macOS prompt to pair it with your login account.`
  String get pivMacSetupDone {
    return Intl.message(
      'CanoKey setup is complete. Reconnect it and follow the macOS prompt to pair it with your login account.',
      name: 'pivMacSetupDone',
      desc: '',
      args: [],
    );
  }

  /// `Configuring`
  String get pivMacSetupWorking {
    return Intl.message(
      'Configuring',
      name: 'pivMacSetupWorking',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get pivMacSetupFinished {
    return Intl.message(
      'Done',
      name: 'pivMacSetupFinished',
      desc: '',
      args: [],
    );
  }

  /// `Enter your PIV PIN and management key.`
  String get pivMacSetupCredentials {
    return Intl.message(
      'Enter your PIV PIN and management key.',
      name: 'pivMacSetupCredentials',
      desc: '',
      args: [],
    );
  }

  /// `Management key (hex)`
  String get pivMacSetupManagementKey {
    return Intl.message(
      'Management key (hex)',
      name: 'pivMacSetupManagementKey',
      desc: '',
      args: [],
    );
  }

  /// `Check the PIN and management key format.`
  String get pivMacSetupInvalid {
    return Intl.message(
      'Check the PIN and management key format.',
      name: 'pivMacSetupInvalid',
      desc: '',
      args: [],
    );
  }

  /// `PIV`
  String get pivPageTitle {
    return Intl.message('PIV', name: 'pivPageTitle', desc: '', args: []);
  }

  /// `Manage PIV keys, certificates and PINs on CanoKey.`
  String get pivPageDescription {
    return Intl.message(
      'Manage PIV keys, certificates and PINs on CanoKey.',
      name: 'pivPageDescription',
      desc: '',
      args: [],
    );
  }

  /// `For user authentication`
  String get pivPinDescription {
    return Intl.message(
      'For user authentication',
      name: 'pivPinDescription',
      desc: '',
      args: [],
    );
  }

  /// `For unblocking the PIN`
  String get pivPukDescription {
    return Intl.message(
      'For unblocking the PIN',
      name: 'pivPukDescription',
      desc: '',
      args: [],
    );
  }

  /// `Attempts remaining`
  String get pivRetriesRemaining {
    return Intl.message(
      'Attempts remaining',
      name: 'pivRetriesRemaining',
      desc: '',
      args: [],
    );
  }

  /// `Ready`
  String get pivStatusReady {
    return Intl.message('Ready', name: 'pivStatusReady', desc: '', args: []);
  }

  /// `Blocked`
  String get pivStatusBlocked {
    return Intl.message(
      'Blocked',
      name: 'pivStatusBlocked',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get pivStatusUnknown {
    return Intl.message(
      'Unknown',
      name: 'pivStatusUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Configured`
  String get pivStatusConfigured {
    return Intl.message(
      'Configured',
      name: 'pivStatusConfigured',
      desc: '',
      args: [],
    );
  }

  /// `Not configured`
  String get pivStatusEmpty {
    return Intl.message(
      'Not configured',
      name: 'pivStatusEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Certificate slots`
  String get pivSlotsTitle {
    return Intl.message(
      'Certificate slots',
      name: 'pivSlotsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Each slot holds a key and certificate.`
  String get pivSlotsDescription {
    return Intl.message(
      'Each slot holds a key and certificate.',
      name: 'pivSlotsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Select a slot to view or manage its certificate`
  String get pivSlotsHint {
    return Intl.message(
      'Select a slot to view or manage its certificate',
      name: 'pivSlotsHint',
      desc: '',
      args: [],
    );
  }

  /// `Slot`
  String get pivSlotColumn {
    return Intl.message('Slot', name: 'pivSlotColumn', desc: '', args: []);
  }

  /// `Name`
  String get pivNameColumn {
    return Intl.message('Name', name: 'pivNameColumn', desc: '', args: []);
  }

  /// `Algorithm`
  String get pivAlgorithmColumn {
    return Intl.message(
      'Algorithm',
      name: 'pivAlgorithmColumn',
      desc: '',
      args: [],
    );
  }

  /// `View certificate`
  String get pivViewCertificate {
    return Intl.message(
      'View certificate',
      name: 'pivViewCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Import / export`
  String get pivTransfer {
    return Intl.message(
      'Import / export',
      name: 'pivTransfer',
      desc: '',
      args: [],
    );
  }

  /// `Manage`
  String get pivManage {
    return Intl.message('Manage', name: 'pivManage', desc: '', args: []);
  }

  /// `macOS login`
  String get pivMacLogin {
    return Intl.message('macOS login', name: 'pivMacLogin', desc: '', args: []);
  }

  /// `Sign in to macOS using your PIV certificates.`
  String get pivMacLoginDescription {
    return Intl.message(
      'Sign in to macOS using your PIV certificates.',
      name: 'pivMacLoginDescription',
      desc: '',
      args: [],
    );
  }

  /// `Certificate information`
  String get pivCertificateInfo {
    return Intl.message(
      'Certificate information',
      name: 'pivCertificateInfo',
      desc: '',
      args: [],
    );
  }

  /// `Certificate details for this slot.`
  String get pivCertificateInfoDescription {
    return Intl.message(
      'Certificate details for this slot.',
      name: 'pivCertificateInfoDescription',
      desc: '',
      args: [],
    );
  }

  /// `Certificate status`
  String get pivCertificateStatus {
    return Intl.message(
      'Certificate status',
      name: 'pivCertificateStatus',
      desc: '',
      args: [],
    );
  }

  /// `Certificate present`
  String get pivCertificatePresent {
    return Intl.message(
      'Certificate present',
      name: 'pivCertificatePresent',
      desc: '',
      args: [],
    );
  }

  /// `Choose an operation for this slot.`
  String get pivActionsDescription {
    return Intl.message(
      'Choose an operation for this slot.',
      name: 'pivActionsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Generate or import keys and certificates for this slot.`
  String get pivProvisioningDescription {
    return Intl.message(
      'Generate or import keys and certificates for this slot.',
      name: 'pivProvisioningDescription',
      desc: '',
      args: [],
    );
  }

  /// `Save a certificate or public key to a file.`
  String get pivExportDescription {
    return Intl.message(
      'Save a certificate or public key to a file.',
      name: 'pivExportDescription',
      desc: '',
      args: [],
    );
  }

  /// `Sign messages or files, or verify a file signature.`
  String get pivKeyOperationsDescription {
    return Intl.message(
      'Sign messages or files, or verify a file signature.',
      name: 'pivKeyOperationsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Before moving or deleting a key, make sure you have another way to sign in or decrypt your data.`
  String get pivDangerDescription {
    return Intl.message(
      'Before moving or deleting a key, make sure you have another way to sign in or decrypt your data.',
      name: 'pivDangerDescription',
      desc: '',
      args: [],
    );
  }

  /// `Configure constraints, key usage and extended key usage.`
  String get pivExtensionsDescription {
    return Intl.message(
      'Configure constraints, key usage and extended key usage.',
      name: 'pivExtensionsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enter the certificate holder's name, organization and other details.`
  String get pivSubjectDescription {
    return Intl.message(
      'Enter the certificate holder\'s name, organization and other details.',
      name: 'pivSubjectDescription',
      desc: '',
      args: [],
    );
  }

  /// `View CanoKey information and change device and app settings.`
  String get settingsDescription {
    return Intl.message(
      'View CanoKey information and change device and app settings.',
      name: 'settingsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Device Settings`
  String get settingsDeviceSettings {
    return Intl.message(
      'Device Settings',
      name: 'settingsDeviceSettings',
      desc: '',
      args: [],
    );
  }

  /// `Device Actions`
  String get settingsDeviceActions {
    return Intl.message(
      'Device Actions',
      name: 'settingsDeviceActions',
      desc: '',
      args: [],
    );
  }

  /// `WebAuthn Credentials`
  String get webAuthnCredentials {
    return Intl.message(
      'WebAuthn Credentials',
      name: 'webAuthnCredentials',
      desc: '',
      args: [],
    );
  }

  /// `Manage WebAuthn sign-in credentials stored on your CanoKey.`
  String get webAuthnDescription {
    return Intl.message(
      'Manage WebAuthn sign-in credentials stored on your CanoKey.',
      name: 'webAuthnDescription',
      desc: '',
      args: [],
    );
  }

  /// `Search WebAuthn credentials…`
  String get webAuthnSearch {
    return Intl.message(
      'Search WebAuthn credentials…',
      name: 'webAuthnSearch',
      desc: '',
      args: [],
    );
  }

  /// `Why can't I see my credentials?`
  String get webAuthnMissingCredentials {
    return Intl.message(
      'Why can\'t I see my credentials?',
      name: 'webAuthnMissingCredentials',
      desc: '',
      args: [],
    );
  }

  /// `This list shows credentials CanoKey can find on its own. Some credentials can only be identified when a website starts sign-in, so they do not appear here. You can still use them to sign in.`
  String get webAuthnMissingCredentialsExplanation {
    return Intl.message(
      'This list shows credentials CanoKey can find on its own. Some credentials can only be identified when a website starts sign-in, so they do not appear here. You can still use them to sign in.',
      name: 'webAuthnMissingCredentialsExplanation',
      desc: '',
      args: [],
    );
  }

  /// `Manage one-time codes for your accounts (TOTP / HOTP).`
  String get oathDescription {
    return Intl.message(
      'Manage one-time codes for your accounts (TOTP / HOTP).',
      name: 'oathDescription',
      desc: '',
      args: [],
    );
  }

  /// `Search account name or email`
  String get oathSearch {
    return Intl.message(
      'Search account name or email',
      name: 'oathSearch',
      desc: '',
      args: [],
    );
  }

  /// `Choose the password output for a short or long press on CanoKey.`
  String get passDescription {
    return Intl.message(
      'Choose the password output for a short or long press on CanoKey.',
      name: 'passDescription',
      desc: '',
      args: [],
    );
  }

  /// `View OpenPGP card information and manage PINs and touch confirmation.`
  String get openpgpDescription {
    return Intl.message(
      'View OpenPGP card information and manage PINs and touch confirmation.',
      name: 'openpgpDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enter a whole number.`
  String get validationNumber {
    return Intl.message(
      'Enter a whole number.',
      name: 'validationNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter a whole number of at least {min}.`
  String validationNumberMin(Object min) {
    return Intl.message(
      'Enter a whole number of at least $min.',
      name: 'validationNumberMin',
      desc: '',
      args: [min],
    );
  }

  /// `Enter a whole number of at most {max}.`
  String validationNumberMax(Object max) {
    return Intl.message(
      'Enter a whole number of at most $max.',
      name: 'validationNumberMax',
      desc: '',
      args: [max],
    );
  }

  /// `The operation failed. Read CanoKey again and try again.`
  String get operationFailed {
    return Intl.message(
      'The operation failed. Read CanoKey again and try again.',
      name: 'operationFailed',
      desc: '',
      args: [],
    );
  }

  /// `PIN verification failed. Read CanoKey again and try again.`
  String get pinVerificationFailed {
    return Intl.message(
      'PIN verification failed. Read CanoKey again and try again.',
      name: 'pinVerificationFailed',
      desc: '',
      args: [],
    );
  }

  /// `Refresh the page and enter your WebAuthn PIN before trying this operation again.`
  String get webauthnPinRequired {
    return Intl.message(
      'Refresh the page and enter your WebAuthn PIN before trying this operation again.',
      name: 'webauthnPinRequired',
      desc: '',
      args: [],
    );
  }

  /// `Could not set the WebAuthn PIN. Read CanoKey again and try again.`
  String get webauthnSetPinFailed {
    return Intl.message(
      'Could not set the WebAuthn PIN. Read CanoKey again and try again.',
      name: 'webauthnSetPinFailed',
      desc: '',
      args: [],
    );
  }

  /// `Could not change the WebAuthn PIN. Read CanoKey again and try again.`
  String get webauthnChangePinFailed {
    return Intl.message(
      'Could not change the WebAuthn PIN. Read CanoKey again and try again.',
      name: 'webauthnChangePinFailed',
      desc: '',
      args: [],
    );
  }

  /// `Reset failed. Check the device connection and try again.`
  String get settingsResetFailed {
    return Intl.message(
      'Reset failed. Check the device connection and try again.',
      name: 'settingsResetFailed',
      desc: '',
      args: [],
    );
  }

  /// `Curve ID`
  String get sm2CurveId {
    return Intl.message('Curve ID', name: 'sm2CurveId', desc: '', args: []);
  }

  /// `Algorithm ID`
  String get sm2AlgorithmId {
    return Intl.message(
      'Algorithm ID',
      name: 'sm2AlgorithmId',
      desc: '',
      args: [],
    );
  }

  /// `Confirm new PIN`
  String get confirmNewPin {
    return Intl.message(
      'Confirm new PIN',
      name: 'confirmNewPin',
      desc: '',
      args: [],
    );
  }

  /// `Type name format (TNF)`
  String get ndefTypeNameFormat {
    return Intl.message(
      'Type name format (TNF)',
      name: 'ndefTypeNameFormat',
      desc: '',
      args: [],
    );
  }

  /// `This ID is reserved for another algorithm or curve. Choose a different value.`
  String get sm2ReservedId {
    return Intl.message(
      'This ID is reserved for another algorithm or curve. Choose a different value.',
      name: 'sm2ReservedId',
      desc: '',
      args: [],
    );
  }

  /// `Open network`
  String get ndefWifiOpen {
    return Intl.message(
      'Open network',
      name: 'ndefWifiOpen',
      desc: '',
      args: [],
    );
  }

  /// `Shared key`
  String get ndefWifiShared {
    return Intl.message(
      'Shared key',
      name: 'ndefWifiShared',
      desc: '',
      args: [],
    );
  }

  /// `{protocol} Personal`
  String ndefWifiPersonal(Object protocol) {
    return Intl.message(
      '$protocol Personal',
      name: 'ndefWifiPersonal',
      desc: '',
      args: [protocol],
    );
  }

  /// `{protocol} Enterprise`
  String ndefWifiEnterprise(Object protocol) {
    return Intl.message(
      '$protocol Enterprise',
      name: 'ndefWifiEnterprise',
      desc: '',
      args: [protocol],
    );
  }

  /// `No encryption`
  String get ndefWifiNoEncryption {
    return Intl.message(
      'No encryption',
      name: 'ndefWifiNoEncryption',
      desc: '',
      args: [],
    );
  }

  /// `Same type as the previous chunk`
  String get ndefTnfUnchanged {
    return Intl.message(
      'Same type as the previous chunk',
      name: 'ndefTnfUnchanged',
      desc: '',
      args: [],
    );
  }

  /// `Basic constraints`
  String get pivBasicConstraints {
    return Intl.message(
      'Basic constraints',
      name: 'pivBasicConstraints',
      desc: '',
      args: [],
    );
  }

  /// `Digital signature`
  String get pivUsageDigitalSignature {
    return Intl.message(
      'Digital signature',
      name: 'pivUsageDigitalSignature',
      desc: '',
      args: [],
    );
  }

  /// `Content commitment`
  String get pivUsageContentCommitment {
    return Intl.message(
      'Content commitment',
      name: 'pivUsageContentCommitment',
      desc: '',
      args: [],
    );
  }

  /// `Key encryption`
  String get pivUsageKeyEncipherment {
    return Intl.message(
      'Key encryption',
      name: 'pivUsageKeyEncipherment',
      desc: '',
      args: [],
    );
  }

  /// `Data encryption`
  String get pivUsageDataEncipherment {
    return Intl.message(
      'Data encryption',
      name: 'pivUsageDataEncipherment',
      desc: '',
      args: [],
    );
  }

  /// `Key agreement`
  String get pivUsageKeyAgreement {
    return Intl.message(
      'Key agreement',
      name: 'pivUsageKeyAgreement',
      desc: '',
      args: [],
    );
  }

  /// `Client authentication`
  String get pivUsageClientAuth {
    return Intl.message(
      'Client authentication',
      name: 'pivUsageClientAuth',
      desc: '',
      args: [],
    );
  }

  /// `Server authentication`
  String get pivUsageServerAuth {
    return Intl.message(
      'Server authentication',
      name: 'pivUsageServerAuth',
      desc: '',
      args: [],
    );
  }

  /// `Code signing`
  String get pivUsageCodeSigning {
    return Intl.message(
      'Code signing',
      name: 'pivUsageCodeSigning',
      desc: '',
      args: [],
    );
  }

  /// `Email protection`
  String get pivUsageEmailProtection {
    return Intl.message(
      'Email protection',
      name: 'pivUsageEmailProtection',
      desc: '',
      args: [],
    );
  }

  /// `Smart card login`
  String get pivUsageSmartCardLogon {
    return Intl.message(
      'Smart card login',
      name: 'pivUsageSmartCardLogon',
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
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
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
