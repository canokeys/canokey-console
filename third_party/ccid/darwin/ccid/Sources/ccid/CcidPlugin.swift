#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif
import CryptoTokenKit

extension String {
    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }

        guard data.count > 0 else { return nil }

        return data
    }
}

extension Data {
    var hexadecimal: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

public class CcidPlugin: NSObject, FlutterPlugin {
    private struct PendingTransceive {
        let run: () -> Void
        let cancel: () -> Void
    }

    var cards: [String: TKSmartCard] = [:]
    private var pendingTransceives: [String: [PendingTransceive]] = [:]
    private var activeTransceiveReaders: Set<String> = []

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(name: "ccid", binaryMessenger: messenger)
        let instance = CcidPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listReaders":
            let manager = TKSmartCardSlotManager.default
            result(manager?.slotNames ?? [])

        case "connect":
            let reader = call.arguments as! String
            let manager = TKSmartCardSlotManager.default
            if let slot = manager?.slotNamed(reader) {
                if let card = slot.makeSmartCard() {
                    cards[reader] = card
                    result(nil)
                } else {
                    result(FlutterError(code: "NO_CARD", message: "Failed to find a card", details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_READER", message: "Invalid reader name", details: nil))
            }

        case "transceive":
            let args = call.arguments as! [String: Any?]
            let reader = args["reader"] as! String
            let capdu = args["capdu"] as! String
            let capduData = capdu.hexadecimal!
            guard let card = cards[reader] else {
                result(FlutterError(code: "NO_CARD", message: "Card is not connected", details: nil))
                return
            }
            enqueueTransceive(
                reader: reader,
                run: {
                    func finish(_ response: Any?) {
                        card.endSession()
                        DispatchQueue.main.async {
                            result(response)
                            self.startNextTransceive(reader: reader)
                        }
                    }

                    card.beginSession { (success, error) in
                        if !success {
                            DispatchQueue.main.async {
                                result(FlutterError(code: "BEGIN_SESSION_ERROR", message: error?.localizedDescription, details: nil))
                                self.startNextTransceive(reader: reader)
                            }
                            return
                        }
                        card.transmit(capduData) { (rapdu, error) in
                            if let rapdu = rapdu {
                                finish(rapdu.hexadecimal)
                            } else {
                                finish(FlutterError(code: "TRANSMIT_ERROR", message: error?.localizedDescription, details: nil))
                            }
                        }
                    }
                },
                cancel: {
                    result(FlutterError(code: "NO_CARD", message: "Card was disconnected", details: nil))
                }
            )

        case "disconnect":
            let reader = call.arguments as! String
            cards.removeValue(forKey: reader)
            let cancelledTransceives = pendingTransceives.removeValue(forKey: reader) ?? []
            cancelledTransceives.forEach { $0.cancel() }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func enqueueTransceive(
        reader: String,
        run: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) {
        pendingTransceives[reader, default: []].append(
            PendingTransceive(run: run, cancel: cancel)
        )
        if !activeTransceiveReaders.contains(reader) {
            startNextTransceive(reader: reader)
        }
    }

    private func startNextTransceive(reader: String) {
        guard var queue = pendingTransceives[reader], !queue.isEmpty else {
            activeTransceiveReaders.remove(reader)
            return
        }

        activeTransceiveReaders.insert(reader)
        let transceive = queue.removeFirst()
        if queue.isEmpty {
            pendingTransceives.removeValue(forKey: reader)
        } else {
            pendingTransceives[reader] = queue
        }
        transceive.run()
    }
}
