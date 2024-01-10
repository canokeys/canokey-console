// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_Hans locale. All the
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
  String get localeName => 'zh_Hans';

  static String m0(min, max) => "新 PIN 的长度应当为 ${min} - ${max} 个字符。";

  static String m1(name) => "您正在删除${name}，删除该项目后无法恢复！请确认相关服务的二步验证已经关闭。";

  static String m2(keyType) => "修改${keyType}密钥的触摸设置";

  static String m3(retries) => "PIN 输入错误，剩余重试次数：${retries}";

  static String m4(applet) => "该操作将抹除 ${applet} 的全部数据！";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("关于"),
        "actions": MessageLookupByLibrary.simpleMessage("操作"),
        "add": MessageLookupByLibrary.simpleMessage("增加"),
        "appletLocked": MessageLookupByLibrary.simpleMessage("该应用已被锁定"),
        "applets": MessageLookupByLibrary.simpleMessage("应用"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "change": MessageLookupByLibrary.simpleMessage("修改"),
        "changePin": MessageLookupByLibrary.simpleMessage("修改 PIN"),
        "changePinPrompt": m0,
        "close": MessageLookupByLibrary.simpleMessage("关闭"),
        "confirm": MessageLookupByLibrary.simpleMessage("确定"),
        "connectFirst": MessageLookupByLibrary.simpleMessage("请先连接 CanoKey"),
        "copied": MessageLookupByLibrary.simpleMessage("已复制"),
        "delete": MessageLookupByLibrary.simpleMessage("删除"),
        "home": MessageLookupByLibrary.simpleMessage("首页"),
        "homePress": MessageLookupByLibrary.simpleMessage("点击"),
        "homeScreenTitle":
            MessageLookupByLibrary.simpleMessage("CanoKey Console"),
        "homeSelect": MessageLookupByLibrary.simpleMessage("选择应用"),
        "networkError":
            MessageLookupByLibrary.simpleMessage("CanoKey 繁忙，请重新插拔并稍后再试"),
        "newPin": MessageLookupByLibrary.simpleMessage("新 PIN"),
        "oathAccount": MessageLookupByLibrary.simpleMessage("账户"),
        "oathAddAccount": MessageLookupByLibrary.simpleMessage("增加账户"),
        "oathAdded": MessageLookupByLibrary.simpleMessage("添加成功"),
        "oathAlgorithm": MessageLookupByLibrary.simpleMessage("算法"),
        "oathCode": MessageLookupByLibrary.simpleMessage("口令"),
        "oathCodeChanged": MessageLookupByLibrary.simpleMessage("口令已修改"),
        "oathCopy": MessageLookupByLibrary.simpleMessage("复制"),
        "oathCounter": MessageLookupByLibrary.simpleMessage("计数器初始值"),
        "oathCounterMustBeNumber":
            MessageLookupByLibrary.simpleMessage("请填写数字"),
        "oathDelete": m1,
        "oathDeleted": MessageLookupByLibrary.simpleMessage("删除成功"),
        "oathDigits": MessageLookupByLibrary.simpleMessage("位数"),
        "oathInputCode": MessageLookupByLibrary.simpleMessage("解锁 CanoKey"),
        "oathInputCodePrompt":
            MessageLookupByLibrary.simpleMessage("该 CanoKey 受口令保护，请输入口令。"),
        "oathInvalidKey": MessageLookupByLibrary.simpleMessage("密钥无效"),
        "oathIssuer": MessageLookupByLibrary.simpleMessage("服务商"),
        "oathNewCode": MessageLookupByLibrary.simpleMessage("新口令"),
        "oathNewCodePrompt":
            MessageLookupByLibrary.simpleMessage("请输入新口令，如需删除，请留空。"),
        "oathNoCredential": MessageLookupByLibrary.simpleMessage("没有找到凭据"),
        "oathPeriod": MessageLookupByLibrary.simpleMessage("周期"),
        "oathRequireTouch": MessageLookupByLibrary.simpleMessage("需要触摸"),
        "oathRequired": MessageLookupByLibrary.simpleMessage("不得为空"),
        "oathSecret": MessageLookupByLibrary.simpleMessage("密钥"),
        "oathSetCode": MessageLookupByLibrary.simpleMessage("设置口令"),
        "oathSetDefault": MessageLookupByLibrary.simpleMessage("设为默认"),
        "oathTooLong": MessageLookupByLibrary.simpleMessage("长度超限"),
        "oathType": MessageLookupByLibrary.simpleMessage("类型"),
        "off": MessageLookupByLibrary.simpleMessage("关"),
        "oldPin": MessageLookupByLibrary.simpleMessage("旧 PIN"),
        "on": MessageLookupByLibrary.simpleMessage("开"),
        "openpgpAuthentication": MessageLookupByLibrary.simpleMessage("认证"),
        "openpgpCardHolder": MessageLookupByLibrary.simpleMessage("持卡人"),
        "openpgpCardInfo": MessageLookupByLibrary.simpleMessage("卡片信息"),
        "openpgpChangeAdminPin":
            MessageLookupByLibrary.simpleMessage("修改 Admin PIN"),
        "openpgpChangeInteraction": m2,
        "openpgpChangeTouchCacheTime":
            MessageLookupByLibrary.simpleMessage("修改触摸缓存时间"),
        "openpgpEncryption": MessageLookupByLibrary.simpleMessage("加密"),
        "openpgpKeyNone": MessageLookupByLibrary.simpleMessage("[未导入]"),
        "openpgpKeys": MessageLookupByLibrary.simpleMessage("密钥信息"),
        "openpgpManufacturer": MessageLookupByLibrary.simpleMessage("制造商"),
        "openpgpPubkeyUrl": MessageLookupByLibrary.simpleMessage("公钥 URL"),
        "openpgpSN": MessageLookupByLibrary.simpleMessage("序列号"),
        "openpgpSignature": MessageLookupByLibrary.simpleMessage("签名"),
        "openpgpUIF": MessageLookupByLibrary.simpleMessage("触摸设置"),
        "openpgpUifCacheTime": MessageLookupByLibrary.simpleMessage("触摸缓存时间"),
        "openpgpUifCacheTimeChanged":
            MessageLookupByLibrary.simpleMessage("触摸缓存时间修改成功"),
        "openpgpUifChanged": MessageLookupByLibrary.simpleMessage("触摸设置修改成功"),
        "openpgpUifOff": MessageLookupByLibrary.simpleMessage("关闭"),
        "openpgpUifOn": MessageLookupByLibrary.simpleMessage("打开"),
        "openpgpUifPermanent":
            MessageLookupByLibrary.simpleMessage("永久启用（无法再关闭）"),
        "openpgpVersion": MessageLookupByLibrary.simpleMessage("版本"),
        "other": MessageLookupByLibrary.simpleMessage("其他"),
        "pinChanged": MessageLookupByLibrary.simpleMessage("PIN 修改成功"),
        "pinIncorrect": MessageLookupByLibrary.simpleMessage("PIN 输入错误"),
        "pinInvalidLength": MessageLookupByLibrary.simpleMessage("长度错误"),
        "pinLength": MessageLookupByLibrary.simpleMessage("输入的 PIN 长度错误"),
        "pinRetries": m3,
        "pivChangePUK": MessageLookupByLibrary.simpleMessage("修改 PUK"),
        "pollCanceled": MessageLookupByLibrary.simpleMessage("您没有选择任何 CanoKey"),
        "pollCanoKey":
            MessageLookupByLibrary.simpleMessage("请点击右上角刷新按钮读取 CanoKey"),
        "reset": MessageLookupByLibrary.simpleMessage("重置"),
        "save": MessageLookupByLibrary.simpleMessage("保存"),
        "seconds": MessageLookupByLibrary.simpleMessage("秒"),
        "settings": MessageLookupByLibrary.simpleMessage("设置"),
        "settingsChangeLanguage": MessageLookupByLibrary.simpleMessage("修改语言"),
        "settingsChipId": MessageLookupByLibrary.simpleMessage("芯片 ID"),
        "settingsFirmwareVersion": MessageLookupByLibrary.simpleMessage("固件版本"),
        "settingsFixNFC": MessageLookupByLibrary.simpleMessage("修复 NFC"),
        "settingsFixNFCSuccess":
            MessageLookupByLibrary.simpleMessage("修复 NFC 成功"),
        "settingsHotp": MessageLookupByLibrary.simpleMessage("触摸时输出 HOTP"),
        "settingsInfo": MessageLookupByLibrary.simpleMessage("CanoKey 信息"),
        "settingsInputPin": MessageLookupByLibrary.simpleMessage("PIN 验证"),
        "settingsInputPinPrompt": MessageLookupByLibrary.simpleMessage(
            "请输入您的 PIN（默认值为 123456）。请注意，该 PIN 与其他应用的 PIN 无关。"),
        "settingsKeyboardWithReturn":
            MessageLookupByLibrary.simpleMessage("OTP 输出后附加回车"),
        "settingsLanguage": MessageLookupByLibrary.simpleMessage("语言"),
        "settingsModel": MessageLookupByLibrary.simpleMessage("型号"),
        "settingsNDEF": MessageLookupByLibrary.simpleMessage("NFC 标签模式 (NDEF)"),
        "settingsNDEFReadonly":
            MessageLookupByLibrary.simpleMessage("NFC 标签只读"),
        "settingsOtherSettings": MessageLookupByLibrary.simpleMessage("其他设置"),
        "settingsResetAll": MessageLookupByLibrary.simpleMessage("重置 CanoKey"),
        "settingsResetAllPrompt": MessageLookupByLibrary.simpleMessage(
            "即将抹除全部数据。当您确认后，CanoKey 将会反复闪烁，请在闪烁时触摸，直到提示成功。"),
        "settingsResetApplet": m4,
        "settingsResetConditionNotSatisfying":
            MessageLookupByLibrary.simpleMessage("PIN 尚未锁定"),
        "settingsResetNDEF": MessageLookupByLibrary.simpleMessage("重置 NDEF"),
        "settingsResetOATH":
            MessageLookupByLibrary.simpleMessage("重置 TOTP/HOTP"),
        "settingsResetOpenPGP":
            MessageLookupByLibrary.simpleMessage("重置 OpenPGP"),
        "settingsResetPIV": MessageLookupByLibrary.simpleMessage("重置 PIV"),
        "settingsResetPass": MessageLookupByLibrary.simpleMessage("重置 Pass"),
        "settingsResetPresenceTestFailed":
            MessageLookupByLibrary.simpleMessage("请按提示触摸"),
        "settingsResetSuccess": MessageLookupByLibrary.simpleMessage("重置成功"),
        "settingsResetWebAuthn":
            MessageLookupByLibrary.simpleMessage("重置 WebAuthn"),
        "settingsSN": MessageLookupByLibrary.simpleMessage("序号"),
        "settingsWebUSB": MessageLookupByLibrary.simpleMessage("插入时 WebUSB 提示"),
        "successfullyChanged": MessageLookupByLibrary.simpleMessage("修改成功"),
        "warning": MessageLookupByLibrary.simpleMessage("警告")
      };
}
