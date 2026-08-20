package im.nfc.ccid

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.*
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.core.content.IntentCompat
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors


/** CcidPlugin */
class CcidPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var usbManager: UsbManager
    private lateinit var ioExecutor: ExecutorService
    private val mainHandler = Handler(Looper.getMainLooper())
    private var readers = mutableMapOf<String, Reader>()
    private val pendingConnections = mutableMapOf<ReaderId, PendingConnection>()
    private val pendingTransceives = mutableSetOf<PendingTransceive>()
    private var nextPermissionRequestCode = 0
    private var receiverRegistered = false

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_USB_PERMISSION) {
                val device = IntentCompat.getParcelableExtra(
                    intent, UsbManager.EXTRA_DEVICE, UsbDevice::class.java
                )
                val deviceName = intent.getStringExtra(EXTRA_DEVICE_NAME)
                val interfaceIdx = intent.getIntExtra(EXTRA_INTERFACE_INDEX, -1)
                if (deviceName == null || interfaceIdx < 0) {
                    Log.e(TAG, "Reader identity missing from permission result")
                    return
                }
                val readerId = ReaderId(deviceName, interfaceIdx)
                val pendingConnection = pendingConnections[readerId]
                if (pendingConnection == null) {
                    Log.d(TAG, "Ignoring stale USB permission result for $readerId")
                    return
                }
                if (device == null || device.deviceName != deviceName) {
                    pendingConnections.remove(readerId)
                    pendingConnection.result.error(
                        "CCID_READER_NOT_FOUND",
                        "Reader not found",
                        null
                    )
                    return
                }
                val readerEntry = readers.entries.firstOrNull { it.value.id == readerId }
                if (readerEntry == null) {
                    pendingConnections.remove(readerId)
                    pendingConnection.result.error(
                        "CCID_READER_NOT_FOUND",
                        "Reader not found",
                        null
                    )
                    return
                }
                if (!intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                    pendingConnections.remove(readerId)
                    Log.d(TAG, "permission denied for device $device")
                    pendingConnection.result.error(
                        "CCID_USB_PERMISSION_DENIED",
                        "USB permission denied",
                        null
                    )
                    return
                }

                startConnection(readerEntry.value, device, pendingConnection)
            }
            if (intent.action == UsbManager.ACTION_USB_DEVICE_DETACHED) {
                val device = IntentCompat.getParcelableExtra(
                    intent, UsbManager.EXTRA_DEVICE, UsbDevice::class.java
                )
                device?.let { detachedDevice ->
                    pendingConnections.keys
                        .filter { it.deviceName == detachedDevice.deviceName }
                        .forEach { readerId ->
                            pendingConnections.remove(readerId)?.result?.error(
                                "CCID_READER_NOT_FOUND", "Reader disconnected", null
                            )
                        }
                    cancelTransceives(
                        { it.deviceName == detachedDevice.deviceName },
                        "CCID_READER_NOT_FOUND",
                        "Reader disconnected"
                    )
                    readers.values
                        .filter { it.deviceName == detachedDevice.deviceName }
                        .mapNotNull { it.ccid }
                        .forEach { ccid -> ioExecutor.execute { ccid.close() } }
                    readers.entries.removeIf { (_, reader) ->
                        reader.deviceName == detachedDevice.deviceName
                    }
                    Log.d(TAG, "USB device detached: $detachedDevice")
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
        ioExecutor = Executors.newSingleThreadExecutor()
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ccid")
        channel.setMethodCallHandler(this)

        val filter = IntentFilter(ACTION_USB_PERMISSION).apply {
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        ContextCompat.registerReceiver(
            context, usbReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED
        )
        receiverRegistered = true
    }

    @OptIn(ExperimentalStdlibApi::class)
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "listReaders" -> {
                try {
                    result.success(listReaders())
                } catch (error: Exception) {
                    result.error("CCID_LIST_READERS_ERROR", error.message, null)
                }
            }

            "connect" -> {
                val name = call.arguments as? String
                if (name == null) {
                    result.error("CCID_INVALID_ARGUMENT", "Reader name is required", null)
                    return
                }
                connect(name, result)
            }

            "transceive" -> {
                val name = call.argument<String>("reader")
                val capdu = call.argument<String>("capdu")
                if (name == null || capdu == null || !capdu.isValidHex()) {
                    result.error("CCID_INVALID_ARGUMENT", "A valid reader and CAPDU are required", null)
                    return
                }
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
                val pendingTransceive = PendingTransceive(reader.id, result)
                pendingTransceives.add(pendingTransceive)
                ioExecutor.execute {
                    val response = try {
                        ccid.xfrBlock(capdu.hexToByteArray()).toHexString()
                    } catch (error: Exception) {
                        Log.e(TAG, "Failed to transceive", error)
                        error
                    }
                    mainHandler.post {
                        if (!pendingTransceives.remove(pendingTransceive)) return@post
                        if (response is String) {
                            result.success(response)
                        } else {
                            val error = response as Exception
                            result.error(
                                "CCID_TRANSCEIVE_ERROR",
                                error.message ?: "Failed to transceive",
                                null
                            )
                        }
                    }
                }
            }

            "disconnect" -> {
                val name = call.arguments as? String
                if (name == null) {
                    result.error("CCID_INVALID_ARGUMENT", "Reader name is required", null)
                    return
                }
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
                cancelTransceives(
                    { it == reader.id },
                    "CCID_READER_DISCONNECTED",
                    "Reader disconnected"
                )
                reader.ccid?.let { ccid -> ioExecutor.execute { ccid.close() } }
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
        if (receiverRegistered) {
            context.unregisterReceiver(usbReceiver)
            receiverRegistered = false
        }
        pendingConnections.values.forEach {
            it.result.error("CCID_PLUGIN_DETACHED", "CCID plugin was detached", null)
        }
        pendingConnections.clear()
        pendingTransceives.forEach {
            it.result.error("CCID_PLUGIN_DETACHED", "CCID plugin was detached", null)
        }
        pendingTransceives.clear()
        readers.values.mapNotNull { it.ccid }.forEach { ccid ->
            ioExecutor.execute { ccid.close() }
        }
        readers.clear()
        ioExecutor.shutdown()
    }

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
            .mapNotNull { it.ccid }
            .forEach { ccid -> ioExecutor.execute { ccid.close() } }
        pendingConnections.keys
            .filter { it !in newReaderIds }
            .forEach { readerId ->
                pendingConnections.remove(readerId)?.result?.error(
                    "CCID_READER_NOT_FOUND", "Reader disconnected", null
                )
            }
        cancelTransceives(
            { it !in newReaderIds },
            "CCID_READER_NOT_FOUND",
            "Reader disconnected"
        )

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
            val pendingConnection = PendingConnection(result)
            pendingConnections[reader.id] = pendingConnection
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
                pendingConnections.remove(reader.id, pendingConnection)
                Log.e(TAG, "Failed to request USB permission", error)
                result.error(
                    "CCID_USB_PERMISSION_ERROR",
                    error.message ?: "Failed to request USB permission",
                    null
                )
            }
            return
        } else {
            val pendingConnection = PendingConnection(result)
            pendingConnections[reader.id] = pendingConnection
            startConnection(reader, device, pendingConnection)
        }
    }

    private fun startConnection(
        reader: Reader,
        device: UsbDevice,
        pendingConnection: PendingConnection
    ) {
        if (!pendingConnection.markStarted()) return
        ioExecutor.execute {
            var ccid: Ccid? = null
            var connectionError: Exception? = null
            try {
                ccid = connectToInterface(device, reader.interfaceIdx)
            } catch (error: Exception) {
                Log.e(TAG, "Failed to connect", error)
                connectionError = error
            }

            mainHandler.post {
                if (!pendingConnections.remove(reader.id, pendingConnection)) {
                    ccid?.close()
                    return@post
                }
                val readerEntry = readers.entries.firstOrNull { it.value.id == reader.id }
                if (readerEntry == null) {
                    ccid?.close()
                    pendingConnection.result.error(
                        "CCID_READER_NOT_FOUND", "Reader disconnected", null
                    )
                    return@post
                }
                if (ccid != null) {
                    readers[readerEntry.key] = readerEntry.value.copy(ccid = ccid)
                    pendingConnection.result.success(null)
                } else {
                    pendingConnection.result.error(
                        "CCID_READER_CONNECT_ERROR",
                        connectionError?.message ?: "Failed to connect",
                        null
                    )
                }
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
        val endpoints: Pair<UsbEndpoint, UsbEndpoint>
        try {
            endpoints = getEndpoints(usbInterface)
        } catch (error: Exception) {
            usbConnection.close()
            throw error
        }
        if (!usbConnection.claimInterface(usbInterface, true)) {
            Log.e(TAG, "Failed to claim interface")
            usbConnection.close()
            return null
        }
        val ccid = Ccid(
            usbConnection, usbInterface, endpoints.first, endpoints.second
        )
        try {
            val descriptor = ccid.getDescriptor(usbInterface.id)
            if (descriptor?.supportsProtocol(Protocol.T1) != true) {
                Log.d(TAG, "Unsupported protocol")
                ccid.close()
                return null
            }
            val atr = ccid.iccPowerOn()
            Log.d(TAG, "ATR: ${atr.toHexString()}")
            return ccid
        } catch (error: Exception) {
            ccid.close()
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

    private fun String.isValidHex(): Boolean {
        return isNotEmpty() && length % 2 == 0 && all { it.isDigit() || it.lowercaseChar() in 'a'..'f' }
    }

    private fun cancelTransceives(
        predicate: (ReaderId) -> Boolean,
        code: String,
        message: String
    ) {
        pendingTransceives.filter { predicate(it.readerId) }.forEach { pending ->
            if (pendingTransceives.remove(pending)) {
                pending.result.error(code, message, null)
            }
        }
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

    private class PendingConnection(val result: Result) {
        private var started = false

        fun markStarted(): Boolean {
            if (started) return false
            started = true
            return true
        }
    }

    private data class PendingTransceive(val readerId: ReaderId, val result: Result)
}
