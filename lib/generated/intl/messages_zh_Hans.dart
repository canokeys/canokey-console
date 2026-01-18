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

  static String m1(name) => "您正在删除 ${name}，删除该项目后无法恢复！请确认相关服务的二步验证已经关闭。";

  static String m2(name) => "您要将 ${name} 设为触摸时的输出吗？请注意，该操作将会覆盖原有的触摸输出。";

  static String m3(keyType) => "修改 ${keyType} 密钥的触摸设置";

  static String m4(retries) => "PIN 输入错误，剩余重试次数：${retries}";

  static String m6(slot) => "此操作将从您的 CanoKey 中删除 ${slot} 中的证书和密钥。请确保您有其他方式访问。";

  static String m7(applet) => "该操作将抹除 ${applet} 的全部数据！";

  static String m8(length) => "需要 ${length} 个字符";

  static String m9(name) => "您正在删除 ${name}，删除该项目后无法恢复！请确认您有其他方式登录该服务。";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "actions": MessageLookupByLibrary.simpleMessage("操作"),
    "add": MessageLookupByLibrary.simpleMessage("增加"),
    "androidAlertTitle": MessageLookupByLibrary.simpleMessage("读取 CanoKey"),
    "androidPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请用手机背面触碰您的 CanoKey 或将其插入 USB 接口",
    ),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "CanoKey Console 是 CanoKey 开源安全密钥的管理工具。",
    ),
    "appletLocked": MessageLookupByLibrary.simpleMessage("该应用已被锁定"),
    "applets": MessageLookupByLibrary.simpleMessage("应用"),
    "beforeSourceLink": MessageLookupByLibrary.simpleMessage(
      "可在 GitHub 获得源代码：",
    ),
    "browserNotSupported": MessageLookupByLibrary.simpleMessage("不支持该浏览器"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "change": MessageLookupByLibrary.simpleMessage("修改"),
    "changePin": MessageLookupByLibrary.simpleMessage("修改 PIN"),
    "changePinPrompt": m0,
    "close": MessageLookupByLibrary.simpleMessage("关闭"),
    "confirm": MessageLookupByLibrary.simpleMessage("确定"),
    "connectFirst": MessageLookupByLibrary.simpleMessage("请先连接 CanoKey"),
    "copied": MessageLookupByLibrary.simpleMessage("已复制"),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "deleted": MessageLookupByLibrary.simpleMessage("删除成功"),
    "desktopPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请将您的 CanoKey 插入 USB 接口",
    ),
    "desktopPollError": MessageLookupByLibrary.simpleMessage(
      "寻找 USB 连接的 CanoKey 时遇到错误。请修复错误后重启此应用：",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("启用"),
    "home": MessageLookupByLibrary.simpleMessage("首页"),
    "homeDirectlySelect": MessageLookupByLibrary.simpleMessage("请选择应用"),
    "homePress": MessageLookupByLibrary.simpleMessage("点击"),
    "homeScreenTitle": MessageLookupByLibrary.simpleMessage("CanoKey Console"),
    "homeSelect": MessageLookupByLibrary.simpleMessage("选择应用"),
    "interrupted": MessageLookupByLibrary.simpleMessage(
      "通讯中断。尝试紧贴 CanoKey 直到读取结束。",
    ),
    "iosAlertMessage": MessageLookupByLibrary.simpleMessage(
      "使用 iPhone 顶部读取 CanoKey",
    ),
    "iosPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请点击刷新按钮并点击您的 CanoKey 或将其插入 USB 接口",
    ),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "CanoKey 繁忙，请重新插拔并稍后再试",
    ),
    "newPin": MessageLookupByLibrary.simpleMessage("新 PIN"),
    "noCard": MessageLookupByLibrary.simpleMessage("未找到 CanoKey"),
    "noCredential": MessageLookupByLibrary.simpleMessage("没有找到凭据"),
    "noMatchingCredential": MessageLookupByLibrary.simpleMessage("没有找到匹配的凭据"),
    "notSupported": MessageLookupByLibrary.simpleMessage("不支持该操作"),
    "notSupportedInNFC": MessageLookupByLibrary.simpleMessage(
      "该操作不支持在 NFC 模式下执行",
    ),
    "oathAccount": MessageLookupByLibrary.simpleMessage("账户"),
    "oathAddAccount": MessageLookupByLibrary.simpleMessage("增加账户"),
    "oathAddByScanning": MessageLookupByLibrary.simpleMessage("扫码添加"),
    "oathAddByScreen": MessageLookupByLibrary.simpleMessage("扫描屏幕上的二维码"),
    "oathAddManually": MessageLookupByLibrary.simpleMessage("手动添加"),
    "oathAdded": MessageLookupByLibrary.simpleMessage("添加成功"),
    "oathAdvancedSettings": MessageLookupByLibrary.simpleMessage(
      "高级设置，仅供专业用户使用，不正确的设置可能导致凭据无法使用。",
    ),
    "oathAlgorithm": MessageLookupByLibrary.simpleMessage("算法"),
    "oathCode": MessageLookupByLibrary.simpleMessage("口令"),
    "oathCodeChanged": MessageLookupByLibrary.simpleMessage("口令已修改"),
    "oathCopy": MessageLookupByLibrary.simpleMessage("复制"),
    "oathCounter": MessageLookupByLibrary.simpleMessage("计数器初始值"),
    "oathCounterMustBeNumber": MessageLookupByLibrary.simpleMessage("请填写数字"),
    "oathDelete": m1,
    "oathDigits": MessageLookupByLibrary.simpleMessage("位数"),
    "oathDuplicated": MessageLookupByLibrary.simpleMessage("账户已存在"),
    "oathInputCode": MessageLookupByLibrary.simpleMessage("解锁 CanoKey"),
    "oathInputCodePrompt": MessageLookupByLibrary.simpleMessage(
      "该 CanoKey 受口令保护，请输入口令。",
    ),
    "oathInvalidKey": MessageLookupByLibrary.simpleMessage("密钥无效"),
    "oathIssuer": MessageLookupByLibrary.simpleMessage("服务商"),
    "oathNewCode": MessageLookupByLibrary.simpleMessage("新口令"),
    "oathNewCodePrompt": MessageLookupByLibrary.simpleMessage(
      "请输入新口令，如需删除，请留空。",
    ),
    "oathNoQr": MessageLookupByLibrary.simpleMessage("未检测到二维码"),
    "oathPeriod": MessageLookupByLibrary.simpleMessage("周期"),
    "oathRequireTouch": MessageLookupByLibrary.simpleMessage("需要触摸"),
    "oathRequired": MessageLookupByLibrary.simpleMessage("不得为空"),
    "oathSecret": MessageLookupByLibrary.simpleMessage("密钥"),
    "oathSetCode": MessageLookupByLibrary.simpleMessage("设置口令"),
    "oathSetDefault": MessageLookupByLibrary.simpleMessage("设为触摸输出"),
    "oathSetDefaultPrompt": m2,
    "oathSlot": MessageLookupByLibrary.simpleMessage("口令槽"),
    "oathTooLong": MessageLookupByLibrary.simpleMessage("长度超限"),
    "oathType": MessageLookupByLibrary.simpleMessage("类型"),
    "off": MessageLookupByLibrary.simpleMessage("关"),
    "oldPin": MessageLookupByLibrary.simpleMessage("当前 PIN"),
    "on": MessageLookupByLibrary.simpleMessage("开"),
    "openpgpAuthentication": MessageLookupByLibrary.simpleMessage("认证"),
    "openpgpCardHolder": MessageLookupByLibrary.simpleMessage("持卡人"),
    "openpgpCardInfo": MessageLookupByLibrary.simpleMessage("卡片信息"),
    "openpgpChangeAdminPin": MessageLookupByLibrary.simpleMessage(
      "修改 Admin PIN",
    ),
    "openpgpChangeInteraction": m3,
    "openpgpChangeTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "修改触摸缓存时间",
    ),
    "openpgpEncryption": MessageLookupByLibrary.simpleMessage("加密"),
    "openpgpKeyNone": MessageLookupByLibrary.simpleMessage("[未导入]"),
    "openpgpKeys": MessageLookupByLibrary.simpleMessage("密钥信息"),
    "openpgpManufacturer": MessageLookupByLibrary.simpleMessage("制造商"),
    "openpgpPubkeyUrl": MessageLookupByLibrary.simpleMessage("公钥 URL"),
    "openpgpSN": MessageLookupByLibrary.simpleMessage("序列号"),
    "openpgpSignature": MessageLookupByLibrary.simpleMessage("签名"),
    "openpgpUIF": MessageLookupByLibrary.simpleMessage("触摸设置"),
    "openpgpUifCacheTime": MessageLookupByLibrary.simpleMessage("触摸缓存时间"),
    "openpgpUifCacheTimeChanged": MessageLookupByLibrary.simpleMessage(
      "触摸缓存时间修改成功",
    ),
    "openpgpUifChanged": MessageLookupByLibrary.simpleMessage("触摸设置修改成功"),
    "openpgpUifOff": MessageLookupByLibrary.simpleMessage("关闭"),
    "openpgpUifOn": MessageLookupByLibrary.simpleMessage("打开"),
    "openpgpUifPermanent": MessageLookupByLibrary.simpleMessage("永久启用（无法再关闭）"),
    "openpgpVersion": MessageLookupByLibrary.simpleMessage("版本"),
    "other": MessageLookupByLibrary.simpleMessage("其他"),
    "passInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "请输入您的管理员（设置应用） PIN（默认值为 123456）。",
    ),
    "passNotSupported": MessageLookupByLibrary.simpleMessage(
      "您的 CanoKey 不支持 Pass 功能。",
    ),
    "passSlotConfigPrompt": MessageLookupByLibrary.simpleMessage(
      "请配置该密码槽。如需配置HOTP，请前往HOTP应用配置。",
    ),
    "passSlotConfigTitle": MessageLookupByLibrary.simpleMessage("配置"),
    "passSlotHotp": MessageLookupByLibrary.simpleMessage("HOTP"),
    "passSlotLong": MessageLookupByLibrary.simpleMessage("长按"),
    "passSlotOff": MessageLookupByLibrary.simpleMessage("关闭"),
    "passSlotShort": MessageLookupByLibrary.simpleMessage("短按"),
    "passSlotStatic": MessageLookupByLibrary.simpleMessage("静态口令"),
    "passSlotWithEnter": MessageLookupByLibrary.simpleMessage("附加回车"),
    "passStatus": MessageLookupByLibrary.simpleMessage("状态"),
    "passkey": MessageLookupByLibrary.simpleMessage("通行密钥"),
    "pinChanged": MessageLookupByLibrary.simpleMessage("PIN 修改成功"),
    "pinIncorrect": MessageLookupByLibrary.simpleMessage("PIN 输入错误"),
    "pinInvalidLength": MessageLookupByLibrary.simpleMessage("长度错误"),
    "pinLength": MessageLookupByLibrary.simpleMessage("输入的 PIN 长度错误"),
    "pinRetries": m4,
    "pivAlgorithm": MessageLookupByLibrary.simpleMessage("当前密钥算法"),
    "pivAuthentication": MessageLookupByLibrary.simpleMessage(
      "认证（Authentication）",
    ),
    "pivCardAuthentication": MessageLookupByLibrary.simpleMessage(
      "卡认证（Card Authentication）",
    ),
    "pivCertificate": MessageLookupByLibrary.simpleMessage("证书"),
    "pivChangeManagementKey": MessageLookupByLibrary.simpleMessage("修改管理密钥"),
    "pivChangeManagementKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "新管理密钥的长度应当为 24 字节。请妥善保管管理密钥，否则您将无法管理 PIV 应用。",
    ),
    "pivChangePUK": MessageLookupByLibrary.simpleMessage("修改 PUK"),
    "pivDelete": MessageLookupByLibrary.simpleMessage("删除"),
    "pivDeleteSlot": m6,
    "pivEmpty": MessageLookupByLibrary.simpleMessage("空"),
    "pivExport": MessageLookupByLibrary.simpleMessage("导出"),
    "pivExportCertificate": MessageLookupByLibrary.simpleMessage("导出证书"),
    "pivGenerate": MessageLookupByLibrary.simpleMessage("生成"),
    "pivImport": MessageLookupByLibrary.simpleMessage("导入"),
    "pivKeyManagement": MessageLookupByLibrary.simpleMessage(
      "密钥管理（Key Management）",
    ),
    "pivManagementKey": MessageLookupByLibrary.simpleMessage("管理密钥"),
    "pivManagementKeyVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "管理密钥验证失败",
    ),
    "pivNewManagementKey": MessageLookupByLibrary.simpleMessage("新密钥"),
    "pivNewPUK": MessageLookupByLibrary.simpleMessage("新 PUK"),
    "pivOldManagementKey": MessageLookupByLibrary.simpleMessage("当前密钥"),
    "pivOldPUK": MessageLookupByLibrary.simpleMessage("当前 PUK"),
    "pivOrigin": MessageLookupByLibrary.simpleMessage("来源"),
    "pivOriginGenerated": MessageLookupByLibrary.simpleMessage("内部生成"),
    "pivOriginImported": MessageLookupByLibrary.simpleMessage("外部导入"),
    "pivPinManagement": MessageLookupByLibrary.simpleMessage("管理 PIN"),
    "pivPinPolicy": MessageLookupByLibrary.simpleMessage("PIN 策略"),
    "pivPinPolicyAlways": MessageLookupByLibrary.simpleMessage("总是验证"),
    "pivPinPolicyDefault": MessageLookupByLibrary.simpleMessage("默认"),
    "pivPinPolicyNever": MessageLookupByLibrary.simpleMessage("从不验证"),
    "pivPinPolicyOnce": MessageLookupByLibrary.simpleMessage("会话内验证一次"),
    "pivRandomManagementKey": MessageLookupByLibrary.simpleMessage("随机值"),
    "pivRetired1": MessageLookupByLibrary.simpleMessage("过期证书 1"),
    "pivRetired2": MessageLookupByLibrary.simpleMessage("过期证书 2"),
    "pivSignature": MessageLookupByLibrary.simpleMessage(
      "签名（Digital Signature）",
    ),
    "pivSlots": MessageLookupByLibrary.simpleMessage("证书槽"),
    "pivTouchPolicy": MessageLookupByLibrary.simpleMessage("触摸策略"),
    "pivTouchPolicyAlways": MessageLookupByLibrary.simpleMessage("总是验证"),
    "pivTouchPolicyCached": MessageLookupByLibrary.simpleMessage("缓存 15 秒"),
    "pivTouchPolicyDefault": MessageLookupByLibrary.simpleMessage("默认"),
    "pivTouchPolicyNever": MessageLookupByLibrary.simpleMessage("从不验证"),
    "pivUseDefaultManagementKey": MessageLookupByLibrary.simpleMessage("默认值"),
    "pivVerifyManagementKey": MessageLookupByLibrary.simpleMessage("验证管理密钥"),
    "pollCanceled": MessageLookupByLibrary.simpleMessage("您没有选择任何 CanoKey"),
    "pollCanoKey": MessageLookupByLibrary.simpleMessage("请点击右上角刷新按钮读取 CanoKey"),
    "readingAlertMessage": MessageLookupByLibrary.simpleMessage(
      "请紧贴 CanoKey 直到读取结束",
    ),
    "reset": MessageLookupByLibrary.simpleMessage("重置"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "savePinOnDevice": MessageLookupByLibrary.simpleMessage("在此设备上保存 PIN"),
    "search": MessageLookupByLibrary.simpleMessage("搜索"),
    "seconds": MessageLookupByLibrary.simpleMessage("秒"),
    "settings": MessageLookupByLibrary.simpleMessage("设置"),
    "settingsChangeLanguage": MessageLookupByLibrary.simpleMessage("修改语言"),
    "settingsChipId": MessageLookupByLibrary.simpleMessage("芯片 ID"),
    "settingsClearPinCache": MessageLookupByLibrary.simpleMessage("清除已保存的 PIN"),
    "settingsClearPinCachePrompt": MessageLookupByLibrary.simpleMessage(
      "确定要清除此设备上所有已保存的 PIN 吗？",
    ),
    "settingsFirmwareVersion": MessageLookupByLibrary.simpleMessage("固件版本"),
    "settingsFixNFC": MessageLookupByLibrary.simpleMessage("修复 NFC"),
    "settingsFixNFCSuccess": MessageLookupByLibrary.simpleMessage("修复 NFC 成功"),
    "settingsHotp": MessageLookupByLibrary.simpleMessage("触摸时输出 HOTP"),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("CanoKey 信息"),
    "settingsInputPin": MessageLookupByLibrary.simpleMessage("PIN 验证"),
    "settingsInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "请输入您的管理应用 PIN（默认值为 123456）。请注意，该 PIN 与其他应用的 PIN 无关。",
    ),
    "settingsKeyboardWithReturn": MessageLookupByLibrary.simpleMessage(
      "OTP 输出后附加回车",
    ),
    "settingsLanguage": MessageLookupByLibrary.simpleMessage("语言"),
    "settingsModel": MessageLookupByLibrary.simpleMessage("型号"),
    "settingsNDEF": MessageLookupByLibrary.simpleMessage("NFC 标签模式 (NDEF)"),
    "settingsNDEFReadonly": MessageLookupByLibrary.simpleMessage("NFC 标签只读"),
    "settingsOtherSettings": MessageLookupByLibrary.simpleMessage("其他设置"),
    "settingsResetAll": MessageLookupByLibrary.simpleMessage("重置 CanoKey"),
    "settingsResetAllPrompt": MessageLookupByLibrary.simpleMessage(
      "即将抹除全部数据。当您确认后，CanoKey 将会多次闪烁，请在每次看到闪烁时触摸，直到提示成功。",
    ),
    "settingsResetApplet": m7,
    "settingsResetConditionNotSatisfying": MessageLookupByLibrary.simpleMessage(
      "PIN 尚未锁定",
    ),
    "settingsResetNDEF": MessageLookupByLibrary.simpleMessage("重置 NDEF"),
    "settingsResetOATH": MessageLookupByLibrary.simpleMessage("重置 TOTP/HOTP"),
    "settingsResetOpenPGP": MessageLookupByLibrary.simpleMessage("重置 OpenPGP"),
    "settingsResetPIV": MessageLookupByLibrary.simpleMessage("重置 PIV"),
    "settingsResetPass": MessageLookupByLibrary.simpleMessage("重置 Pass"),
    "settingsResetPresenceTestFailed": MessageLookupByLibrary.simpleMessage(
      "请按提示触摸",
    ),
    "settingsResetSuccess": MessageLookupByLibrary.simpleMessage("重置成功"),
    "settingsResetWebAuthn": MessageLookupByLibrary.simpleMessage(
      "重置 WebAuthn",
    ),
    "settingsSN": MessageLookupByLibrary.simpleMessage("序号"),
    "settingsStartPage": MessageLookupByLibrary.simpleMessage("起始页"),
    "settingsWebAuthnSm2Support": MessageLookupByLibrary.simpleMessage(
      "WebAuthn SM2",
    ),
    "settingsWebUSB": MessageLookupByLibrary.simpleMessage("插入时 WebUSB 提示"),
    "soundCredit": MessageLookupByLibrary.simpleMessage(
      "NFC 交互音效由 Summer Xu 制作。",
    ),
    "successfullyChanged": MessageLookupByLibrary.simpleMessage("修改成功"),
    "validationExactLength": m8,
    "validationHexString": MessageLookupByLibrary.simpleMessage("请输入十六进制字符串"),
    "viewUserId": MessageLookupByLibrary.simpleMessage("查看用户 ID"),
    "warning": MessageLookupByLibrary.simpleMessage("警告"),
    "webPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请将您的 CanoKey 插入 USB 接口并点击刷新按钮",
    ),
    "webauthnClientPinNotSupported": MessageLookupByLibrary.simpleMessage(
      "该密钥不支持 WebAuthn PIN。",
    ),
    "webauthnDelete": m9,
    "webauthnInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "请输入您的 WebAuthn PIN。",
    ),
    "webauthnInputPinTitle": MessageLookupByLibrary.simpleMessage(
      "解锁 WebAuthn",
    ),
    "webauthnPinAuthBlocked": MessageLookupByLibrary.simpleMessage(
      "PIN 被锁定，请重新插拔 CanoKey。",
    ),
    "webauthnPinBlocked": MessageLookupByLibrary.simpleMessage(
      "PIN 被锁定，请重置 WebAuthn。",
    ),
    "webauthnSetPinPrompt": MessageLookupByLibrary.simpleMessage(
      "请设置 PIN 以启用凭据管理。PIN 的长度应当为 4 - 63 个字符。",
    ),
    "webauthnSetPinTitle": MessageLookupByLibrary.simpleMessage(
      "设置 WebAuthn PIN",
    ),
  };
}
