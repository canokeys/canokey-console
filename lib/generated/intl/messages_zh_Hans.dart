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

  static String m1(min, max) => "新 PIN 的长度应当为 ${min} - ${max} 个字符。";

  static String m2(error) => "保存失败：${error}";

  static String m3(used, total) => "已使用 ${used} / ${total} 字节";

  static String m4(error) => "ndef 库拒绝了此记录：${error}";

  static String m5(name) => "您正在删除 ${name}，删除该项目后无法恢复！请确认相关服务的二步验证已经关闭。";

  static String m6(name) => "您要将 ${name} 设为触摸时的输出吗？请注意，该操作将会覆盖原有的触摸输出。";

  static String m7(keyType) => "修改 ${keyType} 密钥的触摸设置";

  static String m8(remaining) => "剩余次数：${remaining}";

  static String m9(seconds) => "${seconds} 秒";

  static String m10(retries) => "PIN 输入错误，剩余重试次数：${retries}";

  static String m11(algorithm) => "算法：${algorithm}";

  static String m12(slot) => "自签证书已写入 ${slot} 槽。";

  static String m13(min, max) => "新 PUK 的长度应当为 ${min} - ${max} 个字符。";

  static String m14(slot) => "清空槽 ${slot}";

  static String m15(slot) => "此操作将从您的 CanoKey 中删除 ${slot} 中的证书和密钥。请确保您有其他方式访问。";

  static String m16(algorithm) => "正在生成 ${algorithm} 密钥";

  static String m17(sourceSlot) => "移动 ${sourceSlot} 中的密钥";

  static String m18(action, slot) =>
      "${action} 将替换 ${slot} 槽中的私钥。依赖此密钥的认证或签名可能会失效。";

  static String m19(policy) => "PIN：${policy}";

  static String m20(index) => "退役密钥 ${index}";

  static String m21(remaining, total) => "剩余次数：${remaining}/${total}";

  static String m22(policy) => "触摸：${policy}";

  static String m23(layout) => "当前：${layout}";

  static String m24(applet) => "该操作将抹除 ${applet} 的全部数据！";

  static String m25(min) => "至少 ${min} 个字符";

  static String m26(max) => "最多 ${max} 个字符";

  static String m27(length) => "需要 ${length} 个字符";

  static String m28(name) => "您正在删除 ${name}，删除该项目后无法恢复！请确认您有其他方式登录该服务。";

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
    "appletDisabled": m0,
    "appletLocked": MessageLookupByLibrary.simpleMessage("该应用已被锁定"),
    "applets": MessageLookupByLibrary.simpleMessage("应用"),
    "back": MessageLookupByLibrary.simpleMessage("上一步"),
    "beforeSourceLink": MessageLookupByLibrary.simpleMessage(
      "可在 GitHub 获得源代码：",
    ),
    "browserNotSupported": MessageLookupByLibrary.simpleMessage("不支持该浏览器"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "change": MessageLookupByLibrary.simpleMessage("修改"),
    "changePin": MessageLookupByLibrary.simpleMessage("修改 PIN"),
    "changePinPrompt": m1,
    "close": MessageLookupByLibrary.simpleMessage("关闭"),
    "confirm": MessageLookupByLibrary.simpleMessage("确定"),
    "connectFirst": MessageLookupByLibrary.simpleMessage("请先连接 CanoKey"),
    "copied": MessageLookupByLibrary.simpleMessage("已复制"),
    "copy": MessageLookupByLibrary.simpleMessage("复制"),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "deleted": MessageLookupByLibrary.simpleMessage("删除成功"),
    "desktopPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请将您的 CanoKey 插入 USB 接口",
    ),
    "desktopPollError": MessageLookupByLibrary.simpleMessage(
      "寻找 USB 连接的 CanoKey 时遇到错误。请修复错误后重启此应用：",
    ),
    "disable": MessageLookupByLibrary.simpleMessage("禁用"),
    "disableSound": MessageLookupByLibrary.simpleMessage("无音效"),
    "enable": MessageLookupByLibrary.simpleMessage("启用"),
    "enabled": MessageLookupByLibrary.simpleMessage("启用"),
    "fileSaveFailed": MessageLookupByLibrary.simpleMessage("保存文件失败"),
    "fileSaveFailedWithError": m2,
    "fileSaved": MessageLookupByLibrary.simpleMessage("保存成功"),
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
      "请下拉页面或点击刷新按钮，然后用 iPhone 顶部靠近 CanoKey；也可将其插入 USB 接口",
    ),
    "ndefAbsoluteUri": MessageLookupByLibrary.simpleMessage("绝对 URI"),
    "ndefAddRecord": MessageLookupByLibrary.simpleMessage("添加记录"),
    "ndefAndroidApplication": MessageLookupByLibrary.simpleMessage("AAR"),
    "ndefAndroidPackage": MessageLookupByLibrary.simpleMessage("Android 包名"),
    "ndefBluetoothAddressType": MessageLookupByLibrary.simpleMessage("地址类型"),
    "ndefBluetoothClassic": MessageLookupByLibrary.simpleMessage("经典蓝牙"),
    "ndefBluetoothLowEnergy": MessageLookupByLibrary.simpleMessage("低功耗蓝牙"),
    "ndefBluetoothPublicAddress": MessageLookupByLibrary.simpleMessage("公共地址"),
    "ndefBluetoothRandomAddress": MessageLookupByLibrary.simpleMessage("随机地址"),
    "ndefBytesUsed": m3,
    "ndefCapacity": MessageLookupByLibrary.simpleMessage("容量"),
    "ndefCapacityExceeded": MessageLookupByLibrary.simpleMessage(
      "消息超出 NDEF 容量。",
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
      "存储的数据不是有效的 NDEF 消息。请先在设置中重置 NDEF，再进行编辑。",
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
      "请输入带协议的 URI，例如 https:// 或 mailto:。",
    ),
    "ndefInvalidUuid": MessageLookupByLibrary.simpleMessage("请输入标准格式的 UUID。"),
    "ndefLanguage": MessageLookupByLibrary.simpleMessage("语言代码"),
    "ndefMacAddress": MessageLookupByLibrary.simpleMessage("MAC 地址"),
    "ndefMime": MessageLookupByLibrary.simpleMessage("MIME"),
    "ndefMimeType": MessageLookupByLibrary.simpleMessage("MIME 类型"),
    "ndefMoveDown": MessageLookupByLibrary.simpleMessage("下移"),
    "ndefMoveUp": MessageLookupByLibrary.simpleMessage("上移"),
    "ndefNoRecords": MessageLookupByLibrary.simpleMessage("没有 NDEF 记录"),
    "ndefNoRecordsDescription": MessageLookupByLibrary.simpleMessage(
      "添加 URI 或文本记录，使其他设备可以读取该标签。",
    ),
    "ndefOptionalHex": MessageLookupByLibrary.simpleMessage("可选的十六进制字节"),
    "ndefOther": MessageLookupByLibrary.simpleMessage("其他"),
    "ndefPayload": MessageLookupByLibrary.simpleMessage("载荷"),
    "ndefPayloadConversionFailed": MessageLookupByLibrary.simpleMessage(
      "载荷无法在 UTF-8 文本与十六进制字节之间转换。",
    ),
    "ndefPayloadEncoding": MessageLookupByLibrary.simpleMessage("载荷编码"),
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
    "ndefRequiredField": MessageLookupByLibrary.simpleMessage("此项为必填项。"),
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
      "配置其他设备扫描 CanoKey 时读取到的记录。",
    ),
    "ndefText": MessageLookupByLibrary.simpleMessage("文本"),
    "ndefTextValue": MessageLookupByLibrary.simpleMessage("文本内容"),
    "ndefTnfAbsoluteUri": MessageLookupByLibrary.simpleMessage("绝对 URI"),
    "ndefTnfEmpty": MessageLookupByLibrary.simpleMessage("空记录"),
    "ndefTnfExternal": MessageLookupByLibrary.simpleMessage("NFC Forum 外部类型"),
    "ndefTnfMedia": MessageLookupByLibrary.simpleMessage("媒体类型 (MIME)"),
    "ndefTnfRequiresEmptyType": MessageLookupByLibrary.simpleMessage(
      "此 TNF 要求类型名称为空。",
    ),
    "ndefTnfUnknown": MessageLookupByLibrary.simpleMessage("未知类型"),
    "ndefTnfWellKnown": MessageLookupByLibrary.simpleMessage("NFC Forum 已知类型"),
    "ndefTypeName": MessageLookupByLibrary.simpleMessage("类型名称"),
    "ndefUnsavedChanges": MessageLookupByLibrary.simpleMessage("有尚未保存的修改"),
    "ndefUri": MessageLookupByLibrary.simpleMessage("URI"),
    "ndefUriValue": MessageLookupByLibrary.simpleMessage("URI"),
    "ndefWifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
    "ndefWifiAuthentication": MessageLookupByLibrary.simpleMessage("认证方式"),
    "ndefWifiEncryption": MessageLookupByLibrary.simpleMessage("加密方式"),
    "ndefWifiPassword": MessageLookupByLibrary.simpleMessage("网络密码"),
    "ndefWritable": MessageLookupByLibrary.simpleMessage("可写"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "CanoKey 繁忙，请重新插拔并稍后再试",
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
    "oathDelete": m5,
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
    "oathSetDefaultPrompt": m6,
    "oathSlot": MessageLookupByLibrary.simpleMessage("口令槽"),
    "oathTooLong": MessageLookupByLibrary.simpleMessage("长度超限"),
    "oathType": MessageLookupByLibrary.simpleMessage("类型"),
    "off": MessageLookupByLibrary.simpleMessage("关"),
    "oldPin": MessageLookupByLibrary.simpleMessage("当前 PIN"),
    "on": MessageLookupByLibrary.simpleMessage("开"),
    "openpgpAdminPin": MessageLookupByLibrary.simpleMessage("Admin PIN"),
    "openpgpAdminPinLength": MessageLookupByLibrary.simpleMessage(
      "Admin PIN 长度必须为 8 到 64 个字符。",
    ),
    "openpgpAuthentication": MessageLookupByLibrary.simpleMessage("认证"),
    "openpgpCacheSeconds": MessageLookupByLibrary.simpleMessage("缓存秒数"),
    "openpgpCardHolder": MessageLookupByLibrary.simpleMessage("持卡人"),
    "openpgpCardInfo": MessageLookupByLibrary.simpleMessage("卡片信息"),
    "openpgpChangeAdminPin": MessageLookupByLibrary.simpleMessage(
      "修改 Admin PIN",
    ),
    "openpgpChangeInteraction": m7,
    "openpgpChangeSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "修改签名 PIN 策略",
    ),
    "openpgpChangeTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "修改触摸缓存时间",
    ),
    "openpgpCurrentAdminPin": MessageLookupByLibrary.simpleMessage(
      "当前 Admin PIN",
    ),
    "openpgpEncryption": MessageLookupByLibrary.simpleMessage("加密"),
    "openpgpKeyEmpty": MessageLookupByLibrary.simpleMessage("空"),
    "openpgpKeyImported": MessageLookupByLibrary.simpleMessage("已导入"),
    "openpgpKeyNone": MessageLookupByLibrary.simpleMessage("[未导入]"),
    "openpgpKeys": MessageLookupByLibrary.simpleMessage("密钥信息"),
    "openpgpManufacturer": MessageLookupByLibrary.simpleMessage("制造商"),
    "openpgpNewAdminPin": MessageLookupByLibrary.simpleMessage("新 Admin PIN"),
    "openpgpPermanentTouchConfirmation": MessageLookupByLibrary.simpleMessage(
      "我确认永久启用后，此密钥的触摸策略无法再关闭。",
    ),
    "openpgpPubkeyUrl": MessageLookupByLibrary.simpleMessage("公钥 URL"),
    "openpgpResetCode": MessageLookupByLibrary.simpleMessage("Reset Code"),
    "openpgpRetries": m8,
    "openpgpRetriesUnknown": MessageLookupByLibrary.simpleMessage("剩余次数：未知"),
    "openpgpSN": MessageLookupByLibrary.simpleMessage("序列号"),
    "openpgpSetPinRetries": MessageLookupByLibrary.simpleMessage("设置 PIN 重试次数"),
    "openpgpSetPinRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作会将 User PIN 重置为 123456，Admin PIN 重置为 12345678。",
    ),
    "openpgpSetPinRetriesTitle": MessageLookupByLibrary.simpleMessage(
      "设置 PIN/Reset/Admin PIN 重试次数",
    ),
    "openpgpSetResetCode": MessageLookupByLibrary.simpleMessage(
      "设置 Reset Code",
    ),
    "openpgpSetResetCodePrompt": MessageLookupByLibrary.simpleMessage(
      "Reset Code 长度必须为 8 到 64 个字符，需要 Admin PIN 授权。",
    ),
    "openpgpSetTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "设置触摸缓存时间",
    ),
    "openpgpSetTouchCacheTimePrompt": MessageLookupByLibrary.simpleMessage(
      "设置一次触摸确认可复用多久。0 表示每次操作都需要重新触摸。需要 Admin PIN 授权。",
    ),
    "openpgpSignature": MessageLookupByLibrary.simpleMessage("签名"),
    "openpgpSignaturePin": MessageLookupByLibrary.simpleMessage("签名 PIN"),
    "openpgpSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "签名 PIN 策略",
    ),
    "openpgpTouchCacheOff": MessageLookupByLibrary.simpleMessage("0 秒（不缓存）"),
    "openpgpTouchCacheSeconds": m9,
    "openpgpTouchCached": MessageLookupByLibrary.simpleMessage("触摸缓存"),
    "openpgpTouchCachedLabel": MessageLookupByLibrary.simpleMessage("触摸：缓存"),
    "openpgpTouchNone": MessageLookupByLibrary.simpleMessage("无需触摸"),
    "openpgpTouchOffLabel": MessageLookupByLibrary.simpleMessage("触摸：关闭"),
    "openpgpTouchOnLabel": MessageLookupByLibrary.simpleMessage("触摸：开启"),
    "openpgpTouchPermanent": MessageLookupByLibrary.simpleMessage("永久开启"),
    "openpgpTouchPermanentCached": MessageLookupByLibrary.simpleMessage("永久缓存"),
    "openpgpTouchPermanentCachedLabel": MessageLookupByLibrary.simpleMessage(
      "触摸：永久缓存",
    ),
    "openpgpTouchPermanentLabel": MessageLookupByLibrary.simpleMessage(
      "触摸：永久开启",
    ),
    "openpgpTouchRequired": MessageLookupByLibrary.simpleMessage("需要触摸"),
    "openpgpUIF": MessageLookupByLibrary.simpleMessage("触摸设置"),
    "openpgpUifCacheTime": MessageLookupByLibrary.simpleMessage("触摸缓存时间"),
    "openpgpUifCacheTimeChanged": MessageLookupByLibrary.simpleMessage(
      "触摸缓存时间修改成功",
    ),
    "openpgpUifChanged": MessageLookupByLibrary.simpleMessage("触摸设置修改成功"),
    "openpgpUifOff": MessageLookupByLibrary.simpleMessage("关闭"),
    "openpgpUifOn": MessageLookupByLibrary.simpleMessage("打开"),
    "openpgpUifPermanent": MessageLookupByLibrary.simpleMessage("永久启用（无法再关闭）"),
    "openpgpUnblockUserPin": MessageLookupByLibrary.simpleMessage(
      "解锁 User PIN",
    ),
    "openpgpUseAdminPin": MessageLookupByLibrary.simpleMessage("使用 Admin PIN"),
    "openpgpUseResetCode": MessageLookupByLibrary.simpleMessage(
      "使用 Reset Code",
    ),
    "openpgpUserPin": MessageLookupByLibrary.simpleMessage("User PIN"),
    "openpgpUserPinLength": MessageLookupByLibrary.simpleMessage(
      "User PIN 长度必须为 6 到 64 个字符。",
    ),
    "openpgpVerifyEverySignature": MessageLookupByLibrary.simpleMessage(
      "每次签名都验证",
    ),
    "openpgpVerifyEverySignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "每次签名都验证 User PIN",
    ),
    "openpgpVerifyOnceAfterInsertion": MessageLookupByLibrary.simpleMessage(
      "插入后验证一次",
    ),
    "openpgpVerifyOnceAfterInsertionPrompt":
        MessageLookupByLibrary.simpleMessage("每次插入后只验证一次"),
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
    "passSlotHmacSha1": MessageLookupByLibrary.simpleMessage("HMAC-SHA1"),
    "passSlotHmacSha1Key": MessageLookupByLibrary.simpleMessage(
      "20 字节 HMAC-SHA1 密钥（十六进制）",
    ),
    "passSlotHotp": MessageLookupByLibrary.simpleMessage("HOTP"),
    "passSlotLong": MessageLookupByLibrary.simpleMessage("长按"),
    "passSlotOff": MessageLookupByLibrary.simpleMessage("关闭"),
    "passSlotShort": MessageLookupByLibrary.simpleMessage("短按"),
    "passSlotStatic": MessageLookupByLibrary.simpleMessage("静态口令"),
    "passSlotWithEnter": MessageLookupByLibrary.simpleMessage("附加回车"),
    "passStatus": MessageLookupByLibrary.simpleMessage("状态"),
    "passkey": MessageLookupByLibrary.simpleMessage("通行密钥"),
    "pinChanged": MessageLookupByLibrary.simpleMessage("PIN 修改成功"),
    "pinConfirmationMismatch": MessageLookupByLibrary.simpleMessage(
      "两次输入的 PIN 不一致",
    ),
    "pinIncorrect": MessageLookupByLibrary.simpleMessage("PIN 输入错误"),
    "pinInvalidLength": MessageLookupByLibrary.simpleMessage("长度错误"),
    "pinLength": MessageLookupByLibrary.simpleMessage("输入的 PIN 长度错误"),
    "pinRetries": m10,
    "pivAlgorithm": MessageLookupByLibrary.simpleMessage("当前密钥算法"),
    "pivAlgorithmIds": MessageLookupByLibrary.simpleMessage("算法 ID"),
    "pivAlgorithmIdsPrompt": MessageLookupByLibrary.simpleMessage(
      "控制卡片是否接受 PIV 扩展算法 ID。",
    ),
    "pivAlgorithmIdsTitle": MessageLookupByLibrary.simpleMessage("PIV 算法 ID"),
    "pivAlgorithmIdsUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "更新 PIV 算法 ID 失败",
    ),
    "pivAlgorithmIdsWarning": MessageLookupByLibrary.simpleMessage(
      "这些值会影响卡片如何识别 PIV 扩展算法。除非确认客户端和固件需要不同 ID，否则请保持默认值。错误的值可能导致已有扩展算法密钥显示为不支持，直到恢复正确 ID。",
    ),
    "pivAlgorithmValue": m11,
    "pivAttestationUnavailable": MessageLookupByLibrary.simpleMessage(
      "无法生成证明证书。设备必须已配置 F9 证明密钥和证书。",
    ),
    "pivAuthentication": MessageLookupByLibrary.simpleMessage(
      "认证（Authentication）",
    ),
    "pivCardAuthentication": MessageLookupByLibrary.simpleMessage(
      "卡认证（Card Authentication）",
    ),
    "pivCertificate": MessageLookupByLibrary.simpleMessage("证书"),
    "pivCertificateCopied": MessageLookupByLibrary.simpleMessage("证书已复制"),
    "pivCertificateCreated": MessageLookupByLibrary.simpleMessage("证书已创建"),
    "pivCertificateDoesNotMatchPrivateKey":
        MessageLookupByLibrary.simpleMessage("证书公钥与所选私钥不匹配。"),
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
    "pivCertificateSerial": MessageLookupByLibrary.simpleMessage("序列号"),
    "pivCertificateSize": MessageLookupByLibrary.simpleMessage("证书大小"),
    "pivCertificateSubject": MessageLookupByLibrary.simpleMessage("使用者"),
    "pivCertificateSubjectStep": MessageLookupByLibrary.simpleMessage("证书主题"),
    "pivCertificateValidFrom": MessageLookupByLibrary.simpleMessage("生效时间"),
    "pivCertificateValidTo": MessageLookupByLibrary.simpleMessage("失效时间"),
    "pivCertificateWritten": m12,
    "pivChangeManagementKey": MessageLookupByLibrary.simpleMessage("修改管理密钥"),
    "pivChangeManagementKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "新管理密钥的长度应当为 24 字节。请妥善保管管理密钥，否则您将无法管理 PIV 应用。",
    ),
    "pivChangePUK": MessageLookupByLibrary.simpleMessage("修改 PUK"),
    "pivChangePUKPrompt": m13,
    "pivClearSlot": MessageLookupByLibrary.simpleMessage("清空槽"),
    "pivClearSlotFailed": MessageLookupByLibrary.simpleMessage(
      "清空槽失败。请确认固件支持删除私钥。",
    ),
    "pivClearSlotPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作会删除此槽中的私钥和证书。请确认您仍有其他认证方式。",
    ),
    "pivClearSlotTitle": m14,
    "pivCommonName": MessageLookupByLibrary.simpleMessage("通用名称"),
    "pivCopyPem": MessageLookupByLibrary.simpleMessage("复制 PEM"),
    "pivCountryCode": MessageLookupByLibrary.simpleMessage("国家代码"),
    "pivCreateCertificate": MessageLookupByLibrary.simpleMessage("创建证书"),
    "pivCreateCertificateFailed": MessageLookupByLibrary.simpleMessage(
      "创建证书失败",
    ),
    "pivCreatingSelfSignedCertificate": MessageLookupByLibrary.simpleMessage(
      "创建自签证书",
    ),
    "pivCsrCopied": MessageLookupByLibrary.simpleMessage("CSR 已复制"),
    "pivCsrGenerated": MessageLookupByLibrary.simpleMessage("CSR 已生成"),
    "pivCsrGenerationPrompt": MessageLookupByLibrary.simpleMessage(
      "生成 CSR 会使用卡内新密钥对请求签名。",
    ),
    "pivCsrSubject": MessageLookupByLibrary.simpleMessage("CSR 主题"),
    "pivDangerZone": MessageLookupByLibrary.simpleMessage("危险操作"),
    "pivDelete": MessageLookupByLibrary.simpleMessage("删除"),
    "pivDeleteSlot": m15,
    "pivDestinationSlot": MessageLookupByLibrary.simpleMessage("目标槽"),
    "pivDiagnostics": MessageLookupByLibrary.simpleMessage("密钥操作"),
    "pivDisablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "改为手动管理密钥",
    ),
    "pivDisablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage("改为手动管理密钥失败"),
    "pivDisablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage("清除 PIN 保护的副本前会先设置新的管理密钥。"),
    "pivDisablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage("之后需要手动输入管理密钥"),
    "pivDnsSans": MessageLookupByLibrary.simpleMessage("DNS SAN，使用逗号分隔"),
    "pivDownloadAttestation": MessageLookupByLibrary.simpleMessage("下载证明证书"),
    "pivEmpty": MessageLookupByLibrary.simpleMessage("空"),
    "pivEnablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "使用 PIN 保护管理密钥",
    ),
    "pivEnablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage("保存 PIN 保护管理密钥失败"),
    "pivEnablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage("将设置随机管理密钥，并以 PIN 保护的形式保存在卡内。"),
    "pivEnablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage("管理密钥已由 PIN 保护"),
    "pivExport": MessageLookupByLibrary.simpleMessage("导出"),
    "pivExportCertificate": MessageLookupByLibrary.simpleMessage("导出证书"),
    "pivExportPublicKey": MessageLookupByLibrary.simpleMessage("导出公钥"),
    "pivExtendedAlgorithmCompatibilityWarning":
        MessageLookupByLibrary.simpleMessage("使用此算法前请确认客户端兼容性。"),
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
    "pivGeneratingKey": m16,
    "pivGeneratingX25519Key": MessageLookupByLibrary.simpleMessage(
      "生成 X25519 密钥",
    ),
    "pivImport": MessageLookupByLibrary.simpleMessage("导入"),
    "pivImportFailed": MessageLookupByLibrary.simpleMessage("导入失败"),
    "pivImportSucceeded": MessageLookupByLibrary.simpleMessage("导入成功"),
    "pivImportWillReplaceCertificate": MessageLookupByLibrary.simpleMessage(
      "本次导入会替换此槽中现有的证书。",
    ),
    "pivImportWillReplacePrivateKey": MessageLookupByLibrary.simpleMessage(
      "本次导入会替换此槽中现有的私钥。",
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
    "pivKeyOptions": MessageLookupByLibrary.simpleMessage("密钥选项"),
    "pivManagementKey": MessageLookupByLibrary.simpleMessage("管理密钥"),
    "pivManagementKeyAuthentication": MessageLookupByLibrary.simpleMessage(
      "管理密钥认证",
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
      "移动密钥失败。目标槽必须不包含密钥。",
    ),
    "pivMoveKeyFrom": m17,
    "pivMoveKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "仅移动私钥；证书会保留在原来的槽中。",
    ),
    "pivNewManagementKey": MessageLookupByLibrary.simpleMessage("新密钥"),
    "pivNewPUK": MessageLookupByLibrary.simpleMessage("新 PUK"),
    "pivNoCertificate": MessageLookupByLibrary.simpleMessage("无证书"),
    "pivNoEmptyDestinationSlot": MessageLookupByLibrary.simpleMessage(
      "没有可用的空目标槽。",
    ),
    "pivNoFileSelected": MessageLookupByLibrary.simpleMessage("未选择文件"),
    "pivNoPublicKeyAvailable": MessageLookupByLibrary.simpleMessage("没有可用的公钥"),
    "pivNotSelected": MessageLookupByLibrary.simpleMessage("未选择"),
    "pivOldManagementKey": MessageLookupByLibrary.simpleMessage("当前密钥"),
    "pivOldPUK": MessageLookupByLibrary.simpleMessage("当前 PUK"),
    "pivOrganization": MessageLookupByLibrary.simpleMessage("组织"),
    "pivOrganizationalUnit": MessageLookupByLibrary.simpleMessage("组织单位"),
    "pivOrigin": MessageLookupByLibrary.simpleMessage("来源"),
    "pivOriginGenerated": MessageLookupByLibrary.simpleMessage("内部生成"),
    "pivOriginImported": MessageLookupByLibrary.simpleMessage("外部导入"),
    "pivOverwrite": MessageLookupByLibrary.simpleMessage("覆盖"),
    "pivOverwriteKey": MessageLookupByLibrary.simpleMessage("覆盖密钥"),
    "pivOverwriteKeyPrompt": m18,
    "pivPinAndTouchPolicy": MessageLookupByLibrary.simpleMessage("PIN 和触摸策略"),
    "pivPinManagement": MessageLookupByLibrary.simpleMessage("管理 PIN"),
    "pivPinPolicy": MessageLookupByLibrary.simpleMessage("PIN 策略"),
    "pivPinPolicyAlways": MessageLookupByLibrary.simpleMessage("总是验证"),
    "pivPinPolicyChip": m19,
    "pivPinPolicyDefault": MessageLookupByLibrary.simpleMessage("默认"),
    "pivPinPolicyNever": MessageLookupByLibrary.simpleMessage("从不验证"),
    "pivPinPolicyOnce": MessageLookupByLibrary.simpleMessage("会话内验证一次"),
    "pivPinProtectedKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "卡内 PIN 保护密钥",
    ),
    "pivPinProtectedManagementKeyDescription":
        MessageLookupByLibrary.simpleMessage("使用 PIN 解锁保存在卡内的管理密钥。"),
    "pivPinRetries": MessageLookupByLibrary.simpleMessage("PIN 重试次数"),
    "pivPostQuantumCertificateGenerationDisabled":
        MessageLookupByLibrary.simpleMessage("此算法不支持生成 CSR、自签证书或密钥证明。"),
    "pivPrivateKey": MessageLookupByLibrary.simpleMessage("私钥"),
    "pivProvisioning": MessageLookupByLibrary.simpleMessage("配置"),
    "pivPublicKey": MessageLookupByLibrary.simpleMessage("公钥"),
    "pivPukRetries": MessageLookupByLibrary.simpleMessage("PUK 重试次数"),
    "pivRandomManagementKey": MessageLookupByLibrary.simpleMessage("随机值"),
    "pivRetired1": MessageLookupByLibrary.simpleMessage("退役密钥 1"),
    "pivRetired2": MessageLookupByLibrary.simpleMessage("退役密钥 2"),
    "pivRetiredSlot": m20,
    "pivRetries": m21,
    "pivRetriesUnknown": MessageLookupByLibrary.simpleMessage("剩余次数：未知"),
    "pivReview": MessageLookupByLibrary.simpleMessage("确认"),
    "pivSavePem": MessageLookupByLibrary.simpleMessage("保存 PEM"),
    "pivSelectCertificateOrKeyFirst": MessageLookupByLibrary.simpleMessage(
      "请先选择证书或私钥。",
    ),
    "pivSelectFile": MessageLookupByLibrary.simpleMessage("选择文件"),
    "pivSelectFileAndSignatureFirst": MessageLookupByLibrary.simpleMessage(
      "请先选择文件和签名。",
    ),
    "pivSelectFileFirst": MessageLookupByLibrary.simpleMessage("请先选择文件。"),
    "pivSelectFileHint": MessageLookupByLibrary.simpleMessage(
      "（请确认文件包含明文私钥或证书）",
    ),
    "pivSelectFilePrompt": MessageLookupByLibrary.simpleMessage(
      "点击选择 PEM 或 DER 证书/私钥",
    ),
    "pivSelfSign": MessageLookupByLibrary.simpleMessage("生成自签证书"),
    "pivSelfSignCertificate": MessageLookupByLibrary.simpleMessage("生成自签证书"),
    "pivSelfSignedCertificateWarning": MessageLookupByLibrary.simpleMessage(
      "自签证书适合本地测试，兼容性取决于客户端。",
    ),
    "pivSetPinPukRetries": MessageLookupByLibrary.simpleMessage(
      "设置 PIN/PUK 重试次数",
    ),
    "pivSetPinPukRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作会将 PIN 重置为 123456，PUK 重置为 12345678。",
    ),
    "pivSetRetriesFailed": MessageLookupByLibrary.simpleMessage("设置重试次数失败"),
    "pivSetRetriesSuccess": MessageLookupByLibrary.simpleMessage(
      "PIN/PUK 重试次数已设置，PIN 和 PUK 已重置。",
    ),
    "pivSha256Fingerprint": MessageLookupByLibrary.simpleMessage("SHA-256 指纹"),
    "pivSign": MessageLookupByLibrary.simpleMessage("签名"),
    "pivSignFile": MessageLookupByLibrary.simpleMessage("签名文件"),
    "pivSignFilePrompt": MessageLookupByLibrary.simpleMessage(
      "为所选文件生成分离式原始签名。",
    ),
    "pivSignMessage": MessageLookupByLibrary.simpleMessage("签名消息"),
    "pivSignature": MessageLookupByLibrary.simpleMessage(
      "签名（Digital Signature）",
    ),
    "pivSignatureAlgorithm": MessageLookupByLibrary.simpleMessage("签名算法"),
    "pivSignatureFile": MessageLookupByLibrary.simpleMessage("签名"),
    "pivSignatureHex": MessageLookupByLibrary.simpleMessage("签名（十六进制）"),
    "pivSignatureVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "签名验证失败",
    ),
    "pivSignatureVerified": MessageLookupByLibrary.simpleMessage("签名验证通过"),
    "pivSlotAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "认证槽。用于登录时应选择可签名密钥。",
    ),
    "pivSlotCardAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "卡认证槽。部分用途可能不需要 PIN。",
    ),
    "pivSlotCleared": MessageLookupByLibrary.simpleMessage("槽已清空"),
    "pivSlotKeyManagementHint": MessageLookupByLibrary.simpleMessage(
      "密钥管理槽。X25519 只能用于派生共享密钥。",
    ),
    "pivSlotRetiredHint": MessageLookupByLibrary.simpleMessage(
      "退役密钥管理槽，用于保存旧解密私钥及其证书。",
    ),
    "pivSlotSignatureHint": MessageLookupByLibrary.simpleMessage(
      "数字签名槽。PIN 策略默认总是验证。",
    ),
    "pivSlots": MessageLookupByLibrary.simpleMessage("证书槽"),
    "pivStoreManagementKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "将新管理密钥保存在卡内",
    ),
    "pivStoreManagementKeyOnCardPrompt": MessageLookupByLibrary.simpleMessage(
      "启用后，后续管理操作可用 PIN 完成认证。",
    ),
    "pivTouchPolicy": MessageLookupByLibrary.simpleMessage("触摸策略"),
    "pivTouchPolicyAlways": MessageLookupByLibrary.simpleMessage("总是验证"),
    "pivTouchPolicyCached": MessageLookupByLibrary.simpleMessage("缓存 15 秒"),
    "pivTouchPolicyChip": m22,
    "pivTouchPolicyDefault": MessageLookupByLibrary.simpleMessage("默认"),
    "pivTouchPolicyNever": MessageLookupByLibrary.simpleMessage("从不验证"),
    "pivUnblockPin": MessageLookupByLibrary.simpleMessage("解锁 PIN"),
    "pivUnblockPinPrompt": MessageLookupByLibrary.simpleMessage(
      "输入当前 PUK 并设置新的 PIN。",
    ),
    "pivUnsupportedImportFile": MessageLookupByLibrary.simpleMessage(
      "不支持的文件。请使用 PEM 或 DER 格式的证书/私钥文件。",
    ),
    "pivUseDefaultManagementKey": MessageLookupByLibrary.simpleMessage("默认值"),
    "pivValidityDays": MessageLookupByLibrary.simpleMessage("有效天数"),
    "pivVerify": MessageLookupByLibrary.simpleMessage("验证"),
    "pivVerifyFile": MessageLookupByLibrary.simpleMessage("验证文件"),
    "pivVerifyFileSignature": MessageLookupByLibrary.simpleMessage("验证文件签名"),
    "pivVerifyFileSignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "使用当前槽位公钥验证分离式原始签名。",
    ),
    "pivVerifyManagementKey": MessageLookupByLibrary.simpleMessage("验证管理密钥"),
    "pivVerifyPinAndManagementKey": MessageLookupByLibrary.simpleMessage(
      "验证 PIN 和管理密钥",
    ),
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
    "readingAlertMessage": MessageLookupByLibrary.simpleMessage(
      "请紧贴 CanoKey 直到读取结束",
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
      "各应用 Flash 用量",
    ),
    "settingsAppletSwitches": MessageLookupByLibrary.simpleMessage("应用开关"),
    "settingsChangeLanguage": MessageLookupByLibrary.simpleMessage("修改语言"),
    "settingsChipId": MessageLookupByLibrary.simpleMessage("芯片 ID"),
    "settingsClearPinCache": MessageLookupByLibrary.simpleMessage("清除已保存的 PIN"),
    "settingsClearPinCachePrompt": MessageLookupByLibrary.simpleMessage(
      "确定要清除此设备上所有已保存的 PIN 吗？",
    ),
    "settingsCoreCommit": MessageLookupByLibrary.simpleMessage("Core Commit"),
    "settingsFirmwareVersion": MessageLookupByLibrary.simpleMessage("固件版本"),
    "settingsFixNFC": MessageLookupByLibrary.simpleMessage("修复 NFC"),
    "settingsFixNFCSuccess": MessageLookupByLibrary.simpleMessage("修复 NFC 成功"),
    "settingsHotp": MessageLookupByLibrary.simpleMessage("触摸时输出 HOTP"),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("CanoKey 信息"),
    "settingsInputPin": MessageLookupByLibrary.simpleMessage("PIN 验证"),
    "settingsInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "请输入您的管理应用 PIN（默认值为 123456）。请注意，该 PIN 与其他应用的 PIN 无关。",
    ),
    "settingsKeyboardLayout": MessageLookupByLibrary.simpleMessage("键盘布局"),
    "settingsKeyboardLayoutCurrent": m23,
    "settingsKeyboardLayoutCustom": MessageLookupByLibrary.simpleMessage(
      "自定义布局",
    ),
    "settingsKeyboardLayoutDefault": MessageLookupByLibrary.simpleMessage(
      "默认 / US QWERTY",
    ),
    "settingsKeyboardLayoutUnknown": MessageLookupByLibrary.simpleMessage("未知"),
    "settingsKeyboardLayoutUnknownPrompt": MessageLookupByLibrary.simpleMessage(
      "当前 keymap 与内置预置不一致。应用预置会覆盖现有 keymap。",
    ),
    "settingsKeyboardWithReturn": MessageLookupByLibrary.simpleMessage(
      "OTP 输出后附加回车",
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
    "settingsResetApplet": m24,
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
    "settingsStorageFree": MessageLookupByLibrary.simpleMessage("可用"),
    "settingsStorageUsage": MessageLookupByLibrary.simpleMessage("存储用量"),
    "settingsWebAuthnApplet": MessageLookupByLibrary.simpleMessage("WebAuthn"),
    "settingsWebAuthnSm2Support": MessageLookupByLibrary.simpleMessage(
      "WebAuthn SM2",
    ),
    "settingsWebUSB": MessageLookupByLibrary.simpleMessage("插入时 WebUSB 提示"),
    "soundCredit": MessageLookupByLibrary.simpleMessage(
      "NFC 交互音效由 Summer Xu 制作。",
    ),
    "storageFull": MessageLookupByLibrary.simpleMessage("CanoKey 存储空间不足"),
    "successfullyChanged": MessageLookupByLibrary.simpleMessage("修改成功"),
    "validationAtLeastCharacters": m25,
    "validationAtMostCharacters": m26,
    "validationExactLength": m27,
    "validationHexString": MessageLookupByLibrary.simpleMessage("请输入十六进制字符串"),
    "viewUserId": MessageLookupByLibrary.simpleMessage("查看用户 ID"),
    "warning": MessageLookupByLibrary.simpleMessage("警告"),
    "webPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "请将您的 CanoKey 插入 USB 接口并点击刷新按钮",
    ),
    "webauthnClientPinNotSupported": MessageLookupByLibrary.simpleMessage(
      "该密钥不支持 WebAuthn PIN。",
    ),
    "webauthnDelete": m28,
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
