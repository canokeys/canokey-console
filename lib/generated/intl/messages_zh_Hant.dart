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

  static String m1(min, max) => "新 PIN 需要 ${min} 至 ${max} 個字元。";

  static String m2(error) => "儲存失敗：${error}";

  static String m3(used, total) => "已使用 ${used} / ${total} 位元組";

  static String m4(error) => "無法儲存這筆記錄，請檢查填寫的內容。詳情：${error}";

  static String m5(protocol) => "${protocol} 企業版";

  static String m6(protocol) => "${protocol} 個人版";

  static String m7(name) =>
      "刪除 ${name} 後，CanoKey 將無法再為此帳戶產生驗證碼，且無法復原。請先確認您有其他驗證方式，或已在該服務中關閉兩步驟驗證。";

  static String m8(name) => "觸碰 CanoKey 時改為輸出 ${name} 的驗證碼？這會替換原來的觸碰輸出設定。";

  static String m9(keyType) => "修改 ${keyType} 金鑰的觸碰設定";

  static String m10(remaining) => "剩餘次數：${remaining}";

  static String m11(seconds) => "${seconds} 秒";

  static String m12(retries) => "PIN 輸入錯誤，剩餘重試次數：${retries}";

  static String m13(algorithm) => "演算法：${algorithm}";

  static String m14(slot) => "自我簽署憑證已寫入 ${slot} 槽位。";

  static String m15(min, max) => "新 PUK 需要 ${min} 至 ${max} 個字元。";

  static String m16(slot) => "清空槽位 ${slot}";

  static String m17(slot) => "刪除 ${slot} 槽位中的金鑰和憑證？此操作無法復原，請先確認您有其他登入或解密方式。";

  static String m18(algorithm) => "正在產生 ${algorithm} 金鑰";

  static String m19(slot) => "已為 ${slot} 槽位套用建議設定";

  static String m20(sourceSlot) => "移動 ${sourceSlot} 中的金鑰";

  static String m21(count) => "${count} 個已佔用";

  static String m22(action, slot) =>
      "${action} 將替換 ${slot} 槽位中的私密金鑰。依賴此金鑰的驗證或簽章可能會失效。";

  static String m23(policy) => "PIN：${policy}";

  static String m24(index) => "歷史金鑰 ${index}";

  static String m25(remaining, total) => "剩餘次數：${remaining}/${total}";

  static String m26(policy) => "觸碰：${policy}";

  static String m27(layout) => "目前：${layout}";

  static String m28(applet) => "重置後，${applet} 中的所有資料都將被刪除，無法復原。";

  static String m29(min) => "至少 ${min} 個字元";

  static String m30(max) => "最多 ${max} 個字元";

  static String m31(length) => "需要 ${length} 個字元";

  static String m32(max) => "請輸入不大於 ${max} 的整數。";

  static String m33(min) => "請輸入不小於 ${min} 的整數。";

  static String m34(name) => "刪除 ${name} 的登入憑證？此操作無法復原，請先確認您有其他方式登入該服務。";

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
    "confirmNewPin": MessageLookupByLibrary.simpleMessage("再次輸入新 PIN"),
    "connectFirst": MessageLookupByLibrary.simpleMessage("請先連線 CanoKey"),
    "copied": MessageLookupByLibrary.simpleMessage("已複製"),
    "copy": MessageLookupByLibrary.simpleMessage("複製"),
    "delete": MessageLookupByLibrary.simpleMessage("刪除"),
    "deleted": MessageLookupByLibrary.simpleMessage("刪除成功"),
    "desktopPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "請將您的 CanoKey 插入 USB 連接埠",
    ),
    "desktopPollError": MessageLookupByLibrary.simpleMessage(
      "無法透過 USB 連接 CanoKey。請檢查裝置連線，然後重新開啟此應用程式。錯誤詳情：",
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
      "連線已中斷。請重新連接；使用 NFC 時，請讓 CanoKey 保持靠近手機。",
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
    "ndefAndroidApplication": MessageLookupByLibrary.simpleMessage(
      "Android 應用程式",
    ),
    "ndefAndroidPackage": MessageLookupByLibrary.simpleMessage("Android 套件名稱"),
    "ndefBluetoothAddressType": MessageLookupByLibrary.simpleMessage("位址類型"),
    "ndefBluetoothClassic": MessageLookupByLibrary.simpleMessage("經典藍牙"),
    "ndefBluetoothLowEnergy": MessageLookupByLibrary.simpleMessage("低功耗藍牙"),
    "ndefBluetoothPublicAddress": MessageLookupByLibrary.simpleMessage("公用位址"),
    "ndefBluetoothRandomAddress": MessageLookupByLibrary.simpleMessage("隨機位址"),
    "ndefBytesUsed": m3,
    "ndefCapacity": MessageLookupByLibrary.simpleMessage("容量"),
    "ndefCapacityExceeded": MessageLookupByLibrary.simpleMessage(
      "內容超出 NFC 標籤的容量，請減少內容後再試一次。",
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
      "無法讀取現有的 NFC 標籤內容。如需重新設定，請在設定中重置 NFC Tag；這會刪除原有的標籤內容。",
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
      "請輸入完整的連結，例如 https://example.com 或 mailto:name@example.com。",
    ),
    "ndefInvalidUuid": MessageLookupByLibrary.simpleMessage("請輸入標準格式的 UUID。"),
    "ndefLanguage": MessageLookupByLibrary.simpleMessage("語言代碼"),
    "ndefMacAddress": MessageLookupByLibrary.simpleMessage("MAC 位址"),
    "ndefMime": MessageLookupByLibrary.simpleMessage("MIME"),
    "ndefMimeType": MessageLookupByLibrary.simpleMessage("MIME 類型"),
    "ndefMoveDown": MessageLookupByLibrary.simpleMessage("下移"),
    "ndefMoveUp": MessageLookupByLibrary.simpleMessage("上移"),
    "ndefNoRecords": MessageLookupByLibrary.simpleMessage("尚無記錄"),
    "ndefNoRecordsDescription": MessageLookupByLibrary.simpleMessage(
      "新增連結、文字或其他內容，供其他裝置透過 NFC 讀取。",
    ),
    "ndefOptionalHex": MessageLookupByLibrary.simpleMessage("十六進位內容，可留空"),
    "ndefOther": MessageLookupByLibrary.simpleMessage("其他"),
    "ndefPayload": MessageLookupByLibrary.simpleMessage("記錄內容"),
    "ndefPayloadConversionFailed": MessageLookupByLibrary.simpleMessage(
      "無法轉換內容編碼。請檢查十六進位格式，或確認內容是有效的 UTF-8 文字。",
    ),
    "ndefPayloadEncoding": MessageLookupByLibrary.simpleMessage("內容編碼"),
    "ndefPayloadHex": MessageLookupByLibrary.simpleMessage("十六進位"),
    "ndefPayloadText": MessageLookupByLibrary.simpleMessage("文字"),
    "ndefPhone": MessageLookupByLibrary.simpleMessage("電話"),
    "ndefPhoneNumber": MessageLookupByLibrary.simpleMessage("電話號碼"),
    "ndefReadOnly": MessageLookupByLibrary.simpleMessage("NFC 標籤目前為唯讀。"),
    "ndefReadOnlyDescription": MessageLookupByLibrary.simpleMessage(
      "目前無法寫入。請先在設定中關閉「NFC 標籤唯讀」。",
    ),
    "ndefReadOnlyStatus": MessageLookupByLibrary.simpleMessage("唯讀"),
    "ndefRecordId": MessageLookupByLibrary.simpleMessage("記錄 ID（可選，十六進位）"),
    "ndefRecordType": MessageLookupByLibrary.simpleMessage("記錄類型"),
    "ndefRecords": MessageLookupByLibrary.simpleMessage("記錄"),
    "ndefRequiredField": MessageLookupByLibrary.simpleMessage("請填寫此項。"),
    "ndefSaveToKey": MessageLookupByLibrary.simpleMessage("儲存到 CanoKey"),
    "ndefSaved": MessageLookupByLibrary.simpleMessage("NFC 標籤記錄已儲存"),
    "ndefSignature": MessageLookupByLibrary.simpleMessage("簽章"),
    "ndefSmartPoster": MessageLookupByLibrary.simpleMessage("智慧海報"),
    "ndefSmartPosterAction": MessageLookupByLibrary.simpleMessage("建議操作"),
    "ndefSmartPosterActionEdit": MessageLookupByLibrary.simpleMessage("編輯"),
    "ndefSmartPosterActionOpen": MessageLookupByLibrary.simpleMessage("開啟"),
    "ndefSmartPosterActionSave": MessageLookupByLibrary.simpleMessage("儲存"),
    "ndefSmartPosterTitle": MessageLookupByLibrary.simpleMessage("標題（可選）"),
    "ndefTagContent": MessageLookupByLibrary.simpleMessage("NFC 標籤內容"),
    "ndefTagContentDescription": MessageLookupByLibrary.simpleMessage(
      "設定其他裝置透過 NFC 讀取 CanoKey 時取得的內容。",
    ),
    "ndefText": MessageLookupByLibrary.simpleMessage("文字"),
    "ndefTextValue": MessageLookupByLibrary.simpleMessage("文字內容"),
    "ndefTnfAbsoluteUri": MessageLookupByLibrary.simpleMessage("絕對 URI"),
    "ndefTnfEmpty": MessageLookupByLibrary.simpleMessage("空記錄"),
    "ndefTnfExternal": MessageLookupByLibrary.simpleMessage("NFC Forum 外部類型"),
    "ndefTnfMedia": MessageLookupByLibrary.simpleMessage("媒體類型 (MIME)"),
    "ndefTnfRequiresEmptyType": MessageLookupByLibrary.simpleMessage(
      "所選記錄格式不允許填寫類型名稱，請清空該欄位。",
    ),
    "ndefTnfUnchanged": MessageLookupByLibrary.simpleMessage("沿用上一段的類型"),
    "ndefTnfUnknown": MessageLookupByLibrary.simpleMessage("未知類型"),
    "ndefTnfWellKnown": MessageLookupByLibrary.simpleMessage("NFC Forum 已知類型"),
    "ndefTypeName": MessageLookupByLibrary.simpleMessage("類型名稱"),
    "ndefTypeNameFormat": MessageLookupByLibrary.simpleMessage("類型名稱格式（TNF）"),
    "ndefUnsavedChanges": MessageLookupByLibrary.simpleMessage("有尚未儲存的修改"),
    "ndefUri": MessageLookupByLibrary.simpleMessage("連結"),
    "ndefUriValue": MessageLookupByLibrary.simpleMessage("連結網址"),
    "ndefWifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
    "ndefWifiAuthentication": MessageLookupByLibrary.simpleMessage("驗證方式"),
    "ndefWifiEncryption": MessageLookupByLibrary.simpleMessage("加密方式"),
    "ndefWifiEnterprise": m5,
    "ndefWifiNoEncryption": MessageLookupByLibrary.simpleMessage("不加密"),
    "ndefWifiOpen": MessageLookupByLibrary.simpleMessage("開放網路"),
    "ndefWifiPassword": MessageLookupByLibrary.simpleMessage("網路密碼"),
    "ndefWifiPersonal": m6,
    "ndefWifiShared": MessageLookupByLibrary.simpleMessage("共用金鑰"),
    "ndefWritable": MessageLookupByLibrary.simpleMessage("可寫"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "與 CanoKey 通訊失敗，請重新連接後再試一次。",
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
      "此操作需要透過 USB 連接 CanoKey。",
    ),
    "oathAccount": MessageLookupByLibrary.simpleMessage("帳戶"),
    "oathAddAccount": MessageLookupByLibrary.simpleMessage("新增帳戶"),
    "oathAddByScanning": MessageLookupByLibrary.simpleMessage("掃描 QR Code 新增"),
    "oathAddByScreen": MessageLookupByLibrary.simpleMessage("掃描螢幕上的 QR Code"),
    "oathAddManually": MessageLookupByLibrary.simpleMessage("手動新增"),
    "oathAdded": MessageLookupByLibrary.simpleMessage("新增成功"),
    "oathAdvancedSettings": MessageLookupByLibrary.simpleMessage(
      "請使用服務商提供的參數，否則產生的驗證碼可能無法使用。",
    ),
    "oathAlgorithm": MessageLookupByLibrary.simpleMessage("演算法"),
    "oathCode": MessageLookupByLibrary.simpleMessage("密碼"),
    "oathCodeChanged": MessageLookupByLibrary.simpleMessage("密碼已修改"),
    "oathCopy": MessageLookupByLibrary.simpleMessage("複製"),
    "oathCounter": MessageLookupByLibrary.simpleMessage("計數器初始值"),
    "oathCounterMustBeNumber": MessageLookupByLibrary.simpleMessage("請輸入整數"),
    "oathDelete": m7,
    "oathDescription": MessageLookupByLibrary.simpleMessage(
      "管理帳戶的一次性驗證碼（TOTP / HOTP）。",
    ),
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
      "輸入新密碼。留空並儲存可取消密碼保護。",
    ),
    "oathNoQr": MessageLookupByLibrary.simpleMessage("未偵測到 QR Code"),
    "oathPeriod": MessageLookupByLibrary.simpleMessage("更新間隔（秒）"),
    "oathRequireTouch": MessageLookupByLibrary.simpleMessage("需要觸碰"),
    "oathRequired": MessageLookupByLibrary.simpleMessage("請填寫此項"),
    "oathSearch": MessageLookupByLibrary.simpleMessage("搜尋帳戶名稱或電子郵件"),
    "oathSecret": MessageLookupByLibrary.simpleMessage("金鑰"),
    "oathSetCode": MessageLookupByLibrary.simpleMessage("設定密碼"),
    "oathSetDefault": MessageLookupByLibrary.simpleMessage("設為觸碰輸出"),
    "oathSetDefaultPrompt": m8,
    "oathSlot": MessageLookupByLibrary.simpleMessage("密碼槽位"),
    "oathTooLong": MessageLookupByLibrary.simpleMessage("長度超限"),
    "oathType": MessageLookupByLibrary.simpleMessage("類型"),
    "off": MessageLookupByLibrary.simpleMessage("關"),
    "oldPin": MessageLookupByLibrary.simpleMessage("目前 PIN"),
    "on": MessageLookupByLibrary.simpleMessage("開"),
    "openpgpAdminPin": MessageLookupByLibrary.simpleMessage("管理員 PIN"),
    "openpgpAdminPinLength": MessageLookupByLibrary.simpleMessage(
      "管理員 PIN 長度必須為 8 到 64 個字元。",
    ),
    "openpgpAuthentication": MessageLookupByLibrary.simpleMessage("驗證"),
    "openpgpCacheSeconds": MessageLookupByLibrary.simpleMessage("有效時間（秒）"),
    "openpgpCardHolder": MessageLookupByLibrary.simpleMessage("持卡人"),
    "openpgpCardInfo": MessageLookupByLibrary.simpleMessage("卡片資訊"),
    "openpgpChangeAdminPin": MessageLookupByLibrary.simpleMessage("修改 管理員 PIN"),
    "openpgpChangeInteraction": m9,
    "openpgpChangeSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "修改簽章 PIN 策略",
    ),
    "openpgpChangeTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "修改觸碰確認有效時間",
    ),
    "openpgpCurrentAdminPin": MessageLookupByLibrary.simpleMessage(
      "目前 管理員 PIN",
    ),
    "openpgpDescription": MessageLookupByLibrary.simpleMessage(
      "查看 OpenPGP 卡片資訊，管理 PIN 和觸碰確認方式。",
    ),
    "openpgpEncryption": MessageLookupByLibrary.simpleMessage("加密"),
    "openpgpKeyEmpty": MessageLookupByLibrary.simpleMessage("空"),
    "openpgpKeyImported": MessageLookupByLibrary.simpleMessage("已匯入"),
    "openpgpKeyNone": MessageLookupByLibrary.simpleMessage("未設定"),
    "openpgpKeys": MessageLookupByLibrary.simpleMessage("金鑰資訊"),
    "openpgpManufacturer": MessageLookupByLibrary.simpleMessage("製造商"),
    "openpgpNewAdminPin": MessageLookupByLibrary.simpleMessage("新 管理員 PIN"),
    "openpgpPermanentTouchConfirmation": MessageLookupByLibrary.simpleMessage(
      "我確認永久啟用後，此金鑰的觸碰策略無法再關閉。",
    ),
    "openpgpPubkeyUrl": MessageLookupByLibrary.simpleMessage("公開金鑰網址"),
    "openpgpResetCode": MessageLookupByLibrary.simpleMessage("重設碼"),
    "openpgpRetries": m10,
    "openpgpRetriesUnknown": MessageLookupByLibrary.simpleMessage("剩餘次數：未知"),
    "openpgpSN": MessageLookupByLibrary.simpleMessage("序號"),
    "openpgpSetPinRetries": MessageLookupByLibrary.simpleMessage("設定 PIN 重試次數"),
    "openpgpSetPinRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作會將 使用者 PIN 重置為 123456，管理員 PIN 重置為 12345678。",
    ),
    "openpgpSetPinRetriesTitle": MessageLookupByLibrary.simpleMessage(
      "設定 PIN 和重設碼的重試次數",
    ),
    "openpgpSetResetCode": MessageLookupByLibrary.simpleMessage("設定 重設碼"),
    "openpgpSetResetCodePrompt": MessageLookupByLibrary.simpleMessage(
      "重設碼 長度必須為 8 到 64 個字元，需要 管理員 PIN 授權。",
    ),
    "openpgpSetTouchCacheTime": MessageLookupByLibrary.simpleMessage(
      "設定觸碰確認有效時間",
    ),
    "openpgpSetTouchCacheTimePrompt": MessageLookupByLibrary.simpleMessage(
      "設定觸碰一次後多久內不需再次觸碰。設為 0 表示每次操作都需觸碰。修改需要驗證管理員 PIN。",
    ),
    "openpgpSignature": MessageLookupByLibrary.simpleMessage("簽章"),
    "openpgpSignaturePin": MessageLookupByLibrary.simpleMessage("簽章 PIN"),
    "openpgpSignaturePinPolicy": MessageLookupByLibrary.simpleMessage(
      "簽章 PIN 策略",
    ),
    "openpgpTouchCacheOff": MessageLookupByLibrary.simpleMessage("0 秒（每次觸碰）"),
    "openpgpTouchCacheSeconds": m11,
    "openpgpTouchCached": MessageLookupByLibrary.simpleMessage("限時免觸碰"),
    "openpgpTouchCachedLabel": MessageLookupByLibrary.simpleMessage("觸碰：限時免確認"),
    "openpgpTouchNone": MessageLookupByLibrary.simpleMessage("無需觸碰"),
    "openpgpTouchOffLabel": MessageLookupByLibrary.simpleMessage("觸碰：關閉"),
    "openpgpTouchOnLabel": MessageLookupByLibrary.simpleMessage("觸碰：開啟"),
    "openpgpTouchPermanent": MessageLookupByLibrary.simpleMessage("需要觸碰（不可關閉）"),
    "openpgpTouchPermanentCached": MessageLookupByLibrary.simpleMessage(
      "限時免觸碰（不可關閉）",
    ),
    "openpgpTouchPermanentCachedLabel": MessageLookupByLibrary.simpleMessage(
      "觸碰：限時免確認，不可關閉",
    ),
    "openpgpTouchPermanentLabel": MessageLookupByLibrary.simpleMessage(
      "觸碰：需要，不可關閉",
    ),
    "openpgpTouchRequired": MessageLookupByLibrary.simpleMessage("需要觸碰"),
    "openpgpUIF": MessageLookupByLibrary.simpleMessage("觸碰設定"),
    "openpgpUifCacheTime": MessageLookupByLibrary.simpleMessage("觸碰確認有效時間"),
    "openpgpUifCacheTimeChanged": MessageLookupByLibrary.simpleMessage(
      "觸碰確認有效時間已修改",
    ),
    "openpgpUifChanged": MessageLookupByLibrary.simpleMessage("觸碰設定修改成功"),
    "openpgpUifOff": MessageLookupByLibrary.simpleMessage("關閉"),
    "openpgpUifOn": MessageLookupByLibrary.simpleMessage("開啟"),
    "openpgpUifPermanent": MessageLookupByLibrary.simpleMessage("永久啟用（無法再關閉）"),
    "openpgpUnblockUserPin": MessageLookupByLibrary.simpleMessage("解鎖 使用者 PIN"),
    "openpgpUseAdminPin": MessageLookupByLibrary.simpleMessage("使用 管理員 PIN"),
    "openpgpUseResetCode": MessageLookupByLibrary.simpleMessage("使用 重設碼"),
    "openpgpUserPin": MessageLookupByLibrary.simpleMessage("使用者 PIN"),
    "openpgpUserPinLength": MessageLookupByLibrary.simpleMessage(
      "使用者 PIN 長度必須為 6 到 64 個字元。",
    ),
    "openpgpVerifyEverySignature": MessageLookupByLibrary.simpleMessage(
      "每次簽章都驗證",
    ),
    "openpgpVerifyEverySignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "每次簽章都驗證 使用者 PIN",
    ),
    "openpgpVerifyOnceAfterInsertion": MessageLookupByLibrary.simpleMessage(
      "插入後驗證一次",
    ),
    "openpgpVerifyOnceAfterInsertionPrompt":
        MessageLookupByLibrary.simpleMessage("每次插入後只驗證一次"),
    "openpgpVersion": MessageLookupByLibrary.simpleMessage("版本"),
    "operationFailed": MessageLookupByLibrary.simpleMessage(
      "操作失敗，請重新讀取 CanoKey 後再試一次。",
    ),
    "other": MessageLookupByLibrary.simpleMessage("其他"),
    "passDescription": MessageLookupByLibrary.simpleMessage(
      "設定短按或長按 CanoKey 時輸出的密碼。",
    ),
    "passInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "請輸入設定頁面使用的管理 PIN，預設值為 123456。",
    ),
    "passNotSupported": MessageLookupByLibrary.simpleMessage(
      "您的 CanoKey 不支援 Pass 功能。",
    ),
    "passSlotConfigPrompt": MessageLookupByLibrary.simpleMessage(
      "選擇觸碰 CanoKey 時執行的操作。如需輸出 HOTP 驗證碼，請在 OTP 頁面設定。",
    ),
    "passSlotConfigTitle": MessageLookupByLibrary.simpleMessage("觸碰輸出設定"),
    "passSlotHmacSha1": MessageLookupByLibrary.simpleMessage("HMAC-SHA1"),
    "passSlotHmacSha1Key": MessageLookupByLibrary.simpleMessage(
      "20 位元組 HMAC-SHA1 金鑰（十六進位）",
    ),
    "passSlotHotp": MessageLookupByLibrary.simpleMessage("HOTP"),
    "passSlotLong": MessageLookupByLibrary.simpleMessage("長按"),
    "passSlotOff": MessageLookupByLibrary.simpleMessage("關閉"),
    "passSlotShort": MessageLookupByLibrary.simpleMessage("短按"),
    "passSlotStatic": MessageLookupByLibrary.simpleMessage("固定密碼"),
    "passSlotWithEnter": MessageLookupByLibrary.simpleMessage("輸出後按 Enter"),
    "passStatus": MessageLookupByLibrary.simpleMessage("狀態"),
    "passkey": MessageLookupByLibrary.simpleMessage("通行密鑰"),
    "pinChanged": MessageLookupByLibrary.simpleMessage("PIN 修改成功"),
    "pinConfirmationMismatch": MessageLookupByLibrary.simpleMessage(
      "兩次輸入的 PIN 不一致",
    ),
    "pinIncorrect": MessageLookupByLibrary.simpleMessage("PIN 輸入錯誤"),
    "pinInvalidLength": MessageLookupByLibrary.simpleMessage("長度錯誤"),
    "pinLength": MessageLookupByLibrary.simpleMessage("輸入的 PIN 長度錯誤"),
    "pinRetries": m12,
    "pinVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "PIN 驗證失敗，請重新讀取 CanoKey 後再試一次。",
    ),
    "pivActionsDescription": MessageLookupByLibrary.simpleMessage(
      "選擇此槽位要執行的操作。",
    ),
    "pivAlgorithm": MessageLookupByLibrary.simpleMessage("金鑰演算法"),
    "pivAlgorithmColumn": MessageLookupByLibrary.simpleMessage("演算法"),
    "pivAlgorithmIds": MessageLookupByLibrary.simpleMessage("演算法 ID"),
    "pivAlgorithmIdsPrompt": MessageLookupByLibrary.simpleMessage(
      "允許 CanoKey 使用擴充演算法。",
    ),
    "pivAlgorithmIdsTitle": MessageLookupByLibrary.simpleMessage("PIV 演算法 ID"),
    "pivAlgorithmIdsUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "更新 PIV 演算法 ID 失敗",
    ),
    "pivAlgorithmIdsWarning": MessageLookupByLibrary.simpleMessage(
      "通常不需修改。只有軟體或韌體要求使用其他演算法 ID 時才需要變更。填錯後，現有金鑰可能無法辨識；恢復正確的 ID 後可重新辨識。",
    ),
    "pivAlgorithmValue": m13,
    "pivAttestationUnavailable": MessageLookupByLibrary.simpleMessage(
      "無法產生證明憑證。裝置必須已設定 F9 證明金鑰和憑證。",
    ),
    "pivAuthentication": MessageLookupByLibrary.simpleMessage(
      "驗證（Authentication）",
    ),
    "pivBasicConstraints": MessageLookupByLibrary.simpleMessage("憑證基本限制"),
    "pivCardAuthentication": MessageLookupByLibrary.simpleMessage(
      "卡驗證（Card Authentication）",
    ),
    "pivCertificate": MessageLookupByLibrary.simpleMessage("憑證"),
    "pivCertificateCopied": MessageLookupByLibrary.simpleMessage("憑證已複製"),
    "pivCertificateCreated": MessageLookupByLibrary.simpleMessage("憑證已建立"),
    "pivCertificateCustom": MessageLookupByLibrary.simpleMessage("自訂設定"),
    "pivCertificateDoesNotMatchPrivateKey":
        MessageLookupByLibrary.simpleMessage("憑證公開金鑰與所選私密金鑰不相符。"),
    "pivCertificateExtensions": MessageLookupByLibrary.simpleMessage("憑證擴充欄位"),
    "pivCertificateInfo": MessageLookupByLibrary.simpleMessage("憑證資訊"),
    "pivCertificateInfoDescription": MessageLookupByLibrary.simpleMessage(
      "目前槽位中的憑證詳細資訊。",
    ),
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
    "pivCertificatePresent": MessageLookupByLibrary.simpleMessage("已存有憑證"),
    "pivCertificateSerial": MessageLookupByLibrary.simpleMessage("序號"),
    "pivCertificateSize": MessageLookupByLibrary.simpleMessage("憑證大小"),
    "pivCertificateStatus": MessageLookupByLibrary.simpleMessage("憑證狀態"),
    "pivCertificateSubject": MessageLookupByLibrary.simpleMessage("憑證主體"),
    "pivCertificateSubjectAndExtensions": MessageLookupByLibrary.simpleMessage(
      "憑證資訊與擴充欄位",
    ),
    "pivCertificateSubjectStep": MessageLookupByLibrary.simpleMessage("憑證主體資訊"),
    "pivCertificateValidFrom": MessageLookupByLibrary.simpleMessage("生效時間"),
    "pivCertificateValidTo": MessageLookupByLibrary.simpleMessage("失效時間"),
    "pivCertificateWritten": m14,
    "pivChangeManagementKey": MessageLookupByLibrary.simpleMessage("修改管理金鑰"),
    "pivChangeManagementKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "新管理金鑰的長度應當為 24 位元組。請妥善保管管理金鑰，否則您將無法管理 PIV 應用程式。",
    ),
    "pivChangePUK": MessageLookupByLibrary.simpleMessage("修改 PUK"),
    "pivChangePUKPrompt": m15,
    "pivClearSlot": MessageLookupByLibrary.simpleMessage("清空槽位"),
    "pivClearSlotFailed": MessageLookupByLibrary.simpleMessage(
      "清空槽位失敗。請確認韌體支援刪除私密金鑰。",
    ),
    "pivClearSlotPrompt": MessageLookupByLibrary.simpleMessage(
      "此操作會刪除此槽位中的私密金鑰和憑證。請確認您仍有其他驗證方式。",
    ),
    "pivClearSlotTitle": m16,
    "pivCommonName": MessageLookupByLibrary.simpleMessage("一般名稱（CN）"),
    "pivCopyPem": MessageLookupByLibrary.simpleMessage("複製 PEM"),
    "pivCountryCode": MessageLookupByLibrary.simpleMessage("國家或地區代碼"),
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
      "產生憑證簽署請求（CSR），用於向憑證授權單位申請憑證。新金鑰將在 CanoKey 中產生。",
    ),
    "pivCsrSubject": MessageLookupByLibrary.simpleMessage("憑證請求資訊"),
    "pivDangerDescription": MessageLookupByLibrary.simpleMessage(
      "移動或刪除金鑰前，請確認您有其他登入或解密方式。",
    ),
    "pivDangerZone": MessageLookupByLibrary.simpleMessage("危險操作"),
    "pivDelete": MessageLookupByLibrary.simpleMessage("刪除"),
    "pivDeleteSlot": m17,
    "pivDestinationSlot": MessageLookupByLibrary.simpleMessage("目標槽位"),
    "pivDiagnostics": MessageLookupByLibrary.simpleMessage("金鑰操作"),
    "pivDisablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "改為手動管理金鑰",
    ),
    "pivDisablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage("改為手動管理金鑰失敗"),
    "pivDisablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage(
          "將設定新的管理金鑰，並刪除 CanoKey 中由 PIN 保護的副本。之後需要手動輸入管理金鑰。PUK 仍會鎖定；如需恢復 PUK，可在退出此模式後重設重試次數，但這也會重置 PIN。",
        ),
    "pivDisablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage("之後需要手動輸入管理金鑰"),
    "pivDnsSans": MessageLookupByLibrary.simpleMessage("網域名稱（多個名稱以逗號分隔）"),
    "pivDownloadAttestation": MessageLookupByLibrary.simpleMessage("下載證明憑證"),
    "pivEmpty": MessageLookupByLibrary.simpleMessage("空"),
    "pivEnablePinProtectedManagementKey": MessageLookupByLibrary.simpleMessage(
      "使用 PIN 保護管理金鑰",
    ),
    "pivEnablePinProtectedManagementKeyFailed":
        MessageLookupByLibrary.simpleMessage("儲存 PIN 保護管理金鑰失敗"),
    "pivEnablePinProtectedManagementKeyPrompt":
        MessageLookupByLibrary.simpleMessage(
          "啟用後，管理金鑰將隨機產生並儲存在 CanoKey 中，後續管理操作只需驗證 PIN。PUK 將被鎖定，無法再用於重設或解鎖 PIN。啟用期間也無法修改 PIN 和 PUK 的重試次數。",
        ),
    "pivEnablePinProtectedManagementKeySuccess":
        MessageLookupByLibrary.simpleMessage("管理金鑰已由 PIN 保護"),
    "pivEndEntityConstraint": MessageLookupByLibrary.simpleMessage(
      "標示為非 CA 憑證（CA=false）",
    ),
    "pivExport": MessageLookupByLibrary.simpleMessage("匯出"),
    "pivExportCertificate": MessageLookupByLibrary.simpleMessage("匯出憑證"),
    "pivExportDescription": MessageLookupByLibrary.simpleMessage(
      "將憑證或公開金鑰儲存為檔案。",
    ),
    "pivExportPublicKey": MessageLookupByLibrary.simpleMessage("匯出公開金鑰"),
    "pivExtendedAlgorithmCompatibilityWarning":
        MessageLookupByLibrary.simpleMessage("請先確認您要使用的軟體支援此演算法。"),
    "pivExtendedKeyUsage": MessageLookupByLibrary.simpleMessage("延伸金鑰用途（EKU）"),
    "pivExtensionsDescription": MessageLookupByLibrary.simpleMessage(
      "設定憑證的基本限制、金鑰用途與延伸金鑰用途。",
    ),
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
    "pivGeneratingKey": m18,
    "pivGeneratingX25519Key": MessageLookupByLibrary.simpleMessage(
      "產生 X25519 金鑰",
    ),
    "pivImport": MessageLookupByLibrary.simpleMessage("匯入"),
    "pivImportFailed": MessageLookupByLibrary.simpleMessage("匯入失敗"),
    "pivImportSucceeded": MessageLookupByLibrary.simpleMessage("匯入成功"),
    "pivImportWillReplaceCertificate": MessageLookupByLibrary.simpleMessage(
      "本次匯入會替換此槽位中現有的憑證。",
    ),
    "pivImportWillReplacePrivateKey": MessageLookupByLibrary.simpleMessage(
      "本次匯入會替換此槽位中現有的私密金鑰。",
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
    "pivKeyOperationsDescription": MessageLookupByLibrary.simpleMessage(
      "為訊息或檔案簽署，或驗證檔案簽章。",
    ),
    "pivKeyOptions": MessageLookupByLibrary.simpleMessage("金鑰選項"),
    "pivKeyUsage": MessageLookupByLibrary.simpleMessage("金鑰用途（Key Usage）"),
    "pivKeyUsageCritical": MessageLookupByLibrary.simpleMessage("要求驗證端檢查金鑰用途"),
    "pivMacLogin": MessageLookupByLibrary.simpleMessage("macOS 登入"),
    "pivMacLoginDescription": MessageLookupByLibrary.simpleMessage(
      "使用 PIV 憑證登入 macOS。",
    ),
    "pivMacOsApply": MessageLookupByLibrary.simpleMessage("套用 macOS 登入建議設定"),
    "pivMacOsAuthenticationSlot": MessageLookupByLibrary.simpleMessage(
      "9A · 身分驗證",
    ),
    "pivMacOsDescription": MessageLookupByLibrary.simpleMessage(
      "9A 槽位中的金鑰和憑證用於 macOS 登入時的身分驗證。還需設定 9D 槽位，用於解鎖登入鑰匙圈。",
    ),
    "pivMacOsGuide": MessageLookupByLibrary.simpleMessage(
      "設定 9A 槽位用於登入時的身分驗證，設定 9D 槽位用於解鎖登入鑰匙圈。完成後，請重新插入 CanoKey，並依照 macOS 的提示，將智慧卡與您的使用者帳號配對。",
    ),
    "pivMacOsGuideTitle": MessageLookupByLibrary.simpleMessage(
      "使用 CanoKey 登入 macOS",
    ),
    "pivMacOsKeychainDescription": MessageLookupByLibrary.simpleMessage(
      "9D 槽位中的金鑰和憑證用於解鎖 macOS 登入鑰匙圈。還需設定 9A 槽位，用於登入時的身分驗證。",
    ),
    "pivMacOsKeychainSlot": MessageLookupByLibrary.simpleMessage("9D · 解鎖鑰匙圈"),
    "pivMacOsOtherSlot": MessageLookupByLibrary.simpleMessage(
      "使用 CanoKey 登入 macOS，需要設定 9A 和 9D 兩個槽位。",
    ),
    "pivMacOsSlotApplied": m19,
    "pivMacSetupConsent": MessageLookupByLibrary.simpleMessage(
      "我確認替換上面列出的金鑰或憑證。被替換的金鑰無法復原。",
    ),
    "pivMacSetupCreate": MessageLookupByLibrary.simpleMessage("產生金鑰和憑證"),
    "pivMacSetupCredentials": MessageLookupByLibrary.simpleMessage(
      "請輸入 PIV PIN 和管理金鑰。",
    ),
    "pivMacSetupDone": MessageLookupByLibrary.simpleMessage(
      "CanoKey 設定完成。請重新插入 CanoKey，依照 macOS 提示與您的登入帳號配對。",
    ),
    "pivMacSetupError": MessageLookupByLibrary.simpleMessage(
      "檢查或設定失敗。請檢查連線、PIV PIN 和管理金鑰後再試一次。已完成的設定會保留。無法讀取金鑰資訊的舊版韌體不支援此功能。",
    ),
    "pivMacSetupFinished": MessageLookupByLibrary.simpleMessage("已完成"),
    "pivMacSetupInspect": MessageLookupByLibrary.simpleMessage("重新檢查"),
    "pivMacSetupIntro": MessageLookupByLibrary.simpleMessage(
      "設定 macOS 登入所需的金鑰和憑證。將檢查 9A 和 9D 槽位，並保留符合要求的現有內容。",
    ),
    "pivMacSetupInvalid": MessageLookupByLibrary.simpleMessage(
      "PIV PIN 或管理金鑰的格式不正確，請檢查後再試一次。",
    ),
    "pivMacSetupIssue": MessageLookupByLibrary.simpleMessage("保留現有金鑰，產生憑證"),
    "pivMacSetupKeep": MessageLookupByLibrary.simpleMessage("保留現有設定"),
    "pivMacSetupManagementKey": MessageLookupByLibrary.simpleMessage(
      "管理金鑰（十六進位）",
    ),
    "pivMacSetupReplaceCert": MessageLookupByLibrary.simpleMessage(
      "保留現有金鑰，替換憑證",
    ),
    "pivMacSetupReplaceKey": MessageLookupByLibrary.simpleMessage("替換金鑰和憑證"),
    "pivMacSetupStart": MessageLookupByLibrary.simpleMessage("開始設定"),
    "pivMacSetupTitle": MessageLookupByLibrary.simpleMessage("設定 macOS 登入"),
    "pivMacSetupWorking": MessageLookupByLibrary.simpleMessage("正在設定"),
    "pivMainSlots": MessageLookupByLibrary.simpleMessage("主要槽位"),
    "pivManage": MessageLookupByLibrary.simpleMessage("管理"),
    "pivManagementKey": MessageLookupByLibrary.simpleMessage("管理金鑰"),
    "pivManagementKeyAuthentication": MessageLookupByLibrary.simpleMessage(
      "管理金鑰驗證方式",
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
      "移動失敗，請選擇沒有金鑰的目標槽位。",
    ),
    "pivMoveKeyFrom": m20,
    "pivMoveKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "僅移動私密金鑰；憑證會保留在原來的槽位中。",
    ),
    "pivNameColumn": MessageLookupByLibrary.simpleMessage("名稱"),
    "pivNewManagementKey": MessageLookupByLibrary.simpleMessage("新管理金鑰"),
    "pivNewPUK": MessageLookupByLibrary.simpleMessage("新 PUK"),
    "pivNoCertificate": MessageLookupByLibrary.simpleMessage("無憑證"),
    "pivNoEmptyDestinationSlot": MessageLookupByLibrary.simpleMessage(
      "沒有可接收金鑰的空槽位。",
    ),
    "pivNoFileSelected": MessageLookupByLibrary.simpleMessage("未選擇檔案"),
    "pivNoPublicKeyAvailable": MessageLookupByLibrary.simpleMessage(
      "沒有可用的公開金鑰",
    ),
    "pivNotSelected": MessageLookupByLibrary.simpleMessage("未選擇"),
    "pivOccupiedSlots": m21,
    "pivOldManagementKey": MessageLookupByLibrary.simpleMessage("目前管理金鑰"),
    "pivOldPUK": MessageLookupByLibrary.simpleMessage("目前 PUK"),
    "pivOperationRequiresPin": MessageLookupByLibrary.simpleMessage(
      "此操作本身還需要驗證 PIN。",
    ),
    "pivOrganization": MessageLookupByLibrary.simpleMessage("組織"),
    "pivOrganizationalUnit": MessageLookupByLibrary.simpleMessage("組織單位"),
    "pivOrigin": MessageLookupByLibrary.simpleMessage("來源"),
    "pivOriginGenerated": MessageLookupByLibrary.simpleMessage("在 CanoKey 上產生"),
    "pivOriginImported": MessageLookupByLibrary.simpleMessage("從檔案匯入"),
    "pivOverwrite": MessageLookupByLibrary.simpleMessage("覆蓋"),
    "pivOverwriteKey": MessageLookupByLibrary.simpleMessage("覆蓋金鑰"),
    "pivOverwriteKeyPrompt": m22,
    "pivPageDescription": MessageLookupByLibrary.simpleMessage(
      "管理 CanoKey 中的 PIV 金鑰、憑證和 PIN。",
    ),
    "pivPageTitle": MessageLookupByLibrary.simpleMessage("PIV"),
    "pivPinAndTouchPolicy": MessageLookupByLibrary.simpleMessage("PIN 和觸碰策略"),
    "pivPinDescription": MessageLookupByLibrary.simpleMessage("用於使用者身分驗證"),
    "pivPinManagement": MessageLookupByLibrary.simpleMessage("管理 PIN"),
    "pivPinPolicy": MessageLookupByLibrary.simpleMessage("PIN 策略"),
    "pivPinPolicyAlways": MessageLookupByLibrary.simpleMessage("每次驗證"),
    "pivPinPolicyChip": m23,
    "pivPinPolicyDefault": MessageLookupByLibrary.simpleMessage("預設"),
    "pivPinPolicyNever": MessageLookupByLibrary.simpleMessage("從不驗證"),
    "pivPinPolicyOnce": MessageLookupByLibrary.simpleMessage("工作階段內驗證一次"),
    "pivPinProtectedKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "使用 PIN 驗證",
    ),
    "pivPinProtectedManagementKeyDescription":
        MessageLookupByLibrary.simpleMessage("使用 PIN 解鎖儲存在卡內的管理金鑰。"),
    "pivPinRetries": MessageLookupByLibrary.simpleMessage("PIN 重試次數"),
    "pivPostQuantumCertificateGenerationDisabled":
        MessageLookupByLibrary.simpleMessage("此演算法不支援產生 CSR、自我簽署憑證或金鑰證明。"),
    "pivPrintedDataWarning": MessageLookupByLibrary.simpleMessage(
      "警告：啟用 PIN-only 模式後，切勿覆寫 PRINTED（Printed Information）資料物件。該物件儲存著受 PIN 保護的管理金鑰，覆寫它將導致金鑰遺失，失去對 PIV 應用程式的管理權限。",
    ),
    "pivPrivateKey": MessageLookupByLibrary.simpleMessage("私密金鑰"),
    "pivProvisioning": MessageLookupByLibrary.simpleMessage("設定"),
    "pivProvisioningDescription": MessageLookupByLibrary.simpleMessage(
      "為此槽位產生或匯入金鑰和憑證。",
    ),
    "pivPublicKey": MessageLookupByLibrary.simpleMessage("公開金鑰"),
    "pivPukDescription": MessageLookupByLibrary.simpleMessage("用於解除 PIN 鎖定"),
    "pivPukRetries": MessageLookupByLibrary.simpleMessage("PUK 重試次數"),
    "pivRandomManagementKey": MessageLookupByLibrary.simpleMessage("隨機產生"),
    "pivRetired1": MessageLookupByLibrary.simpleMessage("歷史金鑰 1"),
    "pivRetired2": MessageLookupByLibrary.simpleMessage("歷史金鑰 2"),
    "pivRetiredSlot": m24,
    "pivRetiredSlots": MessageLookupByLibrary.simpleMessage("歷史金鑰槽位"),
    "pivRetries": m25,
    "pivRetriesRemaining": MessageLookupByLibrary.simpleMessage("剩餘嘗試次數"),
    "pivRetriesUnknown": MessageLookupByLibrary.simpleMessage("剩餘次數：未知"),
    "pivReview": MessageLookupByLibrary.simpleMessage("確認"),
    "pivSavePem": MessageLookupByLibrary.simpleMessage("儲存 PEM"),
    "pivSelectCertificateOrKeyFirst": MessageLookupByLibrary.simpleMessage(
      "請先選擇憑證或私密金鑰。",
    ),
    "pivSelectFile": MessageLookupByLibrary.simpleMessage("選擇檔案"),
    "pivSelectFileAndSignatureFirst": MessageLookupByLibrary.simpleMessage(
      "請先選擇原始檔案和簽章檔案。",
    ),
    "pivSelectFileFirst": MessageLookupByLibrary.simpleMessage("請先選擇檔案。"),
    "pivSelectFileHint": MessageLookupByLibrary.simpleMessage("私密金鑰檔案不能有密碼保護。"),
    "pivSelectFilePrompt": MessageLookupByLibrary.simpleMessage(
      "選擇 PEM 或 DER 格式的憑證或私密金鑰檔案",
    ),
    "pivSelfSign": MessageLookupByLibrary.simpleMessage("產生自我簽署憑證"),
    "pivSelfSignCertificate": MessageLookupByLibrary.simpleMessage("產生自我簽署憑證"),
    "pivSelfSignedCertificateWarning": MessageLookupByLibrary.simpleMessage(
      "自我簽署憑證可能需要在使用的軟體中手動設為受信任憑證。請先確認該軟體支援自我簽署憑證。",
    ),
    "pivSetPinPukRetries": MessageLookupByLibrary.simpleMessage(
      "設定 PIN/PUK 重試次數",
    ),
    "pivSetPinPukRetriesPrompt": MessageLookupByLibrary.simpleMessage(
      "修改重試次數會將 PIN 重置為 123456，PUK 重置為 12345678。請先關閉「使用 PIN 保護管理金鑰」。",
    ),
    "pivSetRetriesFailed": MessageLookupByLibrary.simpleMessage("設定重試次數失敗"),
    "pivSetRetriesMetadataFailed": MessageLookupByLibrary.simpleMessage(
      "重試次數已修改，但部分管理資訊未能儲存。PIN 已重置為 123456，PUK 已重置為 12345678。請重新讀取 CanoKey，檢查目前狀態。",
    ),
    "pivSetRetriesSuccess": MessageLookupByLibrary.simpleMessage(
      "重試次數已修改，PIN 已重置為 123456，PUK 已重置為 12345678。",
    ),
    "pivSha256Fingerprint": MessageLookupByLibrary.simpleMessage("SHA-256 指紋"),
    "pivSign": MessageLookupByLibrary.simpleMessage("簽章"),
    "pivSignFile": MessageLookupByLibrary.simpleMessage("檔案簽章"),
    "pivSignFilePrompt": MessageLookupByLibrary.simpleMessage(
      "使用此金鑰為檔案簽署。簽章將另存為檔案，不會修改原始檔案。",
    ),
    "pivSignMessage": MessageLookupByLibrary.simpleMessage("訊息簽章"),
    "pivSignature": MessageLookupByLibrary.simpleMessage(
      "簽章（Digital Signature）",
    ),
    "pivSignatureAlgorithm": MessageLookupByLibrary.simpleMessage("簽章演算法"),
    "pivSignatureFile": MessageLookupByLibrary.simpleMessage("簽章檔案"),
    "pivSignatureHex": MessageLookupByLibrary.simpleMessage("簽章（十六進位）"),
    "pivSignatureVerificationFailed": MessageLookupByLibrary.simpleMessage(
      "簽章驗證失敗",
    ),
    "pivSignatureVerified": MessageLookupByLibrary.simpleMessage("簽章驗證通過"),
    "pivSlotAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "用於登入時的身分驗證，請選擇支援簽章的金鑰演算法。",
    ),
    "pivSlotCardAuthenticationHint": MessageLookupByLibrary.simpleMessage(
      "用於驗證智慧卡身分，是否需要 PIN 取決於使用情境。",
    ),
    "pivSlotCertificateOnly": MessageLookupByLibrary.simpleMessage("僅憑證"),
    "pivSlotCleared": MessageLookupByLibrary.simpleMessage("槽位已清空"),
    "pivSlotColumn": MessageLookupByLibrary.simpleMessage("槽位"),
    "pivSlotKeyAndCertificate": MessageLookupByLibrary.simpleMessage("金鑰與憑證"),
    "pivSlotKeyManagementHint": MessageLookupByLibrary.simpleMessage(
      "用於解密或金鑰協議。X25519 僅支援金鑰協議。",
    ),
    "pivSlotKeyOnly": MessageLookupByLibrary.simpleMessage("僅金鑰"),
    "pivSlotRetiredHint": MessageLookupByLibrary.simpleMessage(
      "儲存舊的解密金鑰和憑證，以便繼續讀取以前加密的資料。",
    ),
    "pivSlotSignatureHint": MessageLookupByLibrary.simpleMessage(
      "用於數位簽章，預設每次簽署都需要驗證 PIN。",
    ),
    "pivSlots": MessageLookupByLibrary.simpleMessage("憑證槽位"),
    "pivSlotsDescription": MessageLookupByLibrary.simpleMessage(
      "每個槽位用於存放一組金鑰和憑證。",
    ),
    "pivSlotsHint": MessageLookupByLibrary.simpleMessage("選擇槽位檢視或管理憑證"),
    "pivSlotsTitle": MessageLookupByLibrary.simpleMessage("憑證槽位"),
    "pivStatusBlocked": MessageLookupByLibrary.simpleMessage("已鎖定"),
    "pivStatusConfigured": MessageLookupByLibrary.simpleMessage("已設定"),
    "pivStatusEmpty": MessageLookupByLibrary.simpleMessage("未設定"),
    "pivStatusReady": MessageLookupByLibrary.simpleMessage("正常"),
    "pivStatusUnknown": MessageLookupByLibrary.simpleMessage("未知"),
    "pivStoreManagementKeyOnCard": MessageLookupByLibrary.simpleMessage(
      "將新管理金鑰儲存在卡內",
    ),
    "pivStoreManagementKeyOnCardPrompt": MessageLookupByLibrary.simpleMessage(
      "儲存在 CanoKey 後，管理操作只需驗證 PIN。PUK 將被鎖定，無法再用於重設或解鎖 PIN。",
    ),
    "pivSubjectDescription": MessageLookupByLibrary.simpleMessage(
      "填寫憑證持有者的名稱、組織等資訊。",
    ),
    "pivTouchPolicy": MessageLookupByLibrary.simpleMessage("觸碰策略"),
    "pivTouchPolicyAlways": MessageLookupByLibrary.simpleMessage("每次觸碰"),
    "pivTouchPolicyCached": MessageLookupByLibrary.simpleMessage(
      "觸碰後 15 秒內免確認",
    ),
    "pivTouchPolicyChip": m26,
    "pivTouchPolicyDefault": MessageLookupByLibrary.simpleMessage("預設"),
    "pivTouchPolicyNever": MessageLookupByLibrary.simpleMessage("無需觸碰"),
    "pivTransfer": MessageLookupByLibrary.simpleMessage("匯入/匯出"),
    "pivUnblockPin": MessageLookupByLibrary.simpleMessage("解鎖 PIN"),
    "pivUnblockPinPrompt": MessageLookupByLibrary.simpleMessage(
      "輸入目前 PUK 並設定新的 PIN。",
    ),
    "pivUnsupportedImportFile": MessageLookupByLibrary.simpleMessage(
      "不支援的檔案。請使用 PEM 或 DER 格式的憑證/私密金鑰檔案。",
    ),
    "pivUsageClientAuth": MessageLookupByLibrary.simpleMessage("用戶端身分驗證"),
    "pivUsageCodeSigning": MessageLookupByLibrary.simpleMessage("程式碼簽署"),
    "pivUsageContentCommitment": MessageLookupByLibrary.simpleMessage("不可否認性"),
    "pivUsageDataEncipherment": MessageLookupByLibrary.simpleMessage("資料加密"),
    "pivUsageDigitalSignature": MessageLookupByLibrary.simpleMessage("數位簽章"),
    "pivUsageEmailProtection": MessageLookupByLibrary.simpleMessage("電子郵件保護"),
    "pivUsageKeyAgreement": MessageLookupByLibrary.simpleMessage("金鑰協議"),
    "pivUsageKeyEncipherment": MessageLookupByLibrary.simpleMessage("金鑰加密"),
    "pivUsageOmitted": MessageLookupByLibrary.simpleMessage("留空表示不加入此用途限制。"),
    "pivUsageServerAuth": MessageLookupByLibrary.simpleMessage("伺服器身分驗證"),
    "pivUsageSmartCardLogon": MessageLookupByLibrary.simpleMessage("智慧卡登入"),
    "pivUseDefaultManagementKey": MessageLookupByLibrary.simpleMessage("使用預設值"),
    "pivValidityDays": MessageLookupByLibrary.simpleMessage("有效天數"),
    "pivVerify": MessageLookupByLibrary.simpleMessage("驗證"),
    "pivVerifyFile": MessageLookupByLibrary.simpleMessage("驗證檔案簽章"),
    "pivVerifyFileSignature": MessageLookupByLibrary.simpleMessage("驗證檔案簽章"),
    "pivVerifyFileSignaturePrompt": MessageLookupByLibrary.simpleMessage(
      "選擇原始檔案和對應的簽章檔案，使用此槽位的公開金鑰驗證簽章。",
    ),
    "pivVerifyManagementKey": MessageLookupByLibrary.simpleMessage("驗證管理金鑰"),
    "pivVerifyPinAndManagementKey": MessageLookupByLibrary.simpleMessage(
      "輸入 PIN 和管理金鑰",
    ),
    "pivViewCertificate": MessageLookupByLibrary.simpleMessage("檢視憑證"),
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
      "X25519 金鑰只支援匯入金鑰管理槽位 9D。",
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
      "請讓 CanoKey 靠近手機，直到讀取完成。",
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
      "各應用程式使用空間",
    ),
    "settingsAppletSwitches": MessageLookupByLibrary.simpleMessage("應用程式開關"),
    "settingsAppletSwitchesDescription": MessageLookupByLibrary.simpleMessage(
      "選擇要啟用的應用程式及其可用的通訊方式。",
    ),
    "settingsChangeLanguage": MessageLookupByLibrary.simpleMessage("修改語言"),
    "settingsChipId": MessageLookupByLibrary.simpleMessage("晶片 ID"),
    "settingsClearPinCache": MessageLookupByLibrary.simpleMessage("清除已儲存的 PIN"),
    "settingsClearPinCachePrompt": MessageLookupByLibrary.simpleMessage(
      "確定要清除此裝置上所有已儲存的 PIN 嗎？",
    ),
    "settingsCoreCommit": MessageLookupByLibrary.simpleMessage("韌體原始碼版本"),
    "settingsDescription": MessageLookupByLibrary.simpleMessage(
      "查看 CanoKey 資訊，設定裝置功能和應用程式偏好。",
    ),
    "settingsDeviceActions": MessageLookupByLibrary.simpleMessage("裝置操作"),
    "settingsDeviceSettings": MessageLookupByLibrary.simpleMessage("裝置設定"),
    "settingsFirmwareVersion": MessageLookupByLibrary.simpleMessage("韌體版本"),
    "settingsFixNFC": MessageLookupByLibrary.simpleMessage("修復 NFC"),
    "settingsFixNFCSuccess": MessageLookupByLibrary.simpleMessage("修復 NFC 成功"),
    "settingsHotp": MessageLookupByLibrary.simpleMessage("觸碰時輸出 HOTP"),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("CanoKey 資訊"),
    "settingsInputPin": MessageLookupByLibrary.simpleMessage("PIN 驗證"),
    "settingsInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "請輸入設定頁面使用的管理 PIN，預設值為 123456。它與 OpenPGP、PIV 等應用程式的 PIN 分開設定。",
    ),
    "settingsKeyboardLayout": MessageLookupByLibrary.simpleMessage("鍵盤配置"),
    "settingsKeyboardLayoutCurrent": m27,
    "settingsKeyboardLayoutCustom": MessageLookupByLibrary.simpleMessage(
      "自訂配置",
    ),
    "settingsKeyboardLayoutDefault": MessageLookupByLibrary.simpleMessage(
      "預設 / US QWERTY",
    ),
    "settingsKeyboardLayoutUnknown": MessageLookupByLibrary.simpleMessage("未知"),
    "settingsKeyboardLayoutUnknownPrompt": MessageLookupByLibrary.simpleMessage(
      "目前鍵盤配置是自訂配置。選擇內建配置後，現有配置將被替換。",
    ),
    "settingsKeyboardWithReturn": MessageLookupByLibrary.simpleMessage(
      "輸出驗證碼後按 Enter",
    ),
    "settingsLanguage": MessageLookupByLibrary.simpleMessage("語言"),
    "settingsModel": MessageLookupByLibrary.simpleMessage("型號"),
    "settingsNDEF": MessageLookupByLibrary.simpleMessage("NFC 標籤模式"),
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
    "settingsResetApplet": m28,
    "settingsResetConditionNotSatisfying": MessageLookupByLibrary.simpleMessage(
      "目前 PIN 尚未鎖定，無法重置。",
    ),
    "settingsResetFailed": MessageLookupByLibrary.simpleMessage(
      "重置失敗，請檢查裝置連線後再試一次。",
    ),
    "settingsResetNDEF": MessageLookupByLibrary.simpleMessage("重置 NFC Tag"),
    "settingsResetOATH": MessageLookupByLibrary.simpleMessage("重置 OTP"),
    "settingsResetOpenPGP": MessageLookupByLibrary.simpleMessage("重置 OpenPGP"),
    "settingsResetPIV": MessageLookupByLibrary.simpleMessage("重置 PIV"),
    "settingsResetPass": MessageLookupByLibrary.simpleMessage("重置 Pass"),
    "settingsResetPresenceTestFailed": MessageLookupByLibrary.simpleMessage(
      "未及時觸碰 CanoKey。請再試一次，並在指示燈閃爍時觸碰。",
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
    "settingsWebUSB": MessageLookupByLibrary.simpleMessage("插入時顯示 WebUSB 提示"),
    "sm2AlgorithmId": MessageLookupByLibrary.simpleMessage("演算法 ID"),
    "sm2CurveId": MessageLookupByLibrary.simpleMessage("曲線 ID"),
    "sm2ReservedId": MessageLookupByLibrary.simpleMessage(
      "此 ID 已被其他演算法或曲線使用，請換一個值。",
    ),
    "soundCredit": MessageLookupByLibrary.simpleMessage(
      "NFC 互動音效由 Summer Xu 製作。",
    ),
    "storageFull": MessageLookupByLibrary.simpleMessage("CanoKey 儲存空間不足"),
    "successfullyChanged": MessageLookupByLibrary.simpleMessage("修改成功"),
    "validationAtLeastCharacters": m29,
    "validationAtMostCharacters": m30,
    "validationExactLength": m31,
    "validationHexString": MessageLookupByLibrary.simpleMessage("請輸入十六進位字串"),
    "validationNumber": MessageLookupByLibrary.simpleMessage("請輸入整數。"),
    "validationNumberMax": m32,
    "validationNumberMin": m33,
    "viewUserId": MessageLookupByLibrary.simpleMessage("檢視使用者 ID"),
    "warning": MessageLookupByLibrary.simpleMessage("警告"),
    "webAuthnCredentials": MessageLookupByLibrary.simpleMessage("WebAuthn 憑證"),
    "webAuthnDescription": MessageLookupByLibrary.simpleMessage(
      "管理儲存在 CanoKey 中的 WebAuthn 登入憑證。",
    ),
    "webAuthnMissingCredentials": MessageLookupByLibrary.simpleMessage(
      "為什麼看不到我的憑證？",
    ),
    "webAuthnMissingCredentialsExplanation":
        MessageLookupByLibrary.simpleMessage(
          "這裡只顯示 CanoKey 能直接列出的登入憑證。有些憑證需要網站發起登入才能辨識，無法在這裡列出，但仍可用於登入。",
        ),
    "webAuthnSearch": MessageLookupByLibrary.simpleMessage("搜尋 WebAuthn 憑證…"),
    "webPollCanoKeyPrompt": MessageLookupByLibrary.simpleMessage(
      "請將您的 CanoKey 插入 USB 連接埠並點選重新整理按鈕",
    ),
    "webauthnChangePinFailed": MessageLookupByLibrary.simpleMessage(
      "無法修改 WebAuthn PIN，請重新讀取 CanoKey 後再試一次。",
    ),
    "webauthnClientPinNotSupported": MessageLookupByLibrary.simpleMessage(
      "此 CanoKey 不支援設定 WebAuthn PIN。",
    ),
    "webauthnDelete": m34,
    "webauthnInputPinPrompt": MessageLookupByLibrary.simpleMessage(
      "請輸入您的 WebAuthn PIN。",
    ),
    "webauthnInputPinTitle": MessageLookupByLibrary.simpleMessage(
      "解鎖 WebAuthn",
    ),
    "webauthnPinAuthBlocked": MessageLookupByLibrary.simpleMessage(
      "WebAuthn PIN 已暫時鎖定。請重新插拔 CanoKey 後再試一次。",
    ),
    "webauthnPinBlocked": MessageLookupByLibrary.simpleMessage(
      "WebAuthn PIN 已鎖定，需要重置 WebAuthn 才能繼續使用。重置會刪除所有 WebAuthn 憑證。",
    ),
    "webauthnPinRequired": MessageLookupByLibrary.simpleMessage(
      "請先重新整理頁面並輸入 WebAuthn PIN，再重試此操作。",
    ),
    "webauthnSetPinFailed": MessageLookupByLibrary.simpleMessage(
      "無法設定 WebAuthn PIN，請重新讀取 CanoKey 後再試一次。",
    ),
    "webauthnSetPinPrompt": MessageLookupByLibrary.simpleMessage(
      "設定 WebAuthn PIN 後即可管理登入憑證。PIN 需要 4 至 63 個字元。",
    ),
    "webauthnSetPinTitle": MessageLookupByLibrary.simpleMessage(
      "設定 WebAuthn PIN",
    ),
  };
}
