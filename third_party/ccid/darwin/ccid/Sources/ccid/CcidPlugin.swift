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
    private final class TransceiveCompletion {
        private var completed = false
        private let result: FlutterResult

        init(result: @escaping FlutterResult) {
            self.result = result
        }

        var isCompleted: Bool {
            return completed
        }

        func complete(_ response: Any?) {
            guard !completed else { return }
            completed = true
            result(response)
        }
    }

    private struct PendingTransceive {
        let generation: Int
        let card: TKSmartCard
        let completion: TransceiveCompletion
        let run: () -> Void
    }

    var cards: [String: TKSmartCard] = [:]
    private var pendingTransceives: [String: [PendingTransceive]] = [:]
    private var activeTransceives: [String: PendingTransceive] = [:]
    private var connectionGenerations: [String: Int] = [:]

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
                    resetTransceives(reader: reader, message: "Card was reconnected")
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
            let generation = connectionGenerations[reader, default: 0]
            let completion = TransceiveCompletion(result: result)
            let transceive = PendingTransceive(
                generation: generation,
                card: card,
                completion: completion,
                run: {
                    func finish(_ response: Any?) {
                        DispatchQueue.main.async {
                            card.endSession()
                            completion.complete(response)
                            self.finishTransceive(reader: reader, generation: generation)
                        }
                    }

                    card.beginSession { (success, error) in
                        DispatchQueue.main.async {
                            guard !completion.isCompleted else {
                                if success {
                                    card.endSession()
                                }
                                return
                            }
                            if !success {
                                completion.complete(
                                    FlutterError(code: "BEGIN_SESSION_ERROR", message: error?.localizedDescription, details: nil)
                                )
                                self.finishTransceive(reader: reader, generation: generation)
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
                    }
                }
            )
            enqueueTransceive(reader: reader, transceive: transceive)

        case "disconnect":
            let reader = call.arguments as! String
            cards.removeValue(forKey: reader)
            resetTransceives(reader: reader, message: "Card was disconnected")
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func enqueueTransceive(
        reader: String,
        transceive: PendingTransceive
    ) {
        pendingTransceives[reader, default: []].append(transceive)
        if activeTransceives[reader] == nil {
            startNextTransceive(reader: reader)
        }
    }

    private func startNextTransceive(reader: String) {
        guard activeTransceives[reader] == nil else { return }
        guard var queue = pendingTransceives[reader], !queue.isEmpty else {
            return
        }

        let transceive = queue.removeFirst()
        if queue.isEmpty {
            pendingTransceives.removeValue(forKey: reader)
        } else {
            pendingTransceives[reader] = queue
        }
        guard transceive.generation == connectionGenerations[reader, default: 0] else {
            transceive.completion.complete(
                FlutterError(code: "NO_CARD", message: "Card connection changed", details: nil)
            )
            startNextTransceive(reader: reader)
            return
        }
        activeTransceives[reader] = transceive
        transceive.run()
    }

    private func finishTransceive(reader: String, generation: Int) {
        guard activeTransceives[reader]?.generation == generation else { return }
        activeTransceives.removeValue(forKey: reader)
        startNextTransceive(reader: reader)
    }

    private func resetTransceives(reader: String, message: String) {
        connectionGenerations[reader, default: 0] += 1
        let error = FlutterError(code: "NO_CARD", message: message, details: nil)

        let cancelledTransceives = pendingTransceives.removeValue(forKey: reader) ?? []
        cancelledTransceives.forEach { $0.completion.complete(error) }

        if let activeTransceive = activeTransceives.removeValue(forKey: reader) {
            activeTransceive.card.endSession()
            activeTransceive.completion.complete(error)
        }
    }
}
