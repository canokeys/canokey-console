package im.nfc.ccid

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.*
import android.os.Build
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** CcidPlugin */
class CcidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var usbManager: UsbManager
    private var readers = mutableMapOf<String, Reader>()
    private val pendingConnections = mutableMapOf<ReaderId, PendingConnection>()
    private var nextPermissionRequestCode = 0

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_USB_PERMISSION) {
                synchronized(this) {
                    val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    val deviceName = intent.getStringExtra(EXTRA_DEVICE_NAME)
                    val interfaceIdx = intent.getIntExtra(EXTRA_INTERFACE_INDEX, -1)
                    if (deviceName == null || interfaceIdx < 0) {
                        Log.e(TAG, "Reader identity missing from permission result")
                        return
                    }
                    val readerId = ReaderId(deviceName, interfaceIdx)
                    val pendingConnection = pendingConnections.remove(readerId)
                    if (pendingConnection == null) {
                        Log.d(TAG, "Ignoring stale USB permission result for $readerId")
                        return
                    }
                    if (device == null || device.deviceName != deviceName) {
                        pendingConnection.result.error(
                            "CCID_READER_NOT_FOUND",
                            "Reader not found",
                            null
                        )
                        return
                    }
                    val readerEntry = readers.entries.firstOrNull { it.value.id == readerId }
                    if (readerEntry == null) {
                        pendingConnection.result.error(
                            "CCID_READER_NOT_FOUND",
                            "Reader not found",
                            null
                        )
                        return
                    }
                    if (!intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        Log.d(TAG, "permission denied for device $device")
                        pendingConnection.result.error(
                            "CCID_USB_PERMISSION_DENIED",
                            "USB permission denied",
                            null
                        )
                        return
                    }

                    val reader = readerEntry.value
                    val ccid = try {
                        connectToInterface(device, reader.interfaceIdx)
                    } catch (error: Exception) {
                        Log.e(TAG, "Failed to connect", error)
                        pendingConnection.result.error(
                            "CCID_READER_CONNECT_ERROR",
                            error.message ?: "Failed to connect",
                            null
                        )
                        return
                    }
                    readers[readerEntry.key] = reader.copy(ccid = ccid)
                    if (ccid != null) {
                        pendingConnection.result.success(null)
                    } else {
                        pendingConnection.result.error(
                            "CCID_READER_CONNECT_ERROR",
                            "Failed to connect",
                            null
                        )
                    }
                }
            }
            if (intent.action == UsbManager.ACTION_USB_DEVICE_DETACHED) {
                synchronized(this) {
                    val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    device?.let { detachedDevice ->
                        pendingConnections.keys
                            .filter { it.deviceName == detachedDevice.deviceName }
                            .forEach { readerId ->
                                pendingConnections.remove(readerId)?.result?.error(
                                    "CCID_READER_NOT_FOUND", "Reader disconnected", null
                                )
                            }
                        readers.values
                            .filter { it.deviceName == detachedDevice.deviceName }
                            .forEach { it.ccid?.close() }
                        readers.entries.removeIf { (_, reader) ->
                            reader.deviceName == detachedDevice.deviceName
                        }
                        Log.d(TAG, "USB device detached: $detachedDevice")
                    }
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ccid")
        channel.setMethodCallHandler(this)
    }

    @OptIn(ExperimentalStdlibApi::class)
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "listReaders" -> {
                result.success(listReaders())
            }

            "connect" -> {
                val name = call.arguments as String
                connect(name, result)
            }

            "transceive" -> {
                val name = call.argument<String>("reader")!!
                val capdu = call.argument<String>("capdu")!!
                val reader = readers[name]
                if (reader == null) {
                    result.error("CCID_READER_NOT_FOUND", "Reader not found", null)
                    return
                }
                val ccid = reader.ccid
                if (ccid == null) {
                    result.error("CCID_READER_NOT_CONNECTED", "Reader not connected", null)
                    return
                }
                val resp = ccid.xfrBlock(capdu.hexToByteArray())
                result.success(resp.toHexString())
            }

            "disconnect" -> {
                val name = call.arguments as String
                val reader = readers[name]
                if (reader == null) {
                    result.error("CCID_READER_NOT_FOUND", "Reader not found", null)
                    return
                }
                pendingConnections.remove(reader.id)?.result?.error(
                    "CCID_READER_CONNECT_CANCELLED",
                    "Connection cancelled",
                    null
                )
                reader.ccid?.close()
                readers[name] = reader.copy(ccid = null)
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        context = binding.activity.applicationContext
        usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(
                usbReceiver, IntentFilter(ACTION_USB_PERMISSION), Context.RECEIVER_EXPORTED
            )
        } else {
            context.registerReceiver(usbReceiver, IntentFilter(ACTION_USB_PERMISSION))
        }
        context.registerReceiver(usbReceiver, IntentFilter(UsbManager.ACTION_USB_DEVICE_DETACHED))
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}

    private fun listReaders(): List<String> {
        val readerTree = mutableMapOf<String, MutableList<Reader>>()
        val newReaders = mutableMapOf<String, Reader>()
        val existingReadersById = readers.values.associateBy { it.id }

        usbManager.deviceList.values.forEach { device ->
            (0 until device.interfaceCount).forEach { i ->
                val usbInterface = device.getInterface(i)
                if (usbInterface.interfaceClass == UsbConstants.USB_CLASS_CSCID) {
                    val displayName = getDisplayName(device, usbInterface)
                    val reader = Reader(device.deviceName, i, null)
                    readerTree.getOrPut(displayName) { mutableListOf() }.add(reader)
                }
            }
        }

        readerTree.forEach { (name, list) ->
            if (list.size > 1) {
                list.forEachIndexed { index, reader ->
                    newReaders["$name (${index + 1})"] = reader
                }
            } else {
                newReaders[name] = list[0]
            }
        }

        newReaders.forEach { (name, reader) ->
            existingReadersById[reader.id]?.let { existingReader ->
                newReaders[name] = reader.copy(ccid = existingReader.ccid)
            }
        }

        val newReaderIds = newReaders.values.mapTo(mutableSetOf()) { it.id }
        readers.values
            .filter { it.id !in newReaderIds }
            .forEach { it.ccid?.close() }
        pendingConnections.keys
            .filter { it !in newReaderIds }
            .forEach { readerId ->
                pendingConnections.remove(readerId)?.result?.error(
                    "CCID_READER_NOT_FOUND", "Reader disconnected", null
                )
            }

        readers = newReaders
        return readers.keys.toList()
    }

    private fun connect(name: String, result: Result) {
        val reader = readers[name]
        if (reader == null) {
            result.error("CCID_READER_NOT_FOUND", "Reader not found", null)
            return
        }
        val device =
            usbManager.deviceList.filter { it.key == reader.deviceName }.values.firstOrNull()
        if (device == null) {
            result.error("CCID_READER_NOT_FOUND", "Reader not found", null)
            return
        }

        if (reader.ccid != null) {
            result.error("CCID_READER_ALREADY_CONNECTED", "Reader already connected", null)
            return
        }

        if (pendingConnections.containsKey(reader.id)) {
            result.error("CCID_READER_CONNECT_IN_PROGRESS", "Connection already in progress", null)
            return
        }

        if (!usbManager.hasPermission(device)) {
            // Request permission
            pendingConnections[reader.id] = PendingConnection(result)
            val intent = Intent(ACTION_USB_PERMISSION)
            intent.putExtra(EXTRA_DEVICE_NAME, reader.deviceName)
            intent.putExtra(EXTRA_INTERFACE_INDEX, reader.interfaceIdx)
            intent.setPackage(context.packageName)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                nextPermissionRequestCode++,
                intent,
                PendingIntent.FLAG_ONE_SHOT or
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            PendingIntent.FLAG_MUTABLE
                        } else {
                            0
                        }
            )
            try {
                usbManager.requestPermission(device, pendingIntent)
            } catch (error: Exception) {
                pendingConnections.remove(reader.id)
                Log.e(TAG, "Failed to request USB permission", error)
                result.error(
                    "CCID_USB_PERMISSION_ERROR",
                    error.message ?: "Failed to request USB permission",
                    null
                )
            }
            return
        } else {
            val ccid = try {
                connectToInterface(device, reader.interfaceIdx)
            } catch (error: Exception) {
                Log.e(TAG, "Failed to connect", error)
                result.error(
                    "CCID_READER_CONNECT_ERROR",
                    error.message ?: "Failed to connect",
                    null
                )
                return
            }
            if (ccid != null) {
                readers[name] = reader.copy(ccid = ccid)
                result.success(null)
            } else {
                result.error("CCID_READER_CONNECT_ERROR", "Failed to connect", null)
            }
        }
    }

    @OptIn(ExperimentalStdlibApi::class)
    private fun connectToInterface(device: UsbDevice, interfaceIdx: Int): Ccid? {
        val usbInterface = device.getInterface(interfaceIdx)
        val usbConnection = usbManager.openDevice(device)
        if (usbConnection == null) {
            Log.e(TAG, "Failed to open device")
            return null
        }
        var ccid: Ccid? = null
        try {
            val endpoints = getEndpoints(usbInterface)
            val activeCcid = Ccid(
                usbConnection, usbInterface, endpoints.first, endpoints.second
            )
            ccid = activeCcid
            val descriptor = activeCcid.getDescriptor(interfaceIdx)
            if (descriptor?.supportsProtocol(Protocol.T1) != true) {
                Log.d(TAG, "Unsupported protocol")
                activeCcid.close()
                return null
            }
            if (!usbConnection.claimInterface(usbInterface, true)) {
                Log.e(TAG, "Failed to claim interface")
                activeCcid.close()
                return null
            }
            val atr = activeCcid.iccPowerOn()
            Log.d(TAG, "ATR: ${atr.toHexString()}")
            return activeCcid
        } catch (error: Exception) {
            if (ccid == null) {
                usbConnection.close()
            } else {
                ccid.close()
            }
            throw error
        }
    }

    private fun getEndpoints(usbInterface: UsbInterface): Pair<UsbEndpoint, UsbEndpoint> {
        var bulkIn: UsbEndpoint? = null
        var bulkOut: UsbEndpoint? = null
        for (i in 0 until usbInterface.endpointCount) {
            val endpoint = usbInterface.getEndpoint(i)
            if (endpoint.type == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                if (endpoint.direction == UsbConstants.USB_DIR_IN) {
                    bulkIn = endpoint
                } else {
                    bulkOut = endpoint
                }
            }
        }
        if (bulkIn == null || bulkOut == null) {
            throw Exception("Bulk endpoints not found")
        }
        return Pair(bulkIn, bulkOut)
    }

    private fun getDisplayName(device: UsbDevice, usbInterface: UsbInterface): String {
        val nameParts = mutableListOf<String>()
        if (device.productName != null) {
            nameParts.add(device.productName!!)
        } else {
            nameParts.add("Unknown")
        }

        if (usbInterface.name != null) {
            nameParts.add(usbInterface.name!!)
        } else {
            nameParts.add("CCID")
        }

        return nameParts.joinToString(" ")
    }

    companion object {
        private val TAG = FlutterPlugin::class.java.name
        private const val ACTION_USB_PERMISSION = "im.nfc.ccid.USB_PERMISSION"
        private const val EXTRA_DEVICE_NAME = "deviceName"
        private const val EXTRA_INTERFACE_INDEX = "interfaceIdx"
    }

    private data class Reader(
        val deviceName: String,
        val interfaceIdx: Int,
        val ccid: Ccid?
    ) {
        val id: ReaderId
            get() = ReaderId(deviceName, interfaceIdx)
    }

    private data class ReaderId(val deviceName: String, val interfaceIdx: Int)

    private data class PendingConnection(val result: Result)
}
