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

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_USB_PERMISSION) {
                synchronized(this) {
                    val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        device?.apply {
                            val reader = readers[intent.getStringExtra("name")]
                            if (reader == null) {
                                Log.e(TAG, "Reader not found")
                                return
                            }
                            val ccid = connectToInterface(device, reader.interfaceIdx)
                            if (ccid != null) {
                                readers[reader.name] = reader.copy(ccid = ccid, result = null)
                                reader.result!!.success(null)
                            } else {
                                reader.result!!.error(
                                    "CCID_READER_CONNECT_ERROR",
                                    "Failed to connect",
                                    null
                                )
                            }
                        }
                    } else {
                        Log.d(TAG, "permission denied for device $device")
                    }
                }
            }
            if (intent.action == UsbManager.ACTION_USB_DEVICE_DETACHED) {
                synchronized(this) {
                    val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    device?.let { detachedDevice ->
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
                readers[name] = reader.copy(ccid = null)
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

        usbManager.deviceList.values.forEach { device ->
            (0 until device.interfaceCount).forEach { i ->
                val usbInterface = device.getInterface(i)
                if (usbInterface.interfaceClass == UsbConstants.USB_CLASS_CSCID) {
                    val displayName = getDisplayName(device, usbInterface)
                    val reader = Reader(displayName, device.deviceName, i, null, null)
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

        newReaders.forEach { (name, _) ->
            if (readers.containsKey(name)) {
                newReaders[name] = readers[name]!!
            }
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

        if (!usbManager.hasPermission(device)) {
            // Request permission
            readers[name] = reader.copy(result = result)
            val intent = Intent(ACTION_USB_PERMISSION)
            intent.putExtra("name", name)
            intent.setPackage(context.packageName)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
            )
            usbManager.requestPermission(device, pendingIntent)
            return
        } else {
            val ccid = connectToInterface(device, reader.interfaceIdx)
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
        val endpoints = getEndpoints(usbInterface)
        val ccid = Ccid(usbConnection, endpoints.first, endpoints.second)
        val descriptor = ccid.getDescriptor(interfaceIdx)
        if (descriptor?.supportsProtocol(Protocol.T1) != true) {
            Log.d(TAG, "Unsupported protocol")
            return null
        }
        if (!usbConnection.claimInterface(usbInterface, true)) {
            Log.e(TAG, "Failed to claim interface")
            return null
        }
        val atr = ccid.iccPowerOn()
        Log.d(TAG, "ATR: ${atr.toHexString()}")
        return ccid
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
    }

    private data class Reader(
        val name: String,
        val deviceName: String,
        val interfaceIdx: Int,
        val ccid: Ccid?,
        val result: Result?
    )
}
