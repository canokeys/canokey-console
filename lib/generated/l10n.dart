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

  /// `This applet has been locked.`
  String get appletLocked {
    return Intl.message(
      'This applet has been locked.',
      name: 'appletLocked',
      desc: '',
      args: [],
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
