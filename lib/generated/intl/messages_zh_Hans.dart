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

  static String m0(applet) => "${applet} 已关闭，请先在设置中启用。";

  static String m1(min, max) => "新 PIN 需要 ${min} 至 ${max} 个字符。";

  static String m2(error) => "保存失败：${error}";

  static String m3(used, total) => "已使用 ${used} / ${total} 字节";

  static String m4(error) => "无法保存这条记录，请检查填写的内容。详情：${error}";

  static String m5(protocol) => "${protocol} 企业版";

  static String m6(protocol) => "${protocol} 个人版";

  static String m7(name) =>
      "删除 ${name} 后，CanoKey 将无法再为此账户生成验证码，且无法撤销。请先确认您有其他验证方式，或已在该服务中关闭两步验证。";

  static String m8(name) => "触摸 CanoKey 时改为输出 ${name} 的验证码？这会替换原来的触摸输出设置。";

  static String m9(keyType) => "修改 ${keyType} 密钥的触摸设置";

  static String m10(remaining) => "剩余次数：${remaining}";

  static String m11(seconds) => "${seconds} 秒";

  static String m12(retries) => "PIN 输入错误，剩余重试次数：${retries}";

  static String m13(algorithm) => "算法：${algorithm}";

  static String m14(slot) => "自签名证书已写入 ${slot} 槽。";

  static String m15(min, max) => "新 PUK 需要 ${min} 至 ${max} 个字符。";

  static String m16(slot) => "清空槽位 ${slot}";

  static String m17(slot) => "删除 ${slot} 槽位中的密钥和证书？此操作无法撤销，请先确认您有其他登录或解密方式。";

  static String m18(algorithm) => "正在生成 ${algorithm} 密钥";

  static String m19(slot) => "检查 ${slot} 槽位";

  static String m20(slot) => "已为 ${slot} 槽位应用推荐设置";

  static String m21(sourceSlot) => "移动 ${sourceSlot} 中的密钥";

  static String m22(count) => "${count} 个已占用";

  static String m23(action, slot) =>
      "${action} 将替换 ${slot} 槽中的私钥。依赖此密钥的认证或签名可能会失效。";

  static String m24(policy) => "PIN：${policy}";

  static String m25(index) => "历史密钥 ${index}";

  static String m26(remaining, total) => "剩余次数：${remaining}/${total}";

  static String m27(policy) => "触摸：${policy}";

  static String m28(layout) => "当前：${layout}";

  static String m29(applet) => "重置后，${applet} 中的所有数据都将被删除，无法恢复。";

  static String m30(min) => "至少 ${min} 个字符";

  static String m31(max) => "最多 ${max} 个字符";

  static String m32(length) => "需要 ${length} 个字符";

  static String m33(max) => "请输入不大于 ${max} 的整数。";

  static String m34(min) => "请输入不小于 ${min} 的整数。";

  static String m35(name) => "删除 ${name} 的登录凭据？此操作无法撤销，请先确认您有其他方式登录该服务。";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "actions": MessageLookupByLibrary.simpleMessage("操作"),
    "add": MessageLookupByLibrary.simpleMessage("添加"),
    "agreeAndContinue": MessageLookupByLibrary.simpleMessage("同意并继续"),
    "androidAlertTitle": MessageLookupByLibrary.simpleMessage("读取 CanoKey"),
    "androidPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请用手机背面触碰您的 CanoKey 或将其插入 USB 接口",
    ),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "CanoKey Console 是 CanoKey 开源安全密钥的管理工具。",
    ),
    "appletDisabled": m0,
    "appletLocked": MessageLookupByLibrary.simpleMessage("该应用已被锁定"),
    "applets": MessageLookupByLibrary.simpleMessage("应用"),
    "back": MessageLookupByLibrary.simpleMessage("上一步"),
    "beforeSourceLink": MessageLookupByLibrary.simpleMessage(
      "可在 GitHub 获得源代码：",
    ),
    "browserNotSupported": MessageLookupByLibrary.simpleMessage(
      "当前环境无法使用 WebUSB",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "change": MessageLookupByLibrary.simpleMessage("修改"),
    "changePin": MessageLookupByLibrary.simpleMessage("修改 PIN"),
    "changePinPrompt": m1,
    "close": MessageLookupByLibrary.simpleMessage("关闭"),
    "confirm": MessageLookupByLibrary.simpleMessage("确定"),
    "confirmNewPin": MessageLookupByLibrary.simpleMessage("再次输入新 PIN"),
    "connectFirst": MessageLookupByLibrary.simpleMessage("请先连接 CanoKey"),
    "copied": MessageLookupByLibrary.simpleMessage("已复制"),
    "copy": MessageLookupByLibrary.simpleMessage("复制"),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "deleted": MessageLookupByLibrary.simpleMessage("删除成功"),
    "desktopPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请将您的 CanoKey 插入 USB 接口",
    ),
    "desktopPollError": MessageLookupByLibrary.simpleMessage(
      "无法通过 USB 连接 CanoKey。请检查设备连接，然后重新打开此应用。错误详情：",
    ),
    "disable": MessageLookupByLibrary.simpleMessage("禁用"),
    "disableSound": MessageLookupByLibrary.simpleMessage("无音效"),
    "disagreeAndExit": MessageLookupByLibrary.simpleMessage("不同意并退出"),
    "enable": MessageLookupByLibrary.simpleMessage("启用"),
    "enabled": MessageLookupByLibrary.simpleMessage("启用"),
    "feedback": MessageLookupByLibrary.simpleMessage("意见反馈"),
    "fileSaveFailed": MessageLookupByLibrary.simpleMessage("保存文件失败"),
    "fileSaveFailedWithError": m2,
    "fileSaved": MessageLookupByLibrary.simpleMessage("保存成功"),
    "home": MessageLookupByLibrary.simpleMessage("首页"),
    "homeDirectlySelect": MessageLookupByLibrary.simpleMessage("请选择应用"),
    "homePress": MessageLookupByLibrary.simpleMessage("点击"),
    "homeScreenTitle": MessageLookupByLibrary.simpleMessage("CanoKey Console"),
    "homeSelect": MessageLookupByLibrary.simpleMessage("选择应用"),
    "interrupted": MessageLookupByLibrary.simpleMessage(
      "连接已中断。请重新连接；使用 NFC 时，请让 CanoKey 保持靠近手机。",
    ),
    "iosAlertMessage": MessageLookupByLibrary.simpleMessage(
      "使用 iPhone 顶部读取 CanoKey",
    ),
    "iosPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请下拉页面或点击刷新按钮，然后用 iPhone 顶部靠近 CanoKey；也可将其插入 USB 接口",
    ),
    "logsCopied": MessageLookupByLibrary.simpleMessage("已复制日志"),
    "logsCopyFailed": MessageLookupByLibrary.simpleMessage("无法复制日志"),
    "logsEmpty": MessageLookupByLibrary.simpleMessage("本次运行暂无日志"),
    "logsRecording": MessageLookupByLibrary.simpleMessage("记录日志"),
    "logsTitle": MessageLookupByLibrary.simpleMessage("查看日志"),
    "ndefAbsoluteUri": MessageLookupByLibrary.simpleMessage("绝对 URI"),
    "ndefAddRecord": MessageLookupByLibrary.simpleMessage("添加记录"),
    "ndefAndroidApplication": MessageLookupByLibrary.simpleMessage(
      "Android 应用",
    ),
    "ndefAndroidPackage": MessageLookupByLibrary.simpleMessage("Android 包名"),
    "ndefBluetoothAddressType": MessageLookupByLibrary.simpleMessage("地址类型"),
    "ndefBluetoothClassic": MessageLookupByLibrary.simpleMessage("经典蓝牙"),
    "ndefBluetoothLowEnergy": MessageLookupByLibrary.simpleMessage("低功耗蓝牙"),
    "ndefBluetoothPublicAddress": MessageLookupByLibrary.simpleMessage("公共地址"),
    "ndefBluetoothRandomAddress": MessageLookupByLibrary.simpleMessage("随机地址"),
    "ndefBytesUsed": m3,
    "ndefCapacity": MessageLookupByLibrary.simpleMessage("容量"),
    "ndefCapacityExceeded": MessageLookupByLibrary.simpleMessage(
      "内容超出 NFC 标签的容量，请减少内容后重试。",
    ),
    "ndefContact": MessageLookupByLibrary.simpleMessage("联系人"),
    "ndefContactEmail": MessageLookupByLibrary.simpleMessage("邮箱（可选）"),
    "ndefContactName": MessageLookupByLibrary.simpleMessage("姓名"),
    "ndefContactOrganization": MessageLookupByLibrary.simpleMessage("组织（可选）"),
    "ndefCustom": MessageLookupByLibrary.simpleMessage("自定义记录"),
    "ndefDeviceInformation": MessageLookupByLibrary.simpleMessage("设备信息"),
    "ndefDeviceModel": MessageLookupByLibrary.simpleMessage("型号"),
    "ndefDeviceName": MessageLookupByLibrary.simpleMessage("设备名称（可选）"),
    "ndefDeviceUniqueName": MessageLookupByLibrary.simpleMessage("唯一名称（可选）"),
    "ndefDeviceVendor": MessageLookupByLibrary.simpleMessage("厂商"),
    "ndefDeviceVersion": MessageLookupByLibrary.simpleMessage("版本（可选）"),
    "ndefEditRecord": MessageLookupByLibrary.simpleMessage("编辑记录"),
    "ndefEncoding": MessageLookupByLibrary.simpleMessage("文本编码"),
    "ndefExternal": MessageLookupByLibrary.simpleMessage("外部类型"),
    "ndefExternalType": MessageLookupByLibrary.simpleMessage("外部类型名称"),
    "ndefHandover": MessageLookupByLibrary.simpleMessage("连接切换"),
    "ndefHandoverType": MessageLookupByLibrary.simpleMessage("切换记录类型"),
    "ndefInvalidEmail": MessageLookupByLibrary.simpleMessage("请输入有效的邮箱地址。"),
    "ndefInvalidExternalType": MessageLookupByLibrary.simpleMessage(
      "请输入小写外部类型，例如 example.com:record。",
    ),
    "ndefInvalidLanguage": MessageLookupByLibrary.simpleMessage(
      "请输入有效的语言代码，例如 en 或 zh-Hans。",
    ),
    "ndefInvalidMacAddress": MessageLookupByLibrary.simpleMessage(
      "请输入类似 AA:BB:CC:DD:EE:FF 的 MAC 地址。",
    ),
    "ndefInvalidMessage": MessageLookupByLibrary.simpleMessage(
      "无法读取已有的 NFC 标签内容。如需重新设置，请在设置中重置 NDEF；这会删除原有的标签内容。",
    ),
    "ndefInvalidMimeType": MessageLookupByLibrary.simpleMessage(
      "请输入有效的 MIME 类型，例如 text/plain。",
    ),
    "ndefInvalidPackageName": MessageLookupByLibrary.simpleMessage(
      "请输入有效的 Android 包名，例如 com.example.app。",
    ),
    "ndefInvalidPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "请输入有效的电话号码。",
    ),
    "ndefInvalidRecord": m4,
    "ndefInvalidUri": MessageLookupByLibrary.simpleMessage(
      "请输入完整的链接，例如 https://example.com 或 mailto:name@example.com。",
    ),
    "ndefInvalidUuid": MessageLookupByLibrary.simpleMessage("请输入标准格式的 UUID。"),
    "ndefLanguage": MessageLookupByLibrary.simpleMessage("语言代码"),
    "ndefMacAddress": MessageLookupByLibrary.simpleMessage("MAC 地址"),
    "ndefMime": MessageLookupByLibrary.simpleMessage("MIME"),
    "ndefMimeType": MessageLookupByLibrary.simpleMessage("MIME 类型"),
    "ndefMoveDown": MessageLookupByLibrary.simpleMessage("下移"),
    "ndefMoveUp": MessageLookupByLibrary.simpleMessage("上移"),
    "ndefNoRecords": MessageLookupByLibrary.simpleMessage("暂无记录"),
    "ndefNoRecordsDescription": MessageLookupByLibrary.simpleMessage(
      "添加链接、文本或其他内容，供其他设备通过 NFC 读取。",
    ),
    "ndefOptionalHex": MessageLookupByLibrary.simpleMessage("十六进制内容，可留空"),
    "ndefOther": MessageLookupByLibrary.simpleMessage("其他"),
    "ndefPayload": MessageLookupByLibrary.simpleMessage("记录内容"),
    "ndefPayloadConversionFailed": MessageLookupByLibrary.simpleMessage(
      "无法转换内容编码。请检查十六进制格式，或确认内容是有效的 UTF-8 文本。",
    ),
    "ndefPayloadEncoding": MessageLookupByLibrary.simpleMessage("内容编码"),
    "ndefPayloadHex": MessageLookupByLibrary.simpleMessage("十六进制"),
    "ndefPayloadText": MessageLookupByLibrary.simpleMessage("文本"),
    "ndefPhone": MessageLookupByLibrary.simpleMessage("电话"),
    "ndefPhoneNumber": MessageLookupByLibrary.simpleMessage("电话号码"),
    "ndefReadOnly": MessageLookupByLibrary.simpleMessage("NDEF 标签当前为只读。"),
    "ndefReadOnlyDescription": MessageLookupByLibrary.simpleMessage(
      "当前无法写入。请先在设置中关闭“NFC 标签只读”。",
    ),
    "ndefReadOnlyStatus": MessageLookupByLibrary.simpleMessage("只读"),
    "ndefRecordId": MessageLookupByLibrary.simpleMessage("记录 ID（可选，十六进制）"),
    "ndefRecordType": MessageLookupByLibrary.simpleMessage("记录类型"),
    "ndefRecords": MessageLookupByLibrary.simpleMessage("记录"),
    "ndefRequiredField": MessageLookupByLibrary.simpleMessage("请填写此项。"),
    "ndefSaveToKey": MessageLookupByLibrary.simpleMessage("保存到 CanoKey"),
    "ndefSaved": MessageLookupByLibrary.simpleMessage("NDEF 记录已保存"),
    "ndefSignature": MessageLookupByLibrary.simpleMessage("签名"),
    "ndefSmartPoster": MessageLookupByLibrary.simpleMessage("智能海报"),
    "ndefSmartPosterAction": MessageLookupByLibrary.simpleMessage("建议操作"),
    "ndefSmartPosterActionEdit": MessageLookupByLibrary.simpleMessage("编辑"),
    "ndefSmartPosterActionOpen": MessageLookupByLibrary.simpleMessage("打开"),
    "ndefSmartPosterActionSave": MessageLookupByLibrary.simpleMessage("保存"),
    "ndefSmartPosterTitle": MessageLookupByLibrary.simpleMessage("标题（可选）"),
    "ndefTagContent": MessageLookupByLibrary.simpleMessage("NFC 标签内容"),
    "ndefTagContentDescription": MessageLookupByLibrary.simpleMessage(
      "设置其他设备通过 NFC 读取 CanoKey 时获得的内容。",
    ),
    "ndefText": MessageLookupByLibrary.simpleMessage("文本"),
    "ndefTextValue": MessageLookupByLibrary.simpleMessage("文本内容"),
    "ndefTnfAbsoluteUri": MessageLookupByLibrary.simpleMessage("绝对 URI"),
    "ndefTnfEmpty": MessageLookupByLibrary.simpleMessage("空记录"),
    "ndefTnfExternal": MessageLookupByLibrary.simpleMessage("NFC Forum 外部类型"),
    "ndefTnfMedia": MessageLookupByLibrary.simpleMessage("媒体类型 (MIME)"),
    "ndefTnfRequiresEmptyType": MessageLookupByLibrary.simpleMessage(
      "所选记录格式不允许填写类型名称，请清空该字段。",
    ),
    "ndefTnfUnchanged": MessageLookupByLibrary.simpleMessage("沿用上一段的类型"),
    "ndefTnfUnknown": MessageLookupByLibrary.simpleMessage("未知类型"),
    "ndefTnfWellKnown": MessageLookupByLibrary.simpleMessage("NFC Forum 已知类型"),
    "ndefTypeName": MessageLookupByLibrary.simpleMessage("类型名称"),
    "ndefTypeNameFormat": MessageLookupByLibrary.simpleMessage("类型名称格式（TNF）"),
    "ndefUnsavedChanges": MessageLookupByLibrary.simpleMessage("有尚未保存的修改"),
    "ndefUri": MessageLookupByLibrary.simpleMessage("链接"),
    "ndefUriValue": MessageLookupByLibrary.simpleMessage("链接地址"),
    "ndefWifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
    "ndefWifiAuthentication": MessageLookupByLibrary.simpleMessage("认证方式"),
    "ndefWifiEncryption": MessageLookupByLibrary.simpleMessage("加密方式"),
    "ndefWifiEnterprise": m5,
    "ndefWifiNoEncryption": MessageLookupByLibrary.simpleMessage("不加密"),
    "ndefWifiOpen": MessageLookupByLibrary.simpleMessage("开放网络"),
    "ndefWifiPassword": MessageLookupByLibrary.simpleMessage("网络密码"),
    "ndefWifiPersonal": m6,
    "ndefWifiShared": MessageLookupByLibrary.simpleMessage("共享密钥"),
    "ndefWritable": MessageLookupByLibrary.simpleMessage("可写"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "与 CanoKey 通信失败，请重新连接后重试。",
    ),
    "newPin": MessageLookupByLibrary.simpleMessage("新 PIN"),
    "next": MessageLookupByLibrary.simpleMessage("下一步"),
    "nfcSound": MessageLookupByLibrary.simpleMessage("NFC 交互音效"),
    "nfcSoundPrompt": MessageLookupByLibrary.simpleMessage(
      "播放顺序：读卡开始、读卡结束、读卡失败",
    ),
    "noCard": MessageLookupByLibrary.simpleMessage("未找到 CanoKey"),
    "noCredential": MessageLookupByLibrary.simpleMessage("没有找到凭据"),
    "noMatchingCredential": MessageLookupByLibrary.simpleMessage("没有找到匹配的凭据"),
    "notSupported": MessageLookupByLibrary.simpleMessage("不支持该操作"),
    "notSupportedInNFC": MessageLookupByLibrary.simpleMessage(
      "此操作需要通过 USB 连接 CanoKey。",
    ),
    "oathAccount": MessageLookupByLibrary.simpleMessage("账户"),
    "oathAddAccount": MessageLookupByLibrary.simpleMessage("添加账户"),
    "oathAddByScanning": MessageLookupByLibrary.simpleMessage("扫码添加"),
    "oathAddByScreen": MessageLookupByLibrary.simpleMessage("扫描屏幕上的二维码"),
    "oathAddManually": MessageLookupByLibrary.simpleMessage("手动添加"),
    "oathAdded": MessageLookupByLibrary.simpleMessage("添加成功"),
    "oathAdvancedSettings": MessageLookupByLibrary.simpleMessage(
      "请使用服务商提供的参数，否则生成的验证码可能无法使用。",
    ),
    "oathAlgorithm": MessageLookupByLibrary.simpleMessage("算法"),
    "oathCode": MessageLookupByLibrary.simpleMessage("口令"),
    "oathCodeChanged": MessageLookupByLibrary.simpleMessage("口令已修改"),
    "oathCopy": MessageLookupByLibrary.simpleMessage("复制"),
    "oathCounter": MessageLookupByLibrary.simpleMessage("计数器初始值"),
    "oathCounterMustBeNumber": MessageLookupByLibrary.simpleMessage("请输入整数"),
    "oathDelete": m7,
    "oathDescription": MessageLookupByLibrary.simpleMessage(
      "管理账户的一次性验证码（TOTP / HOTP）。",
    ),
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
      "输入新口令。留空并保存可取消口令保护。",
    ),
    "oathNoQr": MessageLookupByLibrary.simpleMessage("未检测到二维码"),
    "oathPeriod": MessageLookupByLibrary.simpleMessage("更新间隔（秒）"),
    "oathRequireTouch": MessageLookupByLibrary.simpleMessage("需要触摸"),
    "oathRequired": MessageLookupByLibrary.simpleMessage("请填写此项"),
    "oathSearch": MessageLookupByLibrary.simpleMessage("搜索账户名称或邮箱"),
    "oathSecret": MessageLookupByLibrary.simpleMessage("密钥"),
    "oathSetCode": MessageLookupByLibrary.simpleMessage("设置口令"),
    "oathSetDefault": MessageLookupByLibrary.simpleMessage("设为触摸输出"),
    "oathSetDefaultPrompt": m8,
    "oathSlot": MessageLookupByLibrary.simpleMessage("口令槽"),
    "oathTooLong": MessageLookupByLibrary.simpleMessage("长度超限"),
    "oathType": MessageLookupByLibrary.simpleMessage("类型"),
    "off": MessageLookupByLibrary.simpleMessage("关"),
    "oldPin": MessageLookupByLibrary.simpleMessage("当前 PIN"),
    "on": MessageLookupByLibrary.simpleMessage("开"),
    "openpgpAdminPin": MessageLookupByLibrary.simpleMessage("管理员 PIN"),
    "openpgpAdminPinLength": MessageLookupByLibrary.simpleMessage(
      "管理员 PIN 长度必须为 8 到 64 个字符。",
    ),
    "openpgpAuthentication": MessageLookupByLibrary.simpleMessage("认证"),
    "openpgpCacheSeconds": MessageLookupByLibrary.simpleMessage("有效时间（秒）"),
    "openpgpCardHolder": MessageLookupByLibrary.simpleMessage("持卡人"),
    "openpgpCardInfo": MessageLookupByLibrary.simpleMessage("卡片信息"),
    "openpgpChangeAdminPin": MessageLookupByLibrary.simpleMessage("修改 管理员 PIN"),
    "openpgpChangeInteraction": m9,
    "openpgpChangeSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "修改签名 PIN 策略",
    ),
    "openpgpChangeTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "修改触摸确认有效时间",
    ),
    "openpgpCurrentAdminPin": MessageLookupByLibrary.simpleMessage(
      "当前 管理员 PIN",
    ),
    "openpgpDescription": MessageLookupByLibrary.simpleMessage(
      "查看 OpenPGP 卡片信息，管理 PIN 和触摸确认方式。",
    ),
    "openpgpEncryption": MessageLookupByLibrary.simpleMessage("加密"),
    "openpgpKeyEmpty": MessageLookupByLibrary.simpleMessage("空"),
    "openpgpKeyImported": MessageLookupByLibrary.simpleMessage("已导入"),
    "openpgpKeyNone": MessageLookupByLibrary.simpleMessage("未配置"),
    "openpgpKeys": MessageLookupByLibrary.simpleMessage("密钥信息"),
    "openpgpManufacturer": MessageLookupByLibrary.simpleMessage("制造商"),
    "openpgpNewAdminPin": MessageLookupByLibrary.simpleMessage("新 管理员 PIN"),
    "openpgpPermanentTouchConfirmation": MessageLookupByLibrary.simpleMessage(
      "我确认永久启用后，此密钥的触摸策略无法再关闭。",
    ),
    "openpgpPubkeyUrl": MessageLookupByLibrary.simpleMessage("公钥地址"),
    "openpgpResetCode": MessageLookupByLibrary.simpleMessage("重置码"),
    "openpgpRetries": m10,
    "openpgpRetriesUnknown": MessageLookupByLibrary.simpleMessage("剩余次数：未知"),
    "openpgpSN": MessageLookupByLibrary.simpleMessage("序列号"),
    "openpgpSetPinRetries": MessageLookupByLibrary.simpleMessage("设置 PIN 重试次数"),
    "openpgpSetPinRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作会将 用户 PIN 重置为 123456，管理员 PIN 重置为 12345678。",
    ),
    "openpgpSetPinRetriesTitle": MessageLookupByLibrary.simpleMessage(
      "设置 PIN 和重置码的重试次数",
    ),
    "openpgpSetResetCode": MessageLookupByLibrary.simpleMessage("设置 重置码"),
    "openpgpSetResetCodePrompt": MessageLookupByLibrary.simpleMessage(
      "重置码 长度必须为 8 到 64 个字符，需要 管理员 PIN 授权。",
    ),
    "openpgpSetTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "设置触摸确认有效时间",
    ),
    "openpgpSetTouchCacheTimePrompt": MessageLookupByLibrary.simpleMessage(
      "设置触摸一次后多久内无需再次触摸。设为 0 表示每次操作都需触摸。修改需要验证管理员 PIN。",
    ),
    "openpgpSignature": MessageLookupByLibrary.simpleMessage("签名"),
    "openpgpSignaturePin": MessageLookupByLibrary.simpleMessage("签名 PIN"),
    "openpgpSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "签名 PIN 策略",
    ),
    "openpgpTouchCacheOff": MessageLookupByLibrary.simpleMessage("0 秒（每次触摸）"),
    "openpgpTouchCacheSeconds": m11,
    "openpgpTouchCached": MessageLookupByLibrary.simpleMessage("限时免触摸"),
    "openpgpTouchCachedLabel": MessageLookupByLibrary.simpleMessage("触摸：限时免确认"),
    "openpgpTouchNone": MessageLookupByLibrary.simpleMessage("无需触摸"),
    "openpgpTouchOffLabel": MessageLookupByLibrary.simpleMessage("触摸：关闭"),
    "openpgpTouchOnLabel": MessageLookupByLibrary.simpleMessage("触摸：开启"),
    "openpgpTouchPermanent": MessageLookupByLibrary.simpleMessage("需要触摸（不可关闭）"),
    "openpgpTouchPermanentCached": MessageLookupByLibrary.simpleMessage(
      "限时免触摸（不可关闭）",
    ),
    "openpgpTouchPermanentCachedLabel": MessageLookupByLibrary.simpleMessage(
      "触摸：限时免确认，不可关闭",
    ),
    "openpgpTouchPermanentLabel": MessageLookupByLibrary.simpleMessage(
      "触摸：需要，不可关闭",
    ),
    "openpgpTouchRequired": MessageLookupByLibrary.simpleMessage("需要触摸"),
    "openpgpUIF": MessageLookupByLibrary.simpleMessage("触摸设置"),
    "openpgpUifCacheTime": MessageLookupByLibrary.simpleMessage("触摸确认有效时间"),
    "openpgpUifCacheTimeChanged": MessageLookupByLibrary.simpleMessage(
      "触摸确认有效时间已修改",
    ),
    "openpgpUifChanged": MessageLookupByLibrary.simpleMessage("触摸设置修改成功"),
    "openpgpUifOff": MessageLookupByLibrary.simpleMessage("关闭"),
    "openpgpUifOn": MessageLookupByLibrary.simpleMessage("打开"),
    "openpgpUifPermanent": MessageLookupByLibrary.simpleMessage("永久启用（无法再关闭）"),
    "openpgpUnblockUserPin": MessageLookupByLibrary.simpleMessage("解锁 用户 PIN"),
    "openpgpUseAdminPin": MessageLookupByLibrary.simpleMessage("使用 管理员 PIN"),
    "openpgpUseResetCode": MessageLookupByLibrary.simpleMessage("使用 重置码"),
    "openpgpUserPin": MessageLookupByLibrary.simpleMessage("用户 PIN"),
    "openpgpUserPinLength": MessageLookupByLibrary.simpleMessage(
      "用户 PIN 长度必须为 6 到 64 个字符。",
    ),
    "openpgpVerifyEverySignature": MessageLookupByLibrary.simpleMessage(
      "每次签名都验证",
    ),
    "openpgpVerifyEverySignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "每次签名都验证 用户 PIN",
    ),
    "openpgpVerifyOnceAfterInsertion": MessageLookupByLibrary.simpleMessage(
      "插入后验证一次",
    ),
    "openpgpVerifyOnceAfterInsertionPrompt":
        MessageLookupByLibrary.simpleMessage("每次插入后只验证一次"),
    "openpgpVersion": MessageLookupByLibrary.simpleMessage("版本"),
    "operationFailed": MessageLookupByLibrary.simpleMessage(
      "操作失败，请重新读取 CanoKey 后重试。",
    ),
    "other": MessageLookupByLibrary.simpleMessage("其他"),
    "passDescription": MessageLookupByLibrary.simpleMessage(
      "设置短按或长按 CanoKey 时输出的密码。",
    ),
    "passInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "请输入设置页面使用的管理 PIN，默认值为 123456。",
    ),
    "passNotSupported": MessageLookupByLibrary.simpleMessage(
      "您的 CanoKey 不支持 Pass 功能。",
    ),
    "passSlotConfigPrompt": MessageLookupByLibrary.simpleMessage(
      "选择触摸 CanoKey 时执行的操作。如需输出 HOTP 验证码，请在 TOTP / HOTP 页面设置。",
    ),
    "passSlotConfigTitle": MessageLookupByLibrary.simpleMessage("触摸输出设置"),
    "passSlotHmacSha1": MessageLookupByLibrary.simpleMessage("HMAC-SHA1"),
    "passSlotHmacSha1Key": MessageLookupByLibrary.simpleMessage(
      "20 字节 HMAC-SHA1 密钥（十六进制）",
    ),
    "passSlotHotp": MessageLookupByLibrary.simpleMessage("HOTP"),
    "passSlotLong": MessageLookupByLibrary.simpleMessage("长按"),
    "passSlotOff": MessageLookupByLibrary.simpleMessage("关闭"),
    "passSlotShort": MessageLookupByLibrary.simpleMessage("短按"),
    "passSlotStatic": MessageLookupByLibrary.simpleMessage("固定密码"),
    "passSlotWithEnter": MessageLookupByLibrary.simpleMessage("输出后按回车"),
    "passStatus": MessageLookupByLibrary.simpleMessage("状态"),
    "passkey": MessageLookupByLibrary.simpleMessage("通行密钥"),
    "pinChanged": MessageLookupByLibrary.simpleMessage("PIN 修改成功"),
    "pinConfirmationMismatch": MessageLookupByLibrary.simpleMessage(
      "两次输入的 PIN 不一致",
    ),
    "pinIncorrect": MessageLookupByLibrary.simpleMessage("PIN 输入错误"),
    "pinInvalidLength": MessageLookupByLibrary.simpleMessage("长度错误"),
    "pinLength": MessageLookupByLibrary.simpleMessage("输入的 PIN 长度错误"),
    "pinRetries": m12,
    "pinVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "PIN 验证失败，请重新读取 CanoKey 后重试。",
    ),
    "pivActionsDescription": MessageLookupByLibrary.simpleMessage(
      "选择此槽位要执行的操作。",
    ),
    "pivAlgorithm": MessageLookupByLibrary.simpleMessage("密钥算法"),
    "pivAlgorithmColumn": MessageLookupByLibrary.simpleMessage("算法"),
    "pivAlgorithmIds": MessageLookupByLibrary.simpleMessage("算法 ID"),
    "pivAlgorithmIdsPrompt": MessageLookupByLibrary.simpleMessage(
      "允许 CanoKey 使用扩展算法。",
    ),
    "pivAlgorithmIdsTitle": MessageLookupByLibrary.simpleMessage("PIV 算法 ID"),
    "pivAlgorithmIdsUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "更新 PIV 算法 ID 失败",
    ),
    "pivAlgorithmIdsWarning": MessageLookupByLibrary.simpleMessage(
      "通常无需修改。只有软件或固件要求使用其他算法 ID 时才需要更改。填错后，已有密钥可能无法识别；恢复正确的 ID 后可重新识别。",
    ),
    "pivAlgorithmValue": m13,
    "pivAttestationUnavailable": MessageLookupByLibrary.simpleMessage(
      "无法生成证明证书。设备必须已配置 F9 证明密钥和证书。",
    ),
    "pivAuthentication": MessageLookupByLibrary.simpleMessage(
      "认证（Authentication）",
    ),
    "pivBasicConstraints": MessageLookupByLibrary.simpleMessage("证书基本约束"),
    "pivCardAuthentication": MessageLookupByLibrary.simpleMessage(
      "卡认证（Card Authentication）",
    ),
    "pivCertificate": MessageLookupByLibrary.simpleMessage("证书"),
    "pivCertificateCopied": MessageLookupByLibrary.simpleMessage("证书已复制"),
    "pivCertificateCreated": MessageLookupByLibrary.simpleMessage("证书已创建"),
    "pivCertificateCustom": MessageLookupByLibrary.simpleMessage("自定义设置"),
    "pivCertificateDoesNotMatchPrivateKey":
        MessageLookupByLibrary.simpleMessage("证书公钥与所选私钥不匹配。"),
    "pivCertificateExtensions": MessageLookupByLibrary.simpleMessage("证书扩展"),
    "pivCertificateInfo": MessageLookupByLibrary.simpleMessage("证书信息"),
    "pivCertificateInfoDescription": MessageLookupByLibrary.simpleMessage(
      "当前槽位中的证书详细信息。",
    ),
    "pivCertificateIssuer": MessageLookupByLibrary.simpleMessage("签发者"),
    "pivCertificateKey": MessageLookupByLibrary.simpleMessage("证书公钥"),
    "pivCertificateMatchesPrivateKey": MessageLookupByLibrary.simpleMessage(
      "证书与私钥匹配",
    ),
    "pivCertificateMismatchPrivateKey": MessageLookupByLibrary.simpleMessage(
      "证书与私钥不匹配",
    ),
    "pivCertificateOnlyKeepsPrivateKey": MessageLookupByLibrary.simpleMessage(
      "只导入证书不会改变私钥。请确认该证书属于卡内已有私钥。",
    ),
    "pivCertificatePresent": MessageLookupByLibrary.simpleMessage("已存有证书"),
    "pivCertificateSerial": MessageLookupByLibrary.simpleMessage("序列号"),
    "pivCertificateSize": MessageLookupByLibrary.simpleMessage("证书大小"),
    "pivCertificateStatus": MessageLookupByLibrary.simpleMessage("证书状态"),
    "pivCertificateSubject": MessageLookupByLibrary.simpleMessage("证书主体"),
    "pivCertificateSubjectAndExtensions": MessageLookupByLibrary.simpleMessage(
      "证书信息与扩展",
    ),
    "pivCertificateSubjectStep": MessageLookupByLibrary.simpleMessage("证书主体信息"),
    "pivCertificateValidFrom": MessageLookupByLibrary.simpleMessage("生效时间"),
    "pivCertificateValidTo": MessageLookupByLibrary.simpleMessage("失效时间"),
    "pivCertificateWritten": m14,
    "pivChangeManagementKey": MessageLookupByLibrary.simpleMessage("修改管理密钥"),
    "pivChangeManagementKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "新管理密钥的长度应当为 24 字节。请妥善保管管理密钥，否则您将无法管理 PIV 应用。",
    ),
    "pivChangePUK": MessageLookupByLibrary.simpleMessage("修改 PUK"),
    "pivChangePUKPrompt": m15,
    "pivClearSlot": MessageLookupByLibrary.simpleMessage("清空槽位"),
    "pivClearSlotFailed": MessageLookupByLibrary.simpleMessage(
      "清空槽位失败。请确认固件支持删除私钥。",
    ),
    "pivClearSlotPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作会删除此槽位中的私钥和证书。请确认您仍有其他认证方式。",
    ),
    "pivClearSlotTitle": m16,
    "pivCommonName": MessageLookupByLibrary.simpleMessage("通用名称（CN）"),
    "pivCopyPem": MessageLookupByLibrary.simpleMessage("复制 PEM"),
    "pivCountryCode": MessageLookupByLibrary.simpleMessage("国家或地区代码"),
    "pivCreateCertificate": MessageLookupByLibrary.simpleMessage("创建证书"),
    "pivCreateCertificateFailed": MessageLookupByLibrary.simpleMessage(
      "创建证书失败",
    ),
    "pivCreatingSelfSignedCertificate": MessageLookupByLibrary.simpleMessage(
      "创建自签名证书",
    ),
    "pivCsrCopied": MessageLookupByLibrary.simpleMessage("CSR 已复制"),
    "pivCsrGenerated": MessageLookupByLibrary.simpleMessage("CSR 已生成"),
    "pivCsrGenerationPrompt": MessageLookupByLibrary.simpleMessage(
      "生成证书签名请求（CSR），用于向证书颁发机构申请证书。新密钥将在 CanoKey 中生成。",
    ),
    "pivCsrSubject": MessageLookupByLibrary.simpleMessage("证书请求信息"),
    "pivDangerDescription": MessageLookupByLibrary.simpleMessage(
      "移动或删除密钥前，请确认您有其他登录或解密方式。",
    ),
    "pivDangerZone": MessageLookupByLibrary.simpleMessage("危险操作"),
    "pivDelete": MessageLookupByLibrary.simpleMessage("删除"),
    "pivDeleteSlot": m17,
    "pivDestinationSlot": MessageLookupByLibrary.simpleMessage("目标槽位"),
    "pivDiagnostics": MessageLookupByLibrary.simpleMessage("密钥操作"),
    "pivDisablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "改为手动管理密钥",
    ),
    "pivDisablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage("改为手动管理密钥失败"),
    "pivDisablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage(
          "将设置新的管理密钥，并删除 CanoKey 中由 PIN 保护的副本。之后需要手动输入管理密钥。PUK 仍会锁定；如需恢复 PUK，可在退出此模式后重设重试次数，但这也会重置 PIN。",
        ),
    "pivDisablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage("之后需要手动输入管理密钥"),
    "pivDnsSans": MessageLookupByLibrary.simpleMessage("域名（多个域名用逗号分隔）"),
    "pivDownloadAttestation": MessageLookupByLibrary.simpleMessage("下载证明证书"),
    "pivEmpty": MessageLookupByLibrary.simpleMessage("空"),
    "pivEnablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "使用 PIN 保护管理密钥",
    ),
    "pivEnablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage("保存 PIN 保护管理密钥失败"),
    "pivEnablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage(
          "启用后，管理密钥将随机生成并保存在 CanoKey 中，后续管理操作只需验证 PIN。PUK 将被锁定，无法再用于重设或解锁 PIN。启用期间也无法修改 PIN 和 PUK 的重试次数。",
        ),
    "pivEnablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage("管理密钥已由 PIN 保护"),
    "pivEndEntityConstraint": MessageLookupByLibrary.simpleMessage(
      "标记为非 CA 证书（CA=false）",
    ),
    "pivExport": MessageLookupByLibrary.simpleMessage("导出"),
    "pivExportCertificate": MessageLookupByLibrary.simpleMessage("导出证书"),
    "pivExportDescription": MessageLookupByLibrary.simpleMessage(
      "将证书或公钥保存到文件。",
    ),
    "pivExportPublicKey": MessageLookupByLibrary.simpleMessage("导出公钥"),
    "pivExtendedAlgorithmCompatibilityWarning":
        MessageLookupByLibrary.simpleMessage("请先确认您要使用的软件支持此算法。"),
    "pivExtendedKeyUsage": MessageLookupByLibrary.simpleMessage("扩展密钥用途（EKU）"),
    "pivExtensionsDescription": MessageLookupByLibrary.simpleMessage(
      "设置证书的基本约束、密钥用途和扩展密钥用途。",
    ),
    "pivFile": MessageLookupByLibrary.simpleMessage("文件"),
    "pivFileSigningFailed": MessageLookupByLibrary.simpleMessage("文件签名失败"),
    "pivGenerate": MessageLookupByLibrary.simpleMessage("生成"),
    "pivGenerateCsr": MessageLookupByLibrary.simpleMessage("生成 CSR"),
    "pivGenerateCsrFailed": MessageLookupByLibrary.simpleMessage("生成 CSR 失败"),
    "pivGenerateKey": MessageLookupByLibrary.simpleMessage("生成密钥"),
    "pivGenerateKeyFailed": MessageLookupByLibrary.simpleMessage("生成密钥失败"),
    "pivGenerateX25519": MessageLookupByLibrary.simpleMessage("生成 X25519"),
    "pivGenerateX25519Key": MessageLookupByLibrary.simpleMessage(
      "生成 X25519 密钥",
    ),
    "pivGenerateX25519KeyFailed": MessageLookupByLibrary.simpleMessage(
      "生成 X25519 密钥失败",
    ),
    "pivGeneratingCsr": MessageLookupByLibrary.simpleMessage("生成 CSR"),
    "pivGeneratingKey": m18,
    "pivGeneratingX25519Key": MessageLookupByLibrary.simpleMessage(
      "生成 X25519 密钥",
    ),
    "pivImport": MessageLookupByLibrary.simpleMessage("导入"),
    "pivImportFailed": MessageLookupByLibrary.simpleMessage("导入失败"),
    "pivImportSucceeded": MessageLookupByLibrary.simpleMessage("导入成功"),
    "pivImportWillReplaceCertificate": MessageLookupByLibrary.simpleMessage(
      "本次导入会替换此槽位中现有的证书。",
    ),
    "pivImportWillReplacePrivateKey": MessageLookupByLibrary.simpleMessage(
      "本次导入会替换此槽位中现有的私钥。",
    ),
    "pivImportingPrivateKey": MessageLookupByLibrary.simpleMessage("导入私钥"),
    "pivKeyGenerated": MessageLookupByLibrary.simpleMessage("密钥已生成"),
    "pivKeyManagement": MessageLookupByLibrary.simpleMessage(
      "密钥管理（Key Management）",
    ),
    "pivKeyMoved": MessageLookupByLibrary.simpleMessage("密钥已移动"),
    "pivKeyOnlyKeepsCertificate": MessageLookupByLibrary.simpleMessage(
      "只导入私钥会保留现有证书。如证书不再匹配，请替换或清空证书。",
    ),
    "pivKeyOperationsDescription": MessageLookupByLibrary.simpleMessage(
      "为消息或文件签名，或验证文件签名。",
    ),
    "pivKeyOptions": MessageLookupByLibrary.simpleMessage("密钥选项"),
    "pivKeyUsage": MessageLookupByLibrary.simpleMessage("密钥用途（Key Usage）"),
    "pivKeyUsageCritical": MessageLookupByLibrary.simpleMessage("要求验证方检查密钥用途"),
    "pivMacLogin": MessageLookupByLibrary.simpleMessage("macOS 登录"),
    "pivMacLoginDescription": MessageLookupByLibrary.simpleMessage(
      "使用 PIV 证书登录 macOS。",
    ),
    "pivMacOsAfterAuthentication": MessageLookupByLibrary.simpleMessage(
      "9A 槽位配置已完成。请继续检查 9D 槽位，确认已配置用于解锁登录钥匙串的密钥和证书。",
    ),
    "pivMacOsAfterKeychain": MessageLookupByLibrary.simpleMessage(
      "9D 槽位配置已完成。请确认 9A 槽位也已配置，然后重新插入 CanoKey，并按照 macOS 的提示，将智能卡与您的用户账户配对。",
    ),
    "pivMacOsApply": MessageLookupByLibrary.simpleMessage("应用 macOS 登录推荐设置"),
    "pivMacOsAuthenticationSlot": MessageLookupByLibrary.simpleMessage(
      "9A · 身份验证",
    ),
    "pivMacOsCheckSlot": m19,
    "pivMacOsDescription": MessageLookupByLibrary.simpleMessage(
      "9A 槽位中的密钥和证书用于 macOS 登录时的身份验证。还需配置 9D 槽位，用于解锁登录钥匙串。",
    ),
    "pivMacOsGuide": MessageLookupByLibrary.simpleMessage(
      "配置 9A 槽位用于登录时的身份验证，配置 9D 槽位用于解锁登录钥匙串。完成后，请重新插入 CanoKey，并按照 macOS 的提示，将智能卡与您的用户账户配对。",
    ),
    "pivMacOsGuideTitle": MessageLookupByLibrary.simpleMessage(
      "使用 CanoKey 登录 macOS",
    ),
    "pivMacOsKeychainDescription": MessageLookupByLibrary.simpleMessage(
      "9D 槽位中的密钥和证书用于解锁 macOS 登录钥匙串。还需配置 9A 槽位，用于登录时的身份验证。",
    ),
    "pivMacOsKeychainSlot": MessageLookupByLibrary.simpleMessage("9D · 解锁钥匙串"),
    "pivMacOsOtherSlot": MessageLookupByLibrary.simpleMessage(
      "使用 CanoKey 登录 macOS，需要配置 9A 和 9D 两个槽位。",
    ),
    "pivMacOsSlotApplied": m20,
    "pivMacSetupConsent": MessageLookupByLibrary.simpleMessage(
      "我确认替换上面列出的密钥或证书。被替换的密钥无法恢复。",
    ),
    "pivMacSetupCreate": MessageLookupByLibrary.simpleMessage("生成密钥和证书"),
    "pivMacSetupCredentials": MessageLookupByLibrary.simpleMessage(
      "请输入 PIV PIN 和管理密钥。",
    ),
    "pivMacSetupDone": MessageLookupByLibrary.simpleMessage(
      "CanoKey 配置完成。请重新插入 CanoKey，按照 macOS 提示与您的登录账户配对。",
    ),
    "pivMacSetupError": MessageLookupByLibrary.simpleMessage(
      "检查或配置失败。请检查连接、PIV PIN 和管理密钥后重试。已完成的配置会保留。无法读取密钥信息的旧版固件不支持此功能。",
    ),
    "pivMacSetupFinished": MessageLookupByLibrary.simpleMessage("已完成"),
    "pivMacSetupInspect": MessageLookupByLibrary.simpleMessage("重新检查"),
    "pivMacSetupIntro": MessageLookupByLibrary.simpleMessage(
      "配置 macOS 登录所需的密钥和证书。将检查 9A 和 9D 槽位，并保留符合要求的现有内容。",
    ),
    "pivMacSetupInvalid": MessageLookupByLibrary.simpleMessage(
      "PIV PIN 或管理密钥的格式不正确，请检查后重试。",
    ),
    "pivMacSetupIssue": MessageLookupByLibrary.simpleMessage("保留现有密钥，生成证书"),
    "pivMacSetupKeep": MessageLookupByLibrary.simpleMessage("保留现有配置"),
    "pivMacSetupManagementKey": MessageLookupByLibrary.simpleMessage(
      "管理密钥（十六进制）",
    ),
    "pivMacSetupReplaceCert": MessageLookupByLibrary.simpleMessage(
      "保留现有密钥，替换证书",
    ),
    "pivMacSetupReplaceKey": MessageLookupByLibrary.simpleMessage("替换密钥和证书"),
    "pivMacSetupStart": MessageLookupByLibrary.simpleMessage("开始配置"),
    "pivMacSetupTitle": MessageLookupByLibrary.simpleMessage("配置 macOS 登录"),
    "pivMacSetupWorking": MessageLookupByLibrary.simpleMessage("正在配置"),
    "pivMainSlots": MessageLookupByLibrary.simpleMessage("主要槽位"),
    "pivManage": MessageLookupByLibrary.simpleMessage("管理"),
    "pivManagementKey": MessageLookupByLibrary.simpleMessage("管理密钥"),
    "pivManagementKeyAuthentication": MessageLookupByLibrary.simpleMessage(
      "管理密钥验证方式",
    ),
    "pivManagementKeyVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "管理密钥验证失败",
    ),
    "pivManualManagementKey": MessageLookupByLibrary.simpleMessage("手动输入管理密钥"),
    "pivManualManagementKeyDescription": MessageLookupByLibrary.simpleMessage(
      "为本次操作输入 24 字节管理密钥。",
    ),
    "pivMessage": MessageLookupByLibrary.simpleMessage("消息"),
    "pivMessageSigningFailed": MessageLookupByLibrary.simpleMessage("消息签名失败"),
    "pivModifyWithCaution": MessageLookupByLibrary.simpleMessage("请谨慎修改"),
    "pivMoveKey": MessageLookupByLibrary.simpleMessage("移动密钥"),
    "pivMoveKeyFailed": MessageLookupByLibrary.simpleMessage(
      "移动失败，请选择没有密钥的目标槽位。",
    ),
    "pivMoveKeyFrom": m21,
    "pivMoveKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "仅移动私钥；证书会保留在原来的槽中。",
    ),
    "pivNameColumn": MessageLookupByLibrary.simpleMessage("名称"),
    "pivNewManagementKey": MessageLookupByLibrary.simpleMessage("新管理密钥"),
    "pivNewPUK": MessageLookupByLibrary.simpleMessage("新 PUK"),
    "pivNoCertificate": MessageLookupByLibrary.simpleMessage("无证书"),
    "pivNoEmptyDestinationSlot": MessageLookupByLibrary.simpleMessage(
      "没有可接收密钥的空槽位。",
    ),
    "pivNoFileSelected": MessageLookupByLibrary.simpleMessage("未选择文件"),
    "pivNoPublicKeyAvailable": MessageLookupByLibrary.simpleMessage("没有可用的公钥"),
    "pivNotSelected": MessageLookupByLibrary.simpleMessage("未选择"),
    "pivOccupiedSlots": m22,
    "pivOldManagementKey": MessageLookupByLibrary.simpleMessage("当前管理密钥"),
    "pivOldPUK": MessageLookupByLibrary.simpleMessage("当前 PUK"),
    "pivOrganization": MessageLookupByLibrary.simpleMessage("组织"),
    "pivOrganizationalUnit": MessageLookupByLibrary.simpleMessage("组织单位"),
    "pivOrigin": MessageLookupByLibrary.simpleMessage("来源"),
    "pivOriginGenerated": MessageLookupByLibrary.simpleMessage("在 CanoKey 上生成"),
    "pivOriginImported": MessageLookupByLibrary.simpleMessage("从文件导入"),
    "pivOverwrite": MessageLookupByLibrary.simpleMessage("覆盖"),
    "pivOverwriteKey": MessageLookupByLibrary.simpleMessage("覆盖密钥"),
    "pivOverwriteKeyPrompt": m23,
    "pivPageDescription": MessageLookupByLibrary.simpleMessage(
      "管理 CanoKey 中的 PIV 密钥、证书和 PIN。",
    ),
    "pivPageTitle": MessageLookupByLibrary.simpleMessage("PIV"),
    "pivPinAndTouchPolicy": MessageLookupByLibrary.simpleMessage("PIN 和触摸策略"),
    "pivPinDescription": MessageLookupByLibrary.simpleMessage("用于用户身份验证"),
    "pivPinManagement": MessageLookupByLibrary.simpleMessage("管理 PIN"),
    "pivPinPolicy": MessageLookupByLibrary.simpleMessage("PIN 策略"),
    "pivPinPolicyAlways": MessageLookupByLibrary.simpleMessage("每次验证"),
    "pivPinPolicyChip": m24,
    "pivPinPolicyDefault": MessageLookupByLibrary.simpleMessage("默认"),
    "pivPinPolicyNever": MessageLookupByLibrary.simpleMessage("从不验证"),
    "pivPinPolicyOnce": MessageLookupByLibrary.simpleMessage("会话内验证一次"),
    "pivPinProtectedKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "使用 PIN 验证",
    ),
    "pivPinProtectedManagementKeyDescription":
        MessageLookupByLibrary.simpleMessage(
          "验证 PIN 后，即可使用保存在 CanoKey 中的管理密钥。",
        ),
    "pivPinRetries": MessageLookupByLibrary.simpleMessage("PIN 重试次数"),
    "pivPostQuantumCertificateGenerationDisabled":
        MessageLookupByLibrary.simpleMessage("此算法不支持生成 CSR、自签名证书或密钥证明。"),
    "pivPrivateKey": MessageLookupByLibrary.simpleMessage("私钥"),
    "pivProvisioning": MessageLookupByLibrary.simpleMessage("配置"),
    "pivProvisioningDescription": MessageLookupByLibrary.simpleMessage(
      "为此槽位生成或导入密钥和证书。",
    ),
    "pivPublicKey": MessageLookupByLibrary.simpleMessage("公钥"),
    "pivPukDescription": MessageLookupByLibrary.simpleMessage("用于解锁 PIN"),
    "pivPukRetries": MessageLookupByLibrary.simpleMessage("PUK 重试次数"),
    "pivRandomManagementKey": MessageLookupByLibrary.simpleMessage("随机生成"),
    "pivRetired1": MessageLookupByLibrary.simpleMessage("历史密钥 1"),
    "pivRetired2": MessageLookupByLibrary.simpleMessage("历史密钥 2"),
    "pivRetiredSlot": m25,
    "pivRetiredSlots": MessageLookupByLibrary.simpleMessage("历史密钥槽位"),
    "pivRetries": m26,
    "pivRetriesRemaining": MessageLookupByLibrary.simpleMessage("剩余尝试次数"),
    "pivRetriesUnknown": MessageLookupByLibrary.simpleMessage("剩余次数：未知"),
    "pivReview": MessageLookupByLibrary.simpleMessage("确认"),
    "pivSavePem": MessageLookupByLibrary.simpleMessage("保存 PEM"),
    "pivSelectCertificateOrKeyFirst": MessageLookupByLibrary.simpleMessage(
      "请先选择证书或私钥。",
    ),
    "pivSelectFile": MessageLookupByLibrary.simpleMessage("选择文件"),
    "pivSelectFileAndSignatureFirst": MessageLookupByLibrary.simpleMessage(
      "请先选择原文件和签名文件。",
    ),
    "pivSelectFileFirst": MessageLookupByLibrary.simpleMessage("请先选择文件。"),
    "pivSelectFileHint": MessageLookupByLibrary.simpleMessage("私钥文件不能有密码保护。"),
    "pivSelectFilePrompt": MessageLookupByLibrary.simpleMessage(
      "选择 PEM 或 DER 格式的证书或私钥文件",
    ),
    "pivSelfSign": MessageLookupByLibrary.simpleMessage("生成自签名证书"),
    "pivSelfSignCertificate": MessageLookupByLibrary.simpleMessage("生成自签名证书"),
    "pivSelfSignedCertificateWarning": MessageLookupByLibrary.simpleMessage(
      "自签名证书可能需要在使用的软件中手动设为受信任证书。请先确认该软件支持自签名证书。",
    ),
    "pivSetPinPukRetries": MessageLookupByLibrary.simpleMessage(
      "设置 PIN/PUK 重试次数",
    ),
    "pivSetPinPukRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "修改重试次数会将 PIN 重置为 123456，PUK 重置为 12345678。请先关闭“使用 PIN 保护管理密钥”。",
    ),
    "pivSetRetriesFailed": MessageLookupByLibrary.simpleMessage("设置重试次数失败"),
    "pivSetRetriesMetadataFailed": MessageLookupByLibrary.simpleMessage(
      "重试次数已修改，但部分管理信息未能保存。PIN 已重置为 123456，PUK 已重置为 12345678。请重新读取 CanoKey，检查当前状态。",
    ),
    "pivSetRetriesSuccess": MessageLookupByLibrary.simpleMessage(
      "重试次数已修改，PIN 已重置为 123456，PUK 已重置为 12345678。",
    ),
    "pivSha256Fingerprint": MessageLookupByLibrary.simpleMessage("SHA-256 指纹"),
    "pivSign": MessageLookupByLibrary.simpleMessage("签名"),
    "pivSignFile": MessageLookupByLibrary.simpleMessage("文件签名"),
    "pivSignFilePrompt": MessageLookupByLibrary.simpleMessage(
      "使用此密钥为文件签名。签名将单独保存，不会修改原文件。",
    ),
    "pivSignMessage": MessageLookupByLibrary.simpleMessage("消息签名"),
    "pivSignature": MessageLookupByLibrary.simpleMessage(
      "签名（Digital Signature）",
    ),
    "pivSignatureAlgorithm": MessageLookupByLibrary.simpleMessage("签名算法"),
    "pivSignatureFile": MessageLookupByLibrary.simpleMessage("签名文件"),
    "pivSignatureHex": MessageLookupByLibrary.simpleMessage("签名（十六进制）"),
    "pivSignatureVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "签名验证失败",
    ),
    "pivSignatureVerified": MessageLookupByLibrary.simpleMessage("签名验证通过"),
    "pivSlotAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "用于登录时的身份验证，请选择支持签名的密钥算法。",
    ),
    "pivSlotCardAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "用于验证智能卡身份，是否需要 PIN 取决于使用场景。",
    ),
    "pivSlotCertificateOnly": MessageLookupByLibrary.simpleMessage("仅证书"),
    "pivSlotCleared": MessageLookupByLibrary.simpleMessage("槽位已清空"),
    "pivSlotColumn": MessageLookupByLibrary.simpleMessage("槽位"),
    "pivSlotKeyAndCertificate": MessageLookupByLibrary.simpleMessage("密钥与证书"),
    "pivSlotKeyManagementHint": MessageLookupByLibrary.simpleMessage(
      "用于解密或密钥协商。X25519 仅支持密钥协商。",
    ),
    "pivSlotKeyOnly": MessageLookupByLibrary.simpleMessage("仅密钥"),
    "pivSlotRetiredHint": MessageLookupByLibrary.simpleMessage(
      "保存旧的解密密钥和证书，以便继续读取以前加密的数据。",
    ),
    "pivSlotSignatureHint": MessageLookupByLibrary.simpleMessage(
      "用于数字签名，默认每次签名都需要验证 PIN。",
    ),
    "pivSlots": MessageLookupByLibrary.simpleMessage("证书槽位"),
    "pivSlotsDescription": MessageLookupByLibrary.simpleMessage(
      "每个槽位用于存放一组密钥和证书。",
    ),
    "pivSlotsHint": MessageLookupByLibrary.simpleMessage("选择槽位查看或管理证书"),
    "pivSlotsTitle": MessageLookupByLibrary.simpleMessage("证书槽位"),
    "pivStatusBlocked": MessageLookupByLibrary.simpleMessage("已锁定"),
    "pivStatusConfigured": MessageLookupByLibrary.simpleMessage("已配置"),
    "pivStatusEmpty": MessageLookupByLibrary.simpleMessage("未配置"),
    "pivStatusReady": MessageLookupByLibrary.simpleMessage("正常"),
    "pivStatusUnknown": MessageLookupByLibrary.simpleMessage("未知"),
    "pivStoreManagementKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "将新管理密钥保存在卡内",
    ),
    "pivStoreManagementKeyOnCardPrompt": MessageLookupByLibrary.simpleMessage(
      "保存在 CanoKey 后，管理操作只需验证 PIN。PUK 将被锁定，无法再用于重设或解锁 PIN。",
    ),
    "pivSubjectDescription": MessageLookupByLibrary.simpleMessage(
      "填写证书持有者的名称、组织等信息。",
    ),
    "pivTouchPolicy": MessageLookupByLibrary.simpleMessage("触摸策略"),
    "pivTouchPolicyAlways": MessageLookupByLibrary.simpleMessage("每次触摸"),
    "pivTouchPolicyCached": MessageLookupByLibrary.simpleMessage(
      "触摸后 15 秒内免确认",
    ),
    "pivTouchPolicyChip": m27,
    "pivTouchPolicyDefault": MessageLookupByLibrary.simpleMessage("默认"),
    "pivTouchPolicyNever": MessageLookupByLibrary.simpleMessage("无需触摸"),
    "pivTransfer": MessageLookupByLibrary.simpleMessage("导入/导出"),
    "pivUnblockPin": MessageLookupByLibrary.simpleMessage("解锁 PIN"),
    "pivUnblockPinPrompt": MessageLookupByLibrary.simpleMessage(
      "输入当前 PUK 并设置新的 PIN。",
    ),
    "pivUnsupportedImportFile": MessageLookupByLibrary.simpleMessage(
      "不支持的文件。请使用 PEM 或 DER 格式的证书/私钥文件。",
    ),
    "pivUsageClientAuth": MessageLookupByLibrary.simpleMessage("客户端身份验证"),
    "pivUsageCodeSigning": MessageLookupByLibrary.simpleMessage("代码签名"),
    "pivUsageContentCommitment": MessageLookupByLibrary.simpleMessage("不可否认性"),
    "pivUsageDataEncipherment": MessageLookupByLibrary.simpleMessage("数据加密"),
    "pivUsageDigitalSignature": MessageLookupByLibrary.simpleMessage("数字签名"),
    "pivUsageEmailProtection": MessageLookupByLibrary.simpleMessage("电子邮件保护"),
    "pivUsageKeyAgreement": MessageLookupByLibrary.simpleMessage("密钥协商"),
    "pivUsageKeyEncipherment": MessageLookupByLibrary.simpleMessage("密钥加密"),
    "pivUsageOmitted": MessageLookupByLibrary.simpleMessage("留空表示不添加此用途限制。"),
    "pivUsageServerAuth": MessageLookupByLibrary.simpleMessage("服务器身份验证"),
    "pivUsageSmartCardLogon": MessageLookupByLibrary.simpleMessage("智能卡登录"),
    "pivUseDefaultManagementKey": MessageLookupByLibrary.simpleMessage("使用默认值"),
    "pivValidityDays": MessageLookupByLibrary.simpleMessage("有效天数"),
    "pivVerify": MessageLookupByLibrary.simpleMessage("验证"),
    "pivVerifyFile": MessageLookupByLibrary.simpleMessage("验证文件签名"),
    "pivVerifyFileSignature": MessageLookupByLibrary.simpleMessage("验证文件签名"),
    "pivVerifyFileSignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "选择原文件和对应的签名文件，使用此槽位的公钥验证签名。",
    ),
    "pivVerifyManagementKey": MessageLookupByLibrary.simpleMessage("验证管理密钥"),
    "pivVerifyPinAndManagementKey": MessageLookupByLibrary.simpleMessage(
      "输入 PIN 和管理密钥",
    ),
    "pivViewCertificate": MessageLookupByLibrary.simpleMessage("查看证书"),
    "pivX25519CannotUseCertificate": MessageLookupByLibrary.simpleMessage(
      "X25519 不能搭配证书使用。请只导入密钥。",
    ),
    "pivX25519CertificateDisabled": MessageLookupByLibrary.simpleMessage(
      "X25519 不支持 CSR 和证书。",
    ),
    "pivX25519KeyGenerated": MessageLookupByLibrary.simpleMessage(
      "X25519 密钥已生成",
    ),
    "pivX25519OnlyIn9D": MessageLookupByLibrary.simpleMessage(
      "X25519 密钥只支持导入密钥管理槽 9D。",
    ),
    "play": MessageLookupByLibrary.simpleMessage("播放"),
    "pollCanceled": MessageLookupByLibrary.simpleMessage("您没有选择任何 CanoKey"),
    "pollCanoKey": MessageLookupByLibrary.simpleMessage("请点击右上角刷新按钮读取 CanoKey"),
    "privacyConsentAfterLink": MessageLookupByLibrary.simpleMessage(
      "》后继续使用。我们将严格按照政策收集、使用和保护您的个人信息。",
    ),
    "privacyConsentBeforeLink": MessageLookupByLibrary.simpleMessage(
      "感谢您使用 CanoKey Console。请仔细阅读并同意《",
    ),
    "privacyConsentTitle": MessageLookupByLibrary.simpleMessage("隐私政策提示"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("隐私政策"),
    "readingAlertMessage": MessageLookupByLibrary.simpleMessage(
      "请保持 CanoKey 靠近手机，直到读取完成。",
    ),
    "refresh": MessageLookupByLibrary.simpleMessage("刷新"),
    "reset": MessageLookupByLibrary.simpleMessage("重置"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "savePinOnDevice": MessageLookupByLibrary.simpleMessage("在此设备上保存 PIN"),
    "search": MessageLookupByLibrary.simpleMessage("搜索"),
    "seconds": MessageLookupByLibrary.simpleMessage("秒"),
    "select": MessageLookupByLibrary.simpleMessage("选择"),
    "settings": MessageLookupByLibrary.simpleMessage("设置"),
    "settingsAppletStorageUsage": MessageLookupByLibrary.simpleMessage(
      "各应用占用空间",
    ),
    "settingsAppletSwitches": MessageLookupByLibrary.simpleMessage("应用开关"),
    "settingsChangeLanguage": MessageLookupByLibrary.simpleMessage("修改语言"),
    "settingsChipId": MessageLookupByLibrary.simpleMessage("芯片 ID"),
    "settingsClearPinCache": MessageLookupByLibrary.simpleMessage("清除已保存的 PIN"),
    "settingsClearPinCachePrompt": MessageLookupByLibrary.simpleMessage(
      "确定要清除此设备上所有已保存的 PIN 吗？",
    ),
    "settingsCoreCommit": MessageLookupByLibrary.simpleMessage("固件源码版本"),
    "settingsDescription": MessageLookupByLibrary.simpleMessage(
      "查看 CanoKey 信息，设置设备功能和应用偏好。",
    ),
    "settingsDeviceActions": MessageLookupByLibrary.simpleMessage("设备操作"),
    "settingsDeviceSettings": MessageLookupByLibrary.simpleMessage("设备设置"),
    "settingsFirmwareVersion": MessageLookupByLibrary.simpleMessage("固件版本"),
    "settingsFixNFC": MessageLookupByLibrary.simpleMessage("修复 NFC"),
    "settingsFixNFCSuccess": MessageLookupByLibrary.simpleMessage("修复 NFC 成功"),
    "settingsHotp": MessageLookupByLibrary.simpleMessage("触摸时输出 HOTP"),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("CanoKey 信息"),
    "settingsInputPin": MessageLookupByLibrary.simpleMessage("PIN 验证"),
    "settingsInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "请输入设置页面使用的管理 PIN，默认值为 123456。它与 OpenPGP、PIV 等应用的 PIN 分别设置。",
    ),
    "settingsKeyboardLayout": MessageLookupByLibrary.simpleMessage("键盘布局"),
    "settingsKeyboardLayoutCurrent": m28,
    "settingsKeyboardLayoutCustom": MessageLookupByLibrary.simpleMessage(
      "自定义布局",
    ),
    "settingsKeyboardLayoutDefault": MessageLookupByLibrary.simpleMessage(
      "默认 / US QWERTY",
    ),
    "settingsKeyboardLayoutUnknown": MessageLookupByLibrary.simpleMessage("未知"),
    "settingsKeyboardLayoutUnknownPrompt": MessageLookupByLibrary.simpleMessage(
      "当前键盘布局是自定义布局。选择内置布局后，现有布局将被替换。",
    ),
    "settingsKeyboardWithReturn": MessageLookupByLibrary.simpleMessage(
      "输出验证码后按回车",
    ),
    "settingsLanguage": MessageLookupByLibrary.simpleMessage("语言"),
    "settingsModel": MessageLookupByLibrary.simpleMessage("型号"),
    "settingsNDEF": MessageLookupByLibrary.simpleMessage("NFC 标签模式 (NDEF)"),
    "settingsNDEFReadonly": MessageLookupByLibrary.simpleMessage("NFC 标签只读"),
    "settingsOpenPgpCcId": MessageLookupByLibrary.simpleMessage(
      "OpenPGP (CCID)",
    ),
    "settingsOpenPgpNfc": MessageLookupByLibrary.simpleMessage("OpenPGP (NFC)"),
    "settingsOtherSettings": MessageLookupByLibrary.simpleMessage("其他设置"),
    "settingsPassApplet": MessageLookupByLibrary.simpleMessage("Pass"),
    "settingsPivCcId": MessageLookupByLibrary.simpleMessage("PIV (CCID)"),
    "settingsPivNfc": MessageLookupByLibrary.simpleMessage("PIV (NFC)"),
    "settingsResetAll": MessageLookupByLibrary.simpleMessage("重置 CanoKey"),
    "settingsResetAllPrompt": MessageLookupByLibrary.simpleMessage(
      "即将抹除全部数据。当您确认后，CanoKey 将会多次闪烁，请在每次看到闪烁时触摸，直到提示成功。",
    ),
    "settingsResetApplet": m29,
    "settingsResetConditionNotSatisfying": MessageLookupByLibrary.simpleMessage(
      "当前 PIN 尚未锁定，无法重置。",
    ),
    "settingsResetFailed": MessageLookupByLibrary.simpleMessage(
      "重置失败，请检查设备连接后重试。",
    ),
    "settingsResetNDEF": MessageLookupByLibrary.simpleMessage("重置 NDEF"),
    "settingsResetOATH": MessageLookupByLibrary.simpleMessage("重置 TOTP/HOTP"),
    "settingsResetOpenPGP": MessageLookupByLibrary.simpleMessage("重置 OpenPGP"),
    "settingsResetPIV": MessageLookupByLibrary.simpleMessage("重置 PIV"),
    "settingsResetPass": MessageLookupByLibrary.simpleMessage("重置 Pass"),
    "settingsResetPresenceTestFailed": MessageLookupByLibrary.simpleMessage(
      "未及时触摸 CanoKey。请重试，并在指示灯闪烁时触摸。",
    ),
    "settingsResetSuccess": MessageLookupByLibrary.simpleMessage("重置成功"),
    "settingsResetWebAuthn": MessageLookupByLibrary.simpleMessage(
      "重置 WebAuthn",
    ),
    "settingsSN": MessageLookupByLibrary.simpleMessage("序列号"),
    "settingsStartPage": MessageLookupByLibrary.simpleMessage("起始页"),
    "settingsStorageFree": MessageLookupByLibrary.simpleMessage("可用"),
    "settingsStorageUsage": MessageLookupByLibrary.simpleMessage("存储用量"),
    "settingsWebAuthnApplet": MessageLookupByLibrary.simpleMessage("WebAuthn"),
    "settingsWebAuthnSm2Support": MessageLookupByLibrary.simpleMessage(
      "WebAuthn SM2",
    ),
    "settingsWebUSB": MessageLookupByLibrary.simpleMessage("插入时显示 WebUSB 提示"),
    "sm2AlgorithmId": MessageLookupByLibrary.simpleMessage("算法 ID"),
    "sm2CurveId": MessageLookupByLibrary.simpleMessage("曲线 ID"),
    "sm2ReservedId": MessageLookupByLibrary.simpleMessage(
      "此 ID 已被其他算法或曲线使用，请换一个值。",
    ),
    "soundCredit": MessageLookupByLibrary.simpleMessage(
      "NFC 交互音效由 Summer Xu 制作。",
    ),
    "storageFull": MessageLookupByLibrary.simpleMessage("CanoKey 存储空间不足"),
    "successfullyChanged": MessageLookupByLibrary.simpleMessage("修改成功"),
    "validationAtLeastCharacters": m30,
    "validationAtMostCharacters": m31,
    "validationExactLength": m32,
    "validationHexString": MessageLookupByLibrary.simpleMessage("请输入十六进制字符串"),
    "validationNumber": MessageLookupByLibrary.simpleMessage("请输入整数。"),
    "validationNumberMax": m33,
    "validationNumberMin": m34,
    "viewUserId": MessageLookupByLibrary.simpleMessage("查看用户 ID"),
    "warning": MessageLookupByLibrary.simpleMessage("警告"),
    "webAuthnCredentials": MessageLookupByLibrary.simpleMessage("WebAuthn 凭据"),
    "webAuthnDescription": MessageLookupByLibrary.simpleMessage(
      "管理存储在 CanoKey 中的 WebAuthn 登录凭据。",
    ),
    "webAuthnMissingCredentials": MessageLookupByLibrary.simpleMessage(
      "为什么看不到我的凭据？",
    ),
    "webAuthnMissingCredentialsExplanation":
        MessageLookupByLibrary.simpleMessage(
          "这里只显示 CanoKey 能直接列出的登录凭据。有些凭据需要网站发起登录才能识别，无法在这里列出，但仍可用于登录。",
        ),
    "webAuthnSearch": MessageLookupByLibrary.simpleMessage("搜索 WebAuthn 凭据…"),
    "webPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请将您的 CanoKey 插入 USB 接口并点击刷新按钮",
    ),
    "webauthnChangePinFailed": MessageLookupByLibrary.simpleMessage(
      "无法修改 WebAuthn PIN，请重新读取 CanoKey 后重试。",
    ),
    "webauthnClientPinNotSupported": MessageLookupByLibrary.simpleMessage(
      "此 CanoKey 不支持设置 WebAuthn PIN。",
    ),
    "webauthnDelete": m35,
    "webauthnInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "请输入您的 WebAuthn PIN。",
    ),
    "webauthnInputPinTitle": MessageLookupByLibrary.simpleMessage(
      "解锁 WebAuthn",
    ),
    "webauthnPinAuthBlocked": MessageLookupByLibrary.simpleMessage(
      "WebAuthn PIN 已暂时锁定。请重新插拔 CanoKey 后重试。",
    ),
    "webauthnPinBlocked": MessageLookupByLibrary.simpleMessage(
      "WebAuthn PIN 已锁定，需要重置 WebAuthn 才能继续使用。重置会删除所有 WebAuthn 凭据。",
    ),
    "webauthnPinRequired": MessageLookupByLibrary.simpleMessage(
      "请先刷新页面并输入 WebAuthn PIN，再重试此操作。",
    ),
    "webauthnSetPinFailed": MessageLookupByLibrary.simpleMessage(
      "无法设置 WebAuthn PIN，请重新读取 CanoKey 后重试。",
    ),
    "webauthnSetPinPrompt": MessageLookupByLibrary.simpleMessage(
      "设置 WebAuthn PIN 后即可管理登录凭据。PIN 需要 4 至 63 个字符。",
    ),
    "webauthnSetPinTitle": MessageLookupByLibrary.simpleMessage(
      "设置 WebAuthn PIN",
    ),
  };
}
