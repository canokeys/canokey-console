// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_Hant locale. All the
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
  String get localeName => 'zh_Hant';

  static String m0(applet) => "${applet} 已關閉，請先在設定中啟用。";

  static String m1(min, max) => "新 PIN 的長度應當為 ${min} - ${max} 個字元。";

  static String m2(error) => "儲存失敗：${error}";

  static String m3(used, total) => "已使用 ${used} / ${total} 位元組";

  static String m4(error) => "ndef 程式庫拒絕了此記錄：${error}";

  static String m5(name) => "您正在刪除 ${name}，刪除此項目後無法恢復！請確認相關服務的兩步驟驗證已經關閉。";

  static String m6(name) => "您要將 ${name} 設為觸碰時的輸出嗎？請注意，該操作將會覆蓋原有的觸碰輸出。";

  static String m7(keyType) => "修改 ${keyType} 金鑰的觸碰設定";

  static String m8(remaining) => "剩餘次數：${remaining}";

  static String m9(seconds) => "${seconds} 秒";

  static String m10(retries) => "PIN 輸入錯誤，剩餘重試次數：${retries}";

  static String m11(algorithm) => "演算法：${algorithm}";

  static String m12(slot) => "自我簽署憑證已寫入 ${slot} 插槽。";

  static String m13(min, max) => "新 PUK 的長度應當為 ${min} - ${max} 個字元。";

  static String m14(slot) => "清空插槽 ${slot}";

  static String m15(slot) => "此操作將從您的 CanoKey 中刪除 ${slot} 中的憑證和金鑰。請確保您有其他方式存取。";

  static String m16(algorithm) => "正在產生 ${algorithm} 金鑰";

  static String m17(sourceSlot) => "移動 ${sourceSlot} 中的金鑰";

  static String m18(action, slot) =>
      "${action} 將替換 ${slot} 插槽中的私密金鑰。依賴此金鑰的驗證或簽章可能會失效。";

  static String m19(policy) => "PIN：${policy}";

  static String m20(index) => "退役金鑰 ${index}";

  static String m21(remaining, total) => "剩餘次數：${remaining}/${total}";

  static String m22(policy) => "觸碰：${policy}";

  static String m23(layout) => "目前：${layout}";

  static String m24(applet) => "該操作將抹除 ${applet} 的全部資料！";

  static String m25(min) => "至少 ${min} 個字元";

  static String m26(max) => "最多 ${max} 個字元";

  static String m27(length) => "需要 ${length} 個字元";

  static String m28(name) => "您正在刪除 ${name}，刪除此項目後無法恢復！請確認您有其他方式登入該服務。";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("關於"),
    "actions": MessageLookupByLibrary.simpleMessage("操作"),
    "add": MessageLookupByLibrary.simpleMessage("新增"),
    "agreeAndContinue": MessageLookupByLibrary.simpleMessage("同意並繼續"),
    "androidAlertTitle": MessageLookupByLibrary.simpleMessage("讀取 CanoKey"),
    "androidPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "請用手機背面觸碰您的 CanoKey 或將其插入 USB 連接埠",
    ),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "CanoKey Console 是 CanoKey 開源安全金鑰的管理工具。",
    ),
    "appletDisabled": m0,
    "appletLocked": MessageLookupByLibrary.simpleMessage("該應用程式已被鎖定"),
    "applets": MessageLookupByLibrary.simpleMessage("應用程式"),
    "back": MessageLookupByLibrary.simpleMessage("上一步"),
    "beforeSourceLink": MessageLookupByLibrary.simpleMessage(
      "可在 GitHub 取得原始碼：",
    ),
    "browserNotSupported": MessageLookupByLibrary.simpleMessage(
      "目前環境無法使用 WebUSB",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "change": MessageLookupByLibrary.simpleMessage("修改"),
    "changePin": MessageLookupByLibrary.simpleMessage("修改 PIN"),
    "changePinPrompt": m1,
    "close": MessageLookupByLibrary.simpleMessage("關閉"),
    "confirm": MessageLookupByLibrary.simpleMessage("確定"),
    "connectFirst": MessageLookupByLibrary.simpleMessage("請先連線 CanoKey"),
    "copied": MessageLookupByLibrary.simpleMessage("已複製"),
    "copy": MessageLookupByLibrary.simpleMessage("複製"),
    "delete": MessageLookupByLibrary.simpleMessage("刪除"),
    "deleted": MessageLookupByLibrary.simpleMessage("刪除成功"),
    "desktopPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "請將您的 CanoKey 插入 USB 連接埠",
    ),
    "desktopPollError": MessageLookupByLibrary.simpleMessage(
      "尋找 USB 連線的 CanoKey 時遇到錯誤。請修復錯誤後重啟此應用程式：",
    ),
    "disable": MessageLookupByLibrary.simpleMessage("停用"),
    "disableSound": MessageLookupByLibrary.simpleMessage("無音效"),
    "disagreeAndExit": MessageLookupByLibrary.simpleMessage("不同意並結束"),
    "enable": MessageLookupByLibrary.simpleMessage("啟用"),
    "enabled": MessageLookupByLibrary.simpleMessage("啟用"),
    "feedback": MessageLookupByLibrary.simpleMessage("意見回饋"),
    "fileSaveFailed": MessageLookupByLibrary.simpleMessage("儲存檔案失敗"),
    "fileSaveFailedWithError": m2,
    "fileSaved": MessageLookupByLibrary.simpleMessage("儲存成功"),
    "home": MessageLookupByLibrary.simpleMessage("首頁"),
    "homeDirectlySelect": MessageLookupByLibrary.simpleMessage("請選擇應用程式"),
    "homePress": MessageLookupByLibrary.simpleMessage("點選"),
    "homeScreenTitle": MessageLookupByLibrary.simpleMessage("CanoKey Console"),
    "homeSelect": MessageLookupByLibrary.simpleMessage("選擇應用程式"),
    "interrupted": MessageLookupByLibrary.simpleMessage(
      "通訊中斷。嘗試緊貼 CanoKey 直到讀取結束。",
    ),
    "iosAlertMessage": MessageLookupByLibrary.simpleMessage(
      "使用 iPhone 頂部讀取 CanoKey",
    ),
    "iosPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "請下拉頁面或點選重新整理按鈕，然後用 iPhone 頂部靠近 CanoKey；也可將其插入 USB 連接埠",
    ),
    "logsCopied": MessageLookupByLibrary.simpleMessage("已複製記錄"),
    "logsCopyFailed": MessageLookupByLibrary.simpleMessage("無法複製記錄"),
    "logsEmpty": MessageLookupByLibrary.simpleMessage("本次執行尚無記錄"),
    "logsRecording": MessageLookupByLibrary.simpleMessage("啟用記錄"),
    "logsTitle": MessageLookupByLibrary.simpleMessage("檢視記錄"),
    "ndefAbsoluteUri": MessageLookupByLibrary.simpleMessage("絕對 URI"),
    "ndefAddRecord": MessageLookupByLibrary.simpleMessage("新增記錄"),
    "ndefAndroidApplication": MessageLookupByLibrary.simpleMessage("AAR"),
    "ndefAndroidPackage": MessageLookupByLibrary.simpleMessage("Android 套件名稱"),
    "ndefBluetoothAddressType": MessageLookupByLibrary.simpleMessage("位址類型"),
    "ndefBluetoothClassic": MessageLookupByLibrary.simpleMessage("經典藍牙"),
    "ndefBluetoothLowEnergy": MessageLookupByLibrary.simpleMessage("低功耗藍牙"),
    "ndefBluetoothPublicAddress": MessageLookupByLibrary.simpleMessage("公用位址"),
    "ndefBluetoothRandomAddress": MessageLookupByLibrary.simpleMessage("隨機位址"),
    "ndefBytesUsed": m3,
    "ndefCapacity": MessageLookupByLibrary.simpleMessage("容量"),
    "ndefCapacityExceeded": MessageLookupByLibrary.simpleMessage(
      "訊息超出 NDEF 容量。",
    ),
    "ndefContact": MessageLookupByLibrary.simpleMessage("聯絡人"),
    "ndefContactEmail": MessageLookupByLibrary.simpleMessage("電子郵件（可選）"),
    "ndefContactName": MessageLookupByLibrary.simpleMessage("姓名"),
    "ndefContactOrganization": MessageLookupByLibrary.simpleMessage("組織（可選）"),
    "ndefCustom": MessageLookupByLibrary.simpleMessage("自訂記錄"),
    "ndefDeviceInformation": MessageLookupByLibrary.simpleMessage("裝置資訊"),
    "ndefDeviceModel": MessageLookupByLibrary.simpleMessage("型號"),
    "ndefDeviceName": MessageLookupByLibrary.simpleMessage("裝置名稱（可選）"),
    "ndefDeviceUniqueName": MessageLookupByLibrary.simpleMessage("唯一名稱（可選）"),
    "ndefDeviceVendor": MessageLookupByLibrary.simpleMessage("廠商"),
    "ndefDeviceVersion": MessageLookupByLibrary.simpleMessage("版本（可選）"),
    "ndefEditRecord": MessageLookupByLibrary.simpleMessage("編輯記錄"),
    "ndefEncoding": MessageLookupByLibrary.simpleMessage("文字編碼"),
    "ndefExternal": MessageLookupByLibrary.simpleMessage("外部類型"),
    "ndefExternalType": MessageLookupByLibrary.simpleMessage("外部類型名稱"),
    "ndefHandover": MessageLookupByLibrary.simpleMessage("連線切換"),
    "ndefHandoverType": MessageLookupByLibrary.simpleMessage("切換記錄類型"),
    "ndefInvalidEmail": MessageLookupByLibrary.simpleMessage("請輸入有效的電子郵件位址。"),
    "ndefInvalidExternalType": MessageLookupByLibrary.simpleMessage(
      "請輸入小寫外部類型，例如 example.com:record。",
    ),
    "ndefInvalidLanguage": MessageLookupByLibrary.simpleMessage(
      "請輸入有效的語言代碼，例如 en 或 zh-Hans。",
    ),
    "ndefInvalidMacAddress": MessageLookupByLibrary.simpleMessage(
      "請輸入類似 AA:BB:CC:DD:EE:FF 的 MAC 位址。",
    ),
    "ndefInvalidMessage": MessageLookupByLibrary.simpleMessage(
      "儲存的資料不是有效的 NDEF 訊息。請先在設定中重置 NDEF，再進行編輯。",
    ),
    "ndefInvalidMimeType": MessageLookupByLibrary.simpleMessage(
      "請輸入有效的 MIME 類型，例如 text/plain。",
    ),
    "ndefInvalidPackageName": MessageLookupByLibrary.simpleMessage(
      "請輸入有效的 Android 套件名稱，例如 com.example.app。",
    ),
    "ndefInvalidPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "請輸入有效的電話號碼。",
    ),
    "ndefInvalidRecord": m4,
    "ndefInvalidUri": MessageLookupByLibrary.simpleMessage(
      "請輸入帶通訊協定的 URI，例如 https:// 或 mailto:。",
    ),
    "ndefInvalidUuid": MessageLookupByLibrary.simpleMessage("請輸入標準格式的 UUID。"),
    "ndefLanguage": MessageLookupByLibrary.simpleMessage("語言代碼"),
    "ndefMacAddress": MessageLookupByLibrary.simpleMessage("MAC 位址"),
    "ndefMime": MessageLookupByLibrary.simpleMessage("MIME"),
    "ndefMimeType": MessageLookupByLibrary.simpleMessage("MIME 類型"),
    "ndefMoveDown": MessageLookupByLibrary.simpleMessage("下移"),
    "ndefMoveUp": MessageLookupByLibrary.simpleMessage("上移"),
    "ndefNoRecords": MessageLookupByLibrary.simpleMessage("沒有 NDEF 記錄"),
    "ndefNoRecordsDescription": MessageLookupByLibrary.simpleMessage(
      "新增 URI 或文字記錄，使其他裝置可以讀取該標籤。",
    ),
    "ndefOptionalHex": MessageLookupByLibrary.simpleMessage("可選的十六進位位元組"),
    "ndefOther": MessageLookupByLibrary.simpleMessage("其他"),
    "ndefPayload": MessageLookupByLibrary.simpleMessage("承載資料"),
    "ndefPayloadConversionFailed": MessageLookupByLibrary.simpleMessage(
      "承載資料無法在 UTF-8 文字與十六進位位元組之間轉換。",
    ),
    "ndefPayloadEncoding": MessageLookupByLibrary.simpleMessage("承載資料編碼"),
    "ndefPayloadHex": MessageLookupByLibrary.simpleMessage("十六進位"),
    "ndefPayloadText": MessageLookupByLibrary.simpleMessage("文字"),
    "ndefPhone": MessageLookupByLibrary.simpleMessage("電話"),
    "ndefPhoneNumber": MessageLookupByLibrary.simpleMessage("電話號碼"),
    "ndefReadOnly": MessageLookupByLibrary.simpleMessage("NDEF 標籤目前為唯讀。"),
    "ndefReadOnlyDescription": MessageLookupByLibrary.simpleMessage(
      "目前無法寫入。請先在設定中關閉「NFC 標籤唯讀」。",
    ),
    "ndefReadOnlyStatus": MessageLookupByLibrary.simpleMessage("唯讀"),
    "ndefRecordId": MessageLookupByLibrary.simpleMessage("記錄 ID（可選，十六進位）"),
    "ndefRecordType": MessageLookupByLibrary.simpleMessage("記錄類型"),
    "ndefRecords": MessageLookupByLibrary.simpleMessage("記錄"),
    "ndefRequiredField": MessageLookupByLibrary.simpleMessage("此項為必填項。"),
    "ndefSaveToKey": MessageLookupByLibrary.simpleMessage("儲存到 CanoKey"),
    "ndefSaved": MessageLookupByLibrary.simpleMessage("NDEF 記錄已儲存"),
    "ndefSignature": MessageLookupByLibrary.simpleMessage("簽章"),
    "ndefSmartPoster": MessageLookupByLibrary.simpleMessage("智慧海報"),
    "ndefSmartPosterAction": MessageLookupByLibrary.simpleMessage("建議操作"),
    "ndefSmartPosterActionEdit": MessageLookupByLibrary.simpleMessage("編輯"),
    "ndefSmartPosterActionOpen": MessageLookupByLibrary.simpleMessage("開啟"),
    "ndefSmartPosterActionSave": MessageLookupByLibrary.simpleMessage("儲存"),
    "ndefSmartPosterTitle": MessageLookupByLibrary.simpleMessage("標題（可選）"),
    "ndefTagContent": MessageLookupByLibrary.simpleMessage("NFC 標籤內容"),
    "ndefTagContentDescription": MessageLookupByLibrary.simpleMessage(
      "設定其他裝置掃描 CanoKey 時讀取到的記錄。",
    ),
    "ndefText": MessageLookupByLibrary.simpleMessage("文字"),
    "ndefTextValue": MessageLookupByLibrary.simpleMessage("文字內容"),
    "ndefTnfAbsoluteUri": MessageLookupByLibrary.simpleMessage("絕對 URI"),
    "ndefTnfEmpty": MessageLookupByLibrary.simpleMessage("空記錄"),
    "ndefTnfExternal": MessageLookupByLibrary.simpleMessage("NFC Forum 外部類型"),
    "ndefTnfMedia": MessageLookupByLibrary.simpleMessage("媒體類型 (MIME)"),
    "ndefTnfRequiresEmptyType": MessageLookupByLibrary.simpleMessage(
      "此 TNF 要求類型名稱為空。",
    ),
    "ndefTnfUnknown": MessageLookupByLibrary.simpleMessage("未知類型"),
    "ndefTnfWellKnown": MessageLookupByLibrary.simpleMessage("NFC Forum 已知類型"),
    "ndefTypeName": MessageLookupByLibrary.simpleMessage("類型名稱"),
    "ndefUnsavedChanges": MessageLookupByLibrary.simpleMessage("有尚未儲存的修改"),
    "ndefUri": MessageLookupByLibrary.simpleMessage("URI"),
    "ndefUriValue": MessageLookupByLibrary.simpleMessage("URI"),
    "ndefWifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
    "ndefWifiAuthentication": MessageLookupByLibrary.simpleMessage("驗證方式"),
    "ndefWifiEncryption": MessageLookupByLibrary.simpleMessage("加密方式"),
    "ndefWifiPassword": MessageLookupByLibrary.simpleMessage("網路密碼"),
    "ndefWritable": MessageLookupByLibrary.simpleMessage("可寫"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "CanoKey 繁忙，請重新插拔並稍後再試",
    ),
    "newPin": MessageLookupByLibrary.simpleMessage("新 PIN"),
    "next": MessageLookupByLibrary.simpleMessage("下一步"),
    "nfcSound": MessageLookupByLibrary.simpleMessage("NFC 互動音效"),
    "nfcSoundPrompt": MessageLookupByLibrary.simpleMessage(
      "播放順序：讀卡開始、讀卡結束、讀卡失敗",
    ),
    "noCard": MessageLookupByLibrary.simpleMessage("未找到 CanoKey"),
    "noCredential": MessageLookupByLibrary.simpleMessage("沒有找到憑證"),
    "noMatchingCredential": MessageLookupByLibrary.simpleMessage("沒有找到相符的憑證"),
    "notSupported": MessageLookupByLibrary.simpleMessage("不支援該操作"),
    "notSupportedInNFC": MessageLookupByLibrary.simpleMessage(
      "該操作不支援在 NFC 模式下執行",
    ),
    "oathAccount": MessageLookupByLibrary.simpleMessage("帳戶"),
    "oathAddAccount": MessageLookupByLibrary.simpleMessage("新增帳戶"),
    "oathAddByScanning": MessageLookupByLibrary.simpleMessage("掃描 QR Code 新增"),
    "oathAddByScreen": MessageLookupByLibrary.simpleMessage("掃描螢幕上的 QR Code"),
    "oathAddManually": MessageLookupByLibrary.simpleMessage("手動新增"),
    "oathAdded": MessageLookupByLibrary.simpleMessage("新增成功"),
    "oathAdvancedSettings": MessageLookupByLibrary.simpleMessage(
      "進階設定，僅供專業使用者使用，不正確的設定可能導致憑證無法使用。",
    ),
    "oathAlgorithm": MessageLookupByLibrary.simpleMessage("演算法"),
    "oathCode": MessageLookupByLibrary.simpleMessage("密碼"),
    "oathCodeChanged": MessageLookupByLibrary.simpleMessage("密碼已修改"),
    "oathCopy": MessageLookupByLibrary.simpleMessage("複製"),
    "oathCounter": MessageLookupByLibrary.simpleMessage("計數器初始值"),
    "oathCounterMustBeNumber": MessageLookupByLibrary.simpleMessage("請填寫數字"),
    "oathDelete": m5,
    "oathDigits": MessageLookupByLibrary.simpleMessage("位數"),
    "oathDuplicated": MessageLookupByLibrary.simpleMessage("帳戶已存在"),
    "oathInputCode": MessageLookupByLibrary.simpleMessage("解鎖 CanoKey"),
    "oathInputCodePrompt": MessageLookupByLibrary.simpleMessage(
      "該 CanoKey 受密碼保護，請輸入密碼。",
    ),
    "oathInvalidKey": MessageLookupByLibrary.simpleMessage("金鑰無效"),
    "oathIssuer": MessageLookupByLibrary.simpleMessage("服務商"),
    "oathNewCode": MessageLookupByLibrary.simpleMessage("新密碼"),
    "oathNewCodePrompt": MessageLookupByLibrary.simpleMessage(
      "請輸入新密碼，如需刪除，請留空。",
    ),
    "oathNoQr": MessageLookupByLibrary.simpleMessage("未偵測到 QR Code"),
    "oathPeriod": MessageLookupByLibrary.simpleMessage("週期"),
    "oathRequireTouch": MessageLookupByLibrary.simpleMessage("需要觸碰"),
    "oathRequired": MessageLookupByLibrary.simpleMessage("不得為空"),
    "oathSecret": MessageLookupByLibrary.simpleMessage("金鑰"),
    "oathSetCode": MessageLookupByLibrary.simpleMessage("設定密碼"),
    "oathSetDefault": MessageLookupByLibrary.simpleMessage("設為觸碰輸出"),
    "oathSetDefaultPrompt": m6,
    "oathSlot": MessageLookupByLibrary.simpleMessage("密碼插槽"),
    "oathTooLong": MessageLookupByLibrary.simpleMessage("長度超限"),
    "oathType": MessageLookupByLibrary.simpleMessage("類型"),
    "off": MessageLookupByLibrary.simpleMessage("關"),
    "oldPin": MessageLookupByLibrary.simpleMessage("目前 PIN"),
    "on": MessageLookupByLibrary.simpleMessage("開"),
    "openpgpAdminPin": MessageLookupByLibrary.simpleMessage("Admin PIN"),
    "openpgpAdminPinLength": MessageLookupByLibrary.simpleMessage(
      "Admin PIN 長度必須為 8 到 64 個字元。",
    ),
    "openpgpAuthentication": MessageLookupByLibrary.simpleMessage("驗證"),
    "openpgpCacheSeconds": MessageLookupByLibrary.simpleMessage("快取秒數"),
    "openpgpCardHolder": MessageLookupByLibrary.simpleMessage("持卡人"),
    "openpgpCardInfo": MessageLookupByLibrary.simpleMessage("卡片資訊"),
    "openpgpChangeAdminPin": MessageLookupByLibrary.simpleMessage(
      "修改 Admin PIN",
    ),
    "openpgpChangeInteraction": m7,
    "openpgpChangeSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "修改簽章 PIN 策略",
    ),
    "openpgpChangeTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "修改觸碰快取時間",
    ),
    "openpgpCurrentAdminPin": MessageLookupByLibrary.simpleMessage(
      "目前 Admin PIN",
    ),
    "openpgpEncryption": MessageLookupByLibrary.simpleMessage("加密"),
    "openpgpKeyEmpty": MessageLookupByLibrary.simpleMessage("空"),
    "openpgpKeyImported": MessageLookupByLibrary.simpleMessage("已匯入"),
    "openpgpKeyNone": MessageLookupByLibrary.simpleMessage("[未匯入]"),
    "openpgpKeys": MessageLookupByLibrary.simpleMessage("金鑰資訊"),
    "openpgpManufacturer": MessageLookupByLibrary.simpleMessage("製造商"),
    "openpgpNewAdminPin": MessageLookupByLibrary.simpleMessage("新 Admin PIN"),
    "openpgpPermanentTouchConfirmation": MessageLookupByLibrary.simpleMessage(
      "我確認永久啟用後，此金鑰的觸碰策略無法再關閉。",
    ),
    "openpgpPubkeyUrl": MessageLookupByLibrary.simpleMessage("公開金鑰 URL"),
    "openpgpResetCode": MessageLookupByLibrary.simpleMessage("Reset Code"),
    "openpgpRetries": m8,
    "openpgpRetriesUnknown": MessageLookupByLibrary.simpleMessage("剩餘次數：未知"),
    "openpgpSN": MessageLookupByLibrary.simpleMessage("序號"),
    "openpgpSetPinRetries": MessageLookupByLibrary.simpleMessage("設定 PIN 重試次數"),
    "openpgpSetPinRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作會將 User PIN 重置為 123456，Admin PIN 重置為 12345678。",
    ),
    "openpgpSetPinRetriesTitle": MessageLookupByLibrary.simpleMessage(
      "設定 PIN/Reset/Admin PIN 重試次數",
    ),
    "openpgpSetResetCode": MessageLookupByLibrary.simpleMessage(
      "設定 Reset Code",
    ),
    "openpgpSetResetCodePrompt": MessageLookupByLibrary.simpleMessage(
      "Reset Code 長度必須為 8 到 64 個字元，需要 Admin PIN 授權。",
    ),
    "openpgpSetTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "設定觸碰快取時間",
    ),
    "openpgpSetTouchCacheTimePrompt": MessageLookupByLibrary.simpleMessage(
      "設定一次觸碰確認的有效時間。0 表示每次操作都需要重新觸碰。需要 Admin PIN 授權。",
    ),
    "openpgpSignature": MessageLookupByLibrary.simpleMessage("簽章"),
    "openpgpSignaturePin": MessageLookupByLibrary.simpleMessage("簽章 PIN"),
    "openpgpSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "簽章 PIN 策略",
    ),
    "openpgpTouchCacheOff": MessageLookupByLibrary.simpleMessage("0 秒（不快取）"),
    "openpgpTouchCacheSeconds": m9,
    "openpgpTouchCached": MessageLookupByLibrary.simpleMessage("觸碰快取"),
    "openpgpTouchCachedLabel": MessageLookupByLibrary.simpleMessage("觸碰：快取"),
    "openpgpTouchNone": MessageLookupByLibrary.simpleMessage("無需觸碰"),
    "openpgpTouchOffLabel": MessageLookupByLibrary.simpleMessage("觸碰：關閉"),
    "openpgpTouchOnLabel": MessageLookupByLibrary.simpleMessage("觸碰：開啟"),
    "openpgpTouchPermanent": MessageLookupByLibrary.simpleMessage("永久開啟"),
    "openpgpTouchPermanentCached": MessageLookupByLibrary.simpleMessage("永久快取"),
    "openpgpTouchPermanentCachedLabel": MessageLookupByLibrary.simpleMessage(
      "觸碰：永久快取",
    ),
    "openpgpTouchPermanentLabel": MessageLookupByLibrary.simpleMessage(
      "觸碰：永久開啟",
    ),
    "openpgpTouchRequired": MessageLookupByLibrary.simpleMessage("需要觸碰"),
    "openpgpUIF": MessageLookupByLibrary.simpleMessage("觸碰設定"),
    "openpgpUifCacheTime": MessageLookupByLibrary.simpleMessage("觸碰快取時間"),
    "openpgpUifCacheTimeChanged": MessageLookupByLibrary.simpleMessage(
      "觸碰快取時間修改成功",
    ),
    "openpgpUifChanged": MessageLookupByLibrary.simpleMessage("觸碰設定修改成功"),
    "openpgpUifOff": MessageLookupByLibrary.simpleMessage("關閉"),
    "openpgpUifOn": MessageLookupByLibrary.simpleMessage("開啟"),
    "openpgpUifPermanent": MessageLookupByLibrary.simpleMessage("永久啟用（無法再關閉）"),
    "openpgpUnblockUserPin": MessageLookupByLibrary.simpleMessage(
      "解鎖 User PIN",
    ),
    "openpgpUseAdminPin": MessageLookupByLibrary.simpleMessage("使用 Admin PIN"),
    "openpgpUseResetCode": MessageLookupByLibrary.simpleMessage(
      "使用 Reset Code",
    ),
    "openpgpUserPin": MessageLookupByLibrary.simpleMessage("User PIN"),
    "openpgpUserPinLength": MessageLookupByLibrary.simpleMessage(
      "User PIN 長度必須為 6 到 64 個字元。",
    ),
    "openpgpVerifyEverySignature": MessageLookupByLibrary.simpleMessage(
      "每次簽章都驗證",
    ),
    "openpgpVerifyEverySignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "每次簽章都驗證 User PIN",
    ),
    "openpgpVerifyOnceAfterInsertion": MessageLookupByLibrary.simpleMessage(
      "插入後驗證一次",
    ),
    "openpgpVerifyOnceAfterInsertionPrompt":
        MessageLookupByLibrary.simpleMessage("每次插入後只驗證一次"),
    "openpgpVersion": MessageLookupByLibrary.simpleMessage("版本"),
    "other": MessageLookupByLibrary.simpleMessage("其他"),
    "passInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "請輸入您的管理員（設定應用程式） PIN（預設值為 123456）。",
    ),
    "passNotSupported": MessageLookupByLibrary.simpleMessage(
      "您的 CanoKey 不支援 Pass 功能。",
    ),
    "passSlotConfigPrompt": MessageLookupByLibrary.simpleMessage(
      "請設定此密碼插槽。如需設定 HOTP，請前往 HOTP 應用程式。",
    ),
    "passSlotConfigTitle": MessageLookupByLibrary.simpleMessage("設定"),
    "passSlotHmacSha1": MessageLookupByLibrary.simpleMessage("HMAC-SHA1"),
    "passSlotHmacSha1Key": MessageLookupByLibrary.simpleMessage(
      "20 位元組 HMAC-SHA1 金鑰（十六進位）",
    ),
    "passSlotHotp": MessageLookupByLibrary.simpleMessage("HOTP"),
    "passSlotLong": MessageLookupByLibrary.simpleMessage("長按"),
    "passSlotOff": MessageLookupByLibrary.simpleMessage("關閉"),
    "passSlotShort": MessageLookupByLibrary.simpleMessage("短按"),
    "passSlotStatic": MessageLookupByLibrary.simpleMessage("靜態密碼"),
    "passSlotWithEnter": MessageLookupByLibrary.simpleMessage("附加 Enter"),
    "passStatus": MessageLookupByLibrary.simpleMessage("狀態"),
    "passkey": MessageLookupByLibrary.simpleMessage("通行密鑰"),
    "pinChanged": MessageLookupByLibrary.simpleMessage("PIN 修改成功"),
    "pinConfirmationMismatch": MessageLookupByLibrary.simpleMessage(
      "兩次輸入的 PIN 不一致",
    ),
    "pinIncorrect": MessageLookupByLibrary.simpleMessage("PIN 輸入錯誤"),
    "pinInvalidLength": MessageLookupByLibrary.simpleMessage("長度錯誤"),
    "pinLength": MessageLookupByLibrary.simpleMessage("輸入的 PIN 長度錯誤"),
    "pinRetries": m10,
    "pivAlgorithm": MessageLookupByLibrary.simpleMessage("目前金鑰演算法"),
    "pivAlgorithmIds": MessageLookupByLibrary.simpleMessage("演算法 ID"),
    "pivAlgorithmIdsPrompt": MessageLookupByLibrary.simpleMessage(
      "控制卡片是否接受 PIV 擴充演算法 ID。",
    ),
    "pivAlgorithmIdsTitle": MessageLookupByLibrary.simpleMessage("PIV 演算法 ID"),
    "pivAlgorithmIdsUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "更新 PIV 演算法 ID 失敗",
    ),
    "pivAlgorithmIdsWarning": MessageLookupByLibrary.simpleMessage(
      "這些值會影響卡片如何識別 PIV 擴充演算法。除非確認用戶端和韌體需要不同 ID，否則請保持預設值。錯誤的值可能導致已有擴充演算法金鑰顯示為不支援，直到恢復正確 ID。",
    ),
    "pivAlgorithmValue": m11,
    "pivAttestationUnavailable": MessageLookupByLibrary.simpleMessage(
      "無法產生證明憑證。裝置必須已設定 F9 證明金鑰和憑證。",
    ),
    "pivAuthentication": MessageLookupByLibrary.simpleMessage(
      "驗證（Authentication）",
    ),
    "pivCardAuthentication": MessageLookupByLibrary.simpleMessage(
      "卡驗證（Card Authentication）",
    ),
    "pivCertificate": MessageLookupByLibrary.simpleMessage("憑證"),
    "pivCertificateCopied": MessageLookupByLibrary.simpleMessage("憑證已複製"),
    "pivCertificateCreated": MessageLookupByLibrary.simpleMessage("憑證已建立"),
    "pivCertificateDoesNotMatchPrivateKey":
        MessageLookupByLibrary.simpleMessage("憑證公開金鑰與所選私密金鑰不相符。"),
    "pivCertificateIssuer": MessageLookupByLibrary.simpleMessage("簽發者"),
    "pivCertificateKey": MessageLookupByLibrary.simpleMessage("憑證公開金鑰"),
    "pivCertificateMatchesPrivateKey": MessageLookupByLibrary.simpleMessage(
      "憑證與私密金鑰相符",
    ),
    "pivCertificateMismatchPrivateKey": MessageLookupByLibrary.simpleMessage(
      "憑證與私密金鑰不相符",
    ),
    "pivCertificateOnlyKeepsPrivateKey": MessageLookupByLibrary.simpleMessage(
      "只匯入憑證不會改變私密金鑰。請確認該憑證屬於卡內已有私密金鑰。",
    ),
    "pivCertificateSerial": MessageLookupByLibrary.simpleMessage("序號"),
    "pivCertificateSize": MessageLookupByLibrary.simpleMessage("憑證大小"),
    "pivCertificateSubject": MessageLookupByLibrary.simpleMessage("使用者"),
    "pivCertificateSubjectStep": MessageLookupByLibrary.simpleMessage("憑證主題"),
    "pivCertificateValidFrom": MessageLookupByLibrary.simpleMessage("生效時間"),
    "pivCertificateValidTo": MessageLookupByLibrary.simpleMessage("失效時間"),
    "pivCertificateWritten": m12,
    "pivChangeManagementKey": MessageLookupByLibrary.simpleMessage("修改管理金鑰"),
    "pivChangeManagementKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "新管理金鑰的長度應當為 24 位元組。請妥善保管管理金鑰，否則您將無法管理 PIV 應用程式。",
    ),
    "pivChangePUK": MessageLookupByLibrary.simpleMessage("修改 PUK"),
    "pivChangePUKPrompt": m13,
    "pivClearSlot": MessageLookupByLibrary.simpleMessage("清空插槽"),
    "pivClearSlotFailed": MessageLookupByLibrary.simpleMessage(
      "清空插槽失敗。請確認韌體支援刪除私密金鑰。",
    ),
    "pivClearSlotPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作會刪除此插槽中的私密金鑰和憑證。請確認您仍有其他驗證方式。",
    ),
    "pivClearSlotTitle": m14,
    "pivCommonName": MessageLookupByLibrary.simpleMessage("通用名稱"),
    "pivCopyPem": MessageLookupByLibrary.simpleMessage("複製 PEM"),
    "pivCountryCode": MessageLookupByLibrary.simpleMessage("國家代碼"),
    "pivCreateCertificate": MessageLookupByLibrary.simpleMessage("建立憑證"),
    "pivCreateCertificateFailed": MessageLookupByLibrary.simpleMessage(
      "建立憑證失敗",
    ),
    "pivCreatingSelfSignedCertificate": MessageLookupByLibrary.simpleMessage(
      "建立自我簽署憑證",
    ),
    "pivCsrCopied": MessageLookupByLibrary.simpleMessage("CSR 已複製"),
    "pivCsrGenerated": MessageLookupByLibrary.simpleMessage("CSR 已產生"),
    "pivCsrGenerationPrompt": MessageLookupByLibrary.simpleMessage(
      "產生 CSR 會使用卡內新金鑰對請求簽章。",
    ),
    "pivCsrSubject": MessageLookupByLibrary.simpleMessage("CSR 主題"),
    "pivDangerZone": MessageLookupByLibrary.simpleMessage("危險操作"),
    "pivDelete": MessageLookupByLibrary.simpleMessage("刪除"),
    "pivDeleteSlot": m15,
    "pivDestinationSlot": MessageLookupByLibrary.simpleMessage("目標插槽"),
    "pivDiagnostics": MessageLookupByLibrary.simpleMessage("金鑰操作"),
    "pivDisablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "改為手動管理金鑰",
    ),
    "pivDisablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage("改為手動管理金鑰失敗"),
    "pivDisablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage("清除 PIN 保護的副本前會先設定新的管理金鑰。"),
    "pivDisablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage("之後需要手動輸入管理金鑰"),
    "pivDnsSans": MessageLookupByLibrary.simpleMessage("DNS SAN，使用逗號分隔"),
    "pivDownloadAttestation": MessageLookupByLibrary.simpleMessage("下載證明憑證"),
    "pivEmpty": MessageLookupByLibrary.simpleMessage("空"),
    "pivEnablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "使用 PIN 保護管理金鑰",
    ),
    "pivEnablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage("儲存 PIN 保護管理金鑰失敗"),
    "pivEnablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage("將設定隨機管理金鑰，並以 PIN 保護的形式儲存在卡內。"),
    "pivEnablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage("管理金鑰已由 PIN 保護"),
    "pivExport": MessageLookupByLibrary.simpleMessage("匯出"),
    "pivExportCertificate": MessageLookupByLibrary.simpleMessage("匯出憑證"),
    "pivExportPublicKey": MessageLookupByLibrary.simpleMessage("匯出公開金鑰"),
    "pivExtendedAlgorithmCompatibilityWarning":
        MessageLookupByLibrary.simpleMessage("使用此演算法前請確認用戶端相容性。"),
    "pivFile": MessageLookupByLibrary.simpleMessage("檔案"),
    "pivFileSigningFailed": MessageLookupByLibrary.simpleMessage("檔案簽章失敗"),
    "pivGenerate": MessageLookupByLibrary.simpleMessage("產生"),
    "pivGenerateCsr": MessageLookupByLibrary.simpleMessage("產生 CSR"),
    "pivGenerateCsrFailed": MessageLookupByLibrary.simpleMessage("產生 CSR 失敗"),
    "pivGenerateKey": MessageLookupByLibrary.simpleMessage("產生金鑰"),
    "pivGenerateKeyFailed": MessageLookupByLibrary.simpleMessage("產生金鑰失敗"),
    "pivGenerateX25519": MessageLookupByLibrary.simpleMessage("產生 X25519"),
    "pivGenerateX25519Key": MessageLookupByLibrary.simpleMessage(
      "產生 X25519 金鑰",
    ),
    "pivGenerateX25519KeyFailed": MessageLookupByLibrary.simpleMessage(
      "產生 X25519 金鑰失敗",
    ),
    "pivGeneratingCsr": MessageLookupByLibrary.simpleMessage("產生 CSR"),
    "pivGeneratingKey": m16,
    "pivGeneratingX25519Key": MessageLookupByLibrary.simpleMessage(
      "產生 X25519 金鑰",
    ),
    "pivImport": MessageLookupByLibrary.simpleMessage("匯入"),
    "pivImportFailed": MessageLookupByLibrary.simpleMessage("匯入失敗"),
    "pivImportSucceeded": MessageLookupByLibrary.simpleMessage("匯入成功"),
    "pivImportWillReplaceCertificate": MessageLookupByLibrary.simpleMessage(
      "本次匯入會替換此插槽中現有的憑證。",
    ),
    "pivImportWillReplacePrivateKey": MessageLookupByLibrary.simpleMessage(
      "本次匯入會替換此插槽中現有的私密金鑰。",
    ),
    "pivImportingPrivateKey": MessageLookupByLibrary.simpleMessage("匯入私密金鑰"),
    "pivKeyGenerated": MessageLookupByLibrary.simpleMessage("金鑰已產生"),
    "pivKeyManagement": MessageLookupByLibrary.simpleMessage(
      "金鑰管理（Key Management）",
    ),
    "pivKeyMoved": MessageLookupByLibrary.simpleMessage("金鑰已移動"),
    "pivKeyOnlyKeepsCertificate": MessageLookupByLibrary.simpleMessage(
      "只匯入私密金鑰會保留現有憑證。如憑證不再相符，請替換或清空憑證。",
    ),
    "pivKeyOptions": MessageLookupByLibrary.simpleMessage("金鑰選項"),
    "pivManagementKey": MessageLookupByLibrary.simpleMessage("管理金鑰"),
    "pivManagementKeyAuthentication": MessageLookupByLibrary.simpleMessage(
      "管理金鑰驗證",
    ),
    "pivManagementKeyVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "管理金鑰驗證失敗",
    ),
    "pivManualManagementKey": MessageLookupByLibrary.simpleMessage("手動輸入管理金鑰"),
    "pivManualManagementKeyDescription": MessageLookupByLibrary.simpleMessage(
      "為本次操作輸入 24 位元組管理金鑰。",
    ),
    "pivMessage": MessageLookupByLibrary.simpleMessage("訊息"),
    "pivMessageSigningFailed": MessageLookupByLibrary.simpleMessage("訊息簽章失敗"),
    "pivModifyWithCaution": MessageLookupByLibrary.simpleMessage("請謹慎修改"),
    "pivMoveKey": MessageLookupByLibrary.simpleMessage("移動金鑰"),
    "pivMoveKeyFailed": MessageLookupByLibrary.simpleMessage(
      "移動金鑰失敗。目標插槽必須不包含金鑰。",
    ),
    "pivMoveKeyFrom": m17,
    "pivMoveKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "僅移動私密金鑰；憑證會保留在原來的插槽中。",
    ),
    "pivNewManagementKey": MessageLookupByLibrary.simpleMessage("新金鑰"),
    "pivNewPUK": MessageLookupByLibrary.simpleMessage("新 PUK"),
    "pivNoCertificate": MessageLookupByLibrary.simpleMessage("無憑證"),
    "pivNoEmptyDestinationSlot": MessageLookupByLibrary.simpleMessage(
      "沒有可用的空目標插槽。",
    ),
    "pivNoFileSelected": MessageLookupByLibrary.simpleMessage("未選擇檔案"),
    "pivNoPublicKeyAvailable": MessageLookupByLibrary.simpleMessage(
      "沒有可用的公開金鑰",
    ),
    "pivNotSelected": MessageLookupByLibrary.simpleMessage("未選擇"),
    "pivOldManagementKey": MessageLookupByLibrary.simpleMessage("目前金鑰"),
    "pivOldPUK": MessageLookupByLibrary.simpleMessage("目前 PUK"),
    "pivOrganization": MessageLookupByLibrary.simpleMessage("組織"),
    "pivOrganizationalUnit": MessageLookupByLibrary.simpleMessage("組織單位"),
    "pivOrigin": MessageLookupByLibrary.simpleMessage("來源"),
    "pivOriginGenerated": MessageLookupByLibrary.simpleMessage("內部產生"),
    "pivOriginImported": MessageLookupByLibrary.simpleMessage("外部匯入"),
    "pivOverwrite": MessageLookupByLibrary.simpleMessage("覆蓋"),
    "pivOverwriteKey": MessageLookupByLibrary.simpleMessage("覆蓋金鑰"),
    "pivOverwriteKeyPrompt": m18,
    "pivPinAndTouchPolicy": MessageLookupByLibrary.simpleMessage("PIN 和觸碰策略"),
    "pivPinManagement": MessageLookupByLibrary.simpleMessage("管理 PIN"),
    "pivPinPolicy": MessageLookupByLibrary.simpleMessage("PIN 策略"),
    "pivPinPolicyAlways": MessageLookupByLibrary.simpleMessage("總是驗證"),
    "pivPinPolicyChip": m19,
    "pivPinPolicyDefault": MessageLookupByLibrary.simpleMessage("預設"),
    "pivPinPolicyNever": MessageLookupByLibrary.simpleMessage("從不驗證"),
    "pivPinPolicyOnce": MessageLookupByLibrary.simpleMessage("工作階段內驗證一次"),
    "pivPinProtectedKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "卡內 PIN 保護金鑰",
    ),
    "pivPinProtectedManagementKeyDescription":
        MessageLookupByLibrary.simpleMessage("使用 PIN 解鎖儲存在卡內的管理金鑰。"),
    "pivPinRetries": MessageLookupByLibrary.simpleMessage("PIN 重試次數"),
    "pivPostQuantumCertificateGenerationDisabled":
        MessageLookupByLibrary.simpleMessage("此演算法不支援產生 CSR、自我簽署憑證或金鑰證明。"),
    "pivPrivateKey": MessageLookupByLibrary.simpleMessage("私密金鑰"),
    "pivProvisioning": MessageLookupByLibrary.simpleMessage("設定"),
    "pivPublicKey": MessageLookupByLibrary.simpleMessage("公開金鑰"),
    "pivPukRetries": MessageLookupByLibrary.simpleMessage("PUK 重試次數"),
    "pivRandomManagementKey": MessageLookupByLibrary.simpleMessage("隨機值"),
    "pivRetired1": MessageLookupByLibrary.simpleMessage("退役金鑰 1"),
    "pivRetired2": MessageLookupByLibrary.simpleMessage("退役金鑰 2"),
    "pivRetiredSlot": m20,
    "pivRetries": m21,
    "pivRetriesUnknown": MessageLookupByLibrary.simpleMessage("剩餘次數：未知"),
    "pivReview": MessageLookupByLibrary.simpleMessage("確認"),
    "pivSavePem": MessageLookupByLibrary.simpleMessage("儲存 PEM"),
    "pivSelectCertificateOrKeyFirst": MessageLookupByLibrary.simpleMessage(
      "請先選擇憑證或私密金鑰。",
    ),
    "pivSelectFile": MessageLookupByLibrary.simpleMessage("選擇檔案"),
    "pivSelectFileAndSignatureFirst": MessageLookupByLibrary.simpleMessage(
      "請先選擇檔案和簽章。",
    ),
    "pivSelectFileFirst": MessageLookupByLibrary.simpleMessage("請先選擇檔案。"),
    "pivSelectFileHint": MessageLookupByLibrary.simpleMessage(
      "（請確認檔案包含明文私密金鑰或憑證）",
    ),
    "pivSelectFilePrompt": MessageLookupByLibrary.simpleMessage(
      "點選選擇 PEM 或 DER 憑證/私密金鑰",
    ),
    "pivSelfSign": MessageLookupByLibrary.simpleMessage("產生自我簽署憑證"),
    "pivSelfSignCertificate": MessageLookupByLibrary.simpleMessage("產生自我簽署憑證"),
    "pivSelfSignedCertificateWarning": MessageLookupByLibrary.simpleMessage(
      "自我簽署憑證適合本地測試，相容性取決於用戶端。",
    ),
    "pivSetPinPukRetries": MessageLookupByLibrary.simpleMessage(
      "設定 PIN/PUK 重試次數",
    ),
    "pivSetPinPukRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作會將 PIN 重置為 123456，PUK 重置為 12345678。",
    ),
    "pivSetRetriesFailed": MessageLookupByLibrary.simpleMessage("設定重試次數失敗"),
    "pivSetRetriesSuccess": MessageLookupByLibrary.simpleMessage(
      "PIN/PUK 重試次數已設定，PIN 和 PUK 已重置。",
    ),
    "pivSha256Fingerprint": MessageLookupByLibrary.simpleMessage("SHA-256 指紋"),
    "pivSign": MessageLookupByLibrary.simpleMessage("簽章"),
    "pivSignFile": MessageLookupByLibrary.simpleMessage("簽章檔案"),
    "pivSignFilePrompt": MessageLookupByLibrary.simpleMessage(
      "為所選檔案產生分離式原始簽章。",
    ),
    "pivSignMessage": MessageLookupByLibrary.simpleMessage("簽章訊息"),
    "pivSignature": MessageLookupByLibrary.simpleMessage(
      "簽章（Digital Signature）",
    ),
    "pivSignatureAlgorithm": MessageLookupByLibrary.simpleMessage("簽章演算法"),
    "pivSignatureFile": MessageLookupByLibrary.simpleMessage("簽章"),
    "pivSignatureHex": MessageLookupByLibrary.simpleMessage("簽章（十六進位）"),
    "pivSignatureVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "簽章驗證失敗",
    ),
    "pivSignatureVerified": MessageLookupByLibrary.simpleMessage("簽章驗證通過"),
    "pivSlotAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "驗證插槽。用於登入時應選擇可簽章金鑰。",
    ),
    "pivSlotCardAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "卡驗證插槽。部分用途可能不需要 PIN。",
    ),
    "pivSlotCleared": MessageLookupByLibrary.simpleMessage("插槽已清空"),
    "pivSlotKeyManagementHint": MessageLookupByLibrary.simpleMessage(
      "金鑰管理插槽。X25519 只能用於衍生共用金鑰。",
    ),
    "pivSlotRetiredHint": MessageLookupByLibrary.simpleMessage(
      "退役金鑰管理插槽，用於儲存舊解密私密金鑰及其憑證。",
    ),
    "pivSlotSignatureHint": MessageLookupByLibrary.simpleMessage(
      "數位簽章插槽。PIN 策略預設總是驗證。",
    ),
    "pivSlots": MessageLookupByLibrary.simpleMessage("憑證插槽"),
    "pivStoreManagementKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "將新管理金鑰儲存在卡內",
    ),
    "pivStoreManagementKeyOnCardPrompt": MessageLookupByLibrary.simpleMessage(
      "啟用後，後續管理操作可用 PIN 完成驗證。",
    ),
    "pivTouchPolicy": MessageLookupByLibrary.simpleMessage("觸碰策略"),
    "pivTouchPolicyAlways": MessageLookupByLibrary.simpleMessage("總是驗證"),
    "pivTouchPolicyCached": MessageLookupByLibrary.simpleMessage("快取 15 秒"),
    "pivTouchPolicyChip": m22,
    "pivTouchPolicyDefault": MessageLookupByLibrary.simpleMessage("預設"),
    "pivTouchPolicyNever": MessageLookupByLibrary.simpleMessage("從不驗證"),
    "pivUnblockPin": MessageLookupByLibrary.simpleMessage("解鎖 PIN"),
    "pivUnblockPinPrompt": MessageLookupByLibrary.simpleMessage(
      "輸入目前 PUK 並設定新的 PIN。",
    ),
    "pivUnsupportedImportFile": MessageLookupByLibrary.simpleMessage(
      "不支援的檔案。請使用 PEM 或 DER 格式的憑證/私密金鑰檔案。",
    ),
    "pivUseDefaultManagementKey": MessageLookupByLibrary.simpleMessage("預設值"),
    "pivValidityDays": MessageLookupByLibrary.simpleMessage("有效天數"),
    "pivVerify": MessageLookupByLibrary.simpleMessage("驗證"),
    "pivVerifyFile": MessageLookupByLibrary.simpleMessage("驗證檔案"),
    "pivVerifyFileSignature": MessageLookupByLibrary.simpleMessage("驗證檔案簽章"),
    "pivVerifyFileSignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "使用目前插槽公開金鑰驗證分離式原始簽章。",
    ),
    "pivVerifyManagementKey": MessageLookupByLibrary.simpleMessage("驗證管理金鑰"),
    "pivVerifyPinAndManagementKey": MessageLookupByLibrary.simpleMessage(
      "驗證 PIN 和管理金鑰",
    ),
    "pivX25519CannotUseCertificate": MessageLookupByLibrary.simpleMessage(
      "X25519 不能搭配憑證使用。請只匯入金鑰。",
    ),
    "pivX25519CertificateDisabled": MessageLookupByLibrary.simpleMessage(
      "X25519 不支援 CSR 和憑證。",
    ),
    "pivX25519KeyGenerated": MessageLookupByLibrary.simpleMessage(
      "X25519 金鑰已產生",
    ),
    "pivX25519OnlyIn9D": MessageLookupByLibrary.simpleMessage(
      "X25519 金鑰只支援匯入金鑰管理插槽 9D。",
    ),
    "play": MessageLookupByLibrary.simpleMessage("播放"),
    "pollCanceled": MessageLookupByLibrary.simpleMessage("您沒有選擇任何 CanoKey"),
    "pollCanoKey": MessageLookupByLibrary.simpleMessage(
      "請點選右上角重新整理按鈕讀取 CanoKey",
    ),
    "privacyConsentAfterLink": MessageLookupByLibrary.simpleMessage(
      "》後繼續使用。我們將嚴格按照政策收集、使用和保護您的個人資訊。",
    ),
    "privacyConsentBeforeLink": MessageLookupByLibrary.simpleMessage(
      "感謝您使用 CanoKey Console。請仔細閱讀並同意《",
    ),
    "privacyConsentTitle": MessageLookupByLibrary.simpleMessage("隱私權政策提示"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("隱私權政策"),
    "readingAlertMessage": MessageLookupByLibrary.simpleMessage(
      "請緊貼 CanoKey 直到讀取結束",
    ),
    "refresh": MessageLookupByLibrary.simpleMessage("重新整理"),
    "reset": MessageLookupByLibrary.simpleMessage("重置"),
    "save": MessageLookupByLibrary.simpleMessage("儲存"),
    "savePinOnDevice": MessageLookupByLibrary.simpleMessage("在此裝置上儲存 PIN"),
    "search": MessageLookupByLibrary.simpleMessage("搜尋"),
    "seconds": MessageLookupByLibrary.simpleMessage("秒"),
    "select": MessageLookupByLibrary.simpleMessage("選擇"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "settingsAppletStorageUsage": MessageLookupByLibrary.simpleMessage(
      "各應用程式 Flash 用量",
    ),
    "settingsAppletSwitches": MessageLookupByLibrary.simpleMessage("應用程式開關"),
    "settingsChangeLanguage": MessageLookupByLibrary.simpleMessage("修改語言"),
    "settingsChipId": MessageLookupByLibrary.simpleMessage("晶片 ID"),
    "settingsClearPinCache": MessageLookupByLibrary.simpleMessage("清除已儲存的 PIN"),
    "settingsClearPinCachePrompt": MessageLookupByLibrary.simpleMessage(
      "確定要清除此裝置上所有已儲存的 PIN 嗎？",
    ),
    "settingsCoreCommit": MessageLookupByLibrary.simpleMessage("Core Commit"),
    "settingsFirmwareVersion": MessageLookupByLibrary.simpleMessage("韌體版本"),
    "settingsFixNFC": MessageLookupByLibrary.simpleMessage("修復 NFC"),
    "settingsFixNFCSuccess": MessageLookupByLibrary.simpleMessage("修復 NFC 成功"),
    "settingsHotp": MessageLookupByLibrary.simpleMessage("觸碰時輸出 HOTP"),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("CanoKey 資訊"),
    "settingsInputPin": MessageLookupByLibrary.simpleMessage("PIN 驗證"),
    "settingsInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "請輸入您的管理應用程式 PIN（預設值為 123456）。請注意，該 PIN 與其他應用程式的 PIN 無關。",
    ),
    "settingsKeyboardLayout": MessageLookupByLibrary.simpleMessage("鍵盤配置"),
    "settingsKeyboardLayoutCurrent": m23,
    "settingsKeyboardLayoutCustom": MessageLookupByLibrary.simpleMessage(
      "自訂配置",
    ),
    "settingsKeyboardLayoutDefault": MessageLookupByLibrary.simpleMessage(
      "預設 / US QWERTY",
    ),
    "settingsKeyboardLayoutUnknown": MessageLookupByLibrary.simpleMessage("未知"),
    "settingsKeyboardLayoutUnknownPrompt": MessageLookupByLibrary.simpleMessage(
      "目前 keymap 與內建預設組態不一致。套用預設組態會覆蓋現有 keymap。",
    ),
    "settingsKeyboardWithReturn": MessageLookupByLibrary.simpleMessage(
      "OTP 輸出後附加 Enter",
    ),
    "settingsLanguage": MessageLookupByLibrary.simpleMessage("語言"),
    "settingsModel": MessageLookupByLibrary.simpleMessage("型號"),
    "settingsNDEF": MessageLookupByLibrary.simpleMessage("NFC 標籤模式 (NDEF)"),
    "settingsNDEFReadonly": MessageLookupByLibrary.simpleMessage("NFC 標籤唯讀"),
    "settingsOpenPgpCcId": MessageLookupByLibrary.simpleMessage(
      "OpenPGP (CCID)",
    ),
    "settingsOpenPgpNfc": MessageLookupByLibrary.simpleMessage("OpenPGP (NFC)"),
    "settingsOtherSettings": MessageLookupByLibrary.simpleMessage("其他設定"),
    "settingsPassApplet": MessageLookupByLibrary.simpleMessage("Pass"),
    "settingsPivCcId": MessageLookupByLibrary.simpleMessage("PIV (CCID)"),
    "settingsPivNfc": MessageLookupByLibrary.simpleMessage("PIV (NFC)"),
    "settingsResetAll": MessageLookupByLibrary.simpleMessage("重置 CanoKey"),
    "settingsResetAllPrompt": MessageLookupByLibrary.simpleMessage(
      "即將抹除全部資料。當您確認後，CanoKey 將會多次閃爍，請在每次看到閃爍時觸碰，直到提示成功。",
    ),
    "settingsResetApplet": m24,
    "settingsResetConditionNotSatisfying": MessageLookupByLibrary.simpleMessage(
      "PIN 尚未鎖定",
    ),
    "settingsResetNDEF": MessageLookupByLibrary.simpleMessage("重置 NDEF"),
    "settingsResetOATH": MessageLookupByLibrary.simpleMessage("重置 TOTP/HOTP"),
    "settingsResetOpenPGP": MessageLookupByLibrary.simpleMessage("重置 OpenPGP"),
    "settingsResetPIV": MessageLookupByLibrary.simpleMessage("重置 PIV"),
    "settingsResetPass": MessageLookupByLibrary.simpleMessage("重置 Pass"),
    "settingsResetPresenceTestFailed": MessageLookupByLibrary.simpleMessage(
      "請按提示觸碰",
    ),
    "settingsResetSuccess": MessageLookupByLibrary.simpleMessage("重置成功"),
    "settingsResetWebAuthn": MessageLookupByLibrary.simpleMessage(
      "重置 WebAuthn",
    ),
    "settingsSN": MessageLookupByLibrary.simpleMessage("序號"),
    "settingsStartPage": MessageLookupByLibrary.simpleMessage("起始頁"),
    "settingsStorageFree": MessageLookupByLibrary.simpleMessage("可用"),
    "settingsStorageUsage": MessageLookupByLibrary.simpleMessage("儲存用量"),
    "settingsWebAuthnApplet": MessageLookupByLibrary.simpleMessage("WebAuthn"),
    "settingsWebAuthnSm2Support": MessageLookupByLibrary.simpleMessage(
      "WebAuthn SM2",
    ),
    "settingsWebUSB": MessageLookupByLibrary.simpleMessage("插入時 WebUSB 提示"),
    "soundCredit": MessageLookupByLibrary.simpleMessage(
      "NFC 互動音效由 Summer Xu 製作。",
    ),
    "storageFull": MessageLookupByLibrary.simpleMessage("CanoKey 儲存空間不足"),
    "successfullyChanged": MessageLookupByLibrary.simpleMessage("修改成功"),
    "validationAtLeastCharacters": m25,
    "validationAtMostCharacters": m26,
    "validationExactLength": m27,
    "validationHexString": MessageLookupByLibrary.simpleMessage("請輸入十六進位字串"),
    "viewUserId": MessageLookupByLibrary.simpleMessage("檢視使用者 ID"),
    "warning": MessageLookupByLibrary.simpleMessage("警告"),
    "webPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "請將您的 CanoKey 插入 USB 連接埠並點選重新整理按鈕",
    ),
    "webauthnClientPinNotSupported": MessageLookupByLibrary.simpleMessage(
      "該金鑰不支援 WebAuthn PIN。",
    ),
    "webauthnDelete": m28,
    "webauthnInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "請輸入您的 WebAuthn PIN。",
    ),
    "webauthnInputPinTitle": MessageLookupByLibrary.simpleMessage(
      "解鎖 WebAuthn",
    ),
    "webauthnPinAuthBlocked": MessageLookupByLibrary.simpleMessage(
      "PIN 被鎖定，請重新插拔 CanoKey。",
    ),
    "webauthnPinBlocked": MessageLookupByLibrary.simpleMessage(
      "PIN 被鎖定，請重置 WebAuthn。",
    ),
    "webauthnSetPinPrompt": MessageLookupByLibrary.simpleMessage(
      "請設定 PIN 以啟用憑證管理。PIN 的長度應當為 4 - 63 個字元。",
    ),
    "webauthnSetPinTitle": MessageLookupByLibrary.simpleMessage(
      "設定 WebAuthn PIN",
    ),
  };
}
