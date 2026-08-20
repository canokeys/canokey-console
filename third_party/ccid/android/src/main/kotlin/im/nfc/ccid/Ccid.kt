package im.nfc.ccid

import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface

class Ccid(
    private val usbDeviceConnection: UsbDeviceConnection,
    private val usbInterface: UsbInterface,
    private val bulkIn: UsbEndpoint,
    private val bulkOut: UsbEndpoint
) {
    private var currentSeq = 0.toByte()
    private var closed = false

    fun iccPowerOn(): ByteArray {
        val seq = currentSeq++
        val command = byteArrayOf(
            MESSAGE_TYPE_PC_TO_RDR_ICCPOWERON,
            0x00, 0x00, 0x00, 0x00,
            0x00,
            seq,
            0x00, // Auto voltage selection
            0x00, 0x00
        )
        sendCcidPcToRdrMessage(command)
        val response = receiveCcidRdrToPcMessage(seq)
        return response.data
    }

    fun iccPowerOff() {
        val seq = currentSeq++
        val command = byteArrayOf(
            MESSAGE_TYPE_PC_TO_RDR_ICCPOWEROFF,
            0x00, 0x00, 0x00, 0x00,
            0x00,
            seq,
            0x00, 0x00, 0x00
        )
        sendCcidPcToRdrMessage(command)
    }

    @Synchronized
    fun close() {
        if (closed) return
        closed = true
        usbDeviceConnection.releaseInterface(usbInterface)
        usbDeviceConnection.close()
    }

    @Synchronized
    fun xfrBlock(apdu: ByteArray): ByteArray {
        if (closed) throw CcidException("Reader is closed")
        val seq = currentSeq++
        val command = byteArrayOf(
            MESSAGE_TYPE_PC_TO_RDR_XFRBLOCK,
            apdu.size.toByte(),
            (apdu.size shr 8).toByte(),
            (apdu.size shr 16).toByte(),
            (apdu.size shr 24).toByte(),
            0x00,
            seq,
            0x00,
            0x00,
            0x00
        )
        val data = command + apdu

        var bytesSent = 0
        while (bytesSent < data.size) {
            val chunkSize = minOf(data.size - bytesSent, bulkOut.maxPacketSize)
            val chunk = data.copyOfRange(bytesSent, bytesSent + chunkSize)
            sendCcidPcToRdrMessage(chunk)
            bytesSent += chunkSize
        }

        return receiveCcidRdrToPcMessage(seq).data
    }


    fun getDescriptor(interfaceNumber: Int): CcidDescriptor? {
        val rawDescriptors = usbDeviceConnection.rawDescriptors
        var byteIndex = 0
        var currInterfaceNumber = 0

        while (byteIndex + 1 < rawDescriptors.size) {
            val descriptorLength = rawDescriptors[byteIndex].toInt() and 0xff
            val descriptorType = rawDescriptors[byteIndex + 1].toInt() and 0xff
            if (descriptorLength < 2 || byteIndex + descriptorLength > rawDescriptors.size) {
                throw CcidException("Invalid USB descriptor length")
            }

            // Check if it's an interface descriptor
            if (descriptorType == 0x04) {
                if (descriptorLength < 3) {
                    throw CcidException("Invalid interface descriptor")
                }
                currInterfaceNumber = rawDescriptors[byteIndex + 2].toInt() and 0xff
            }
            // Check if it's a CCID class descriptor and the interface number matches
            else if (descriptorType == 0x21 && currInterfaceNumber == interfaceNumber) {
                if (descriptorLength < CCID_DESCRIPTOR_MIN_LENGTH) {
                    throw CcidException("Invalid CCID descriptor")
                }
                val dwProtocols = (rawDescriptors[byteIndex + 6].toInt() and 0xff) or
                        ((rawDescriptors[byteIndex + 7].toInt() and 0xff) shl 8) or
                        ((rawDescriptors[byteIndex + 8].toInt() and 0xff) shl 16) or
                        ((rawDescriptors[byteIndex + 9].toInt() and 0xff) shl 24)
                val dwFeatures = (rawDescriptors[byteIndex + 40].toInt() and 0xff) or
                        ((rawDescriptors[byteIndex + 41].toInt() and 0xff) shl 8) or
                        ((rawDescriptors[byteIndex + 42].toInt() and 0xff) shl 16) or
                        ((rawDescriptors[byteIndex + 43].toInt() and 0xff) shl 24)
                val dwMaxIFSD = (rawDescriptors[byteIndex + 28].toInt() and 0xff) or
                        ((rawDescriptors[byteIndex + 29].toInt() and 0xff) shl 8) or
                        ((rawDescriptors[byteIndex + 30].toInt() and 0xff) shl 16) or
                        ((rawDescriptors[byteIndex + 31].toInt() and 0xff) shl 24)
                val levelOfExchange = when ((dwFeatures shr 16) and 0xFF) {
                    0x01 -> LevelOfExchange.TPDU
                    0x02 -> LevelOfExchange.ShortAPDU
                    0x04 -> LevelOfExchange.ExtendedAPDU
                    else -> throw CcidException("Unknown level of exchange")
                }
                return CcidDescriptor(dwProtocols.toByte(), levelOfExchange, dwMaxIFSD)
            }

            byteIndex += descriptorLength
        }

        return null
    }

    private fun sendCcidPcToRdrMessage(message: ByteArray) {
        val transmitted = usbDeviceConnection.bulkTransfer(bulkOut, message, message.size, 1000)
        if (transmitted != message.size) {
            throw CcidException("Failed to transmit data ($transmitted / ${message.size})")
        }
    }

    private fun receiveCcidRdrToPcMessage(expectedSeq: Byte): CcidRdrToPcMessage {
        var message: CcidRdrToPcMessage
        do {
            message = receiveRawMessage(expectedSeq)
        } while (message.isStatusTimeoutExtensionRequest)

        if (!message.isStatusSuccess) {
            throw CcidException("Card error: ${message.iccStatus}")
        }

        return message
    }

    private fun receiveRawMessage(expectedSeq: Byte): CcidRdrToPcMessage {
        var retries = 3
        var bytesRead = 0
        var message: CcidRdrToPcMessage? = null
        val buffer = ByteArray(bulkIn.maxPacketSize)
        var lastException: CcidException? = null
        while (retries > 0) {
            try {
                bytesRead = usbDeviceConnection.bulkTransfer(bulkIn, buffer, buffer.size, USB_TIMEOUT)
                if (bytesRead <= 0) {
                    throw CcidException("Failed to read data")
                }
                if (bytesRead < HEADER_SIZE) {
                    throw CcidException("Incorrect header")
                }
                if (buffer[0] != MESSAGE_TYPE_RDR_TO_PC_DATABLOCK) {
                    throw CcidException("Unexpected message type")
                }
                message = CcidRdrToPcMessage.parseHeader(buffer)
                if (message.seq != expectedSeq) {
                    throw CcidException("Unexpected sequence number ${message.seq}, expected $expectedSeq")
                }
                lastException = null
                break
            } catch (e: CcidException) {
                lastException = e
                retries--
                if (retries > 0) {
                    Thread.sleep(100)
                }
            }
        }

        if (lastException != null) {
            throw lastException
        }

        val response = message ?: throw CcidException("Missing response header")
        val dataBuffer = ByteArray(response.length)
        var bytesBuffered = bytesRead - HEADER_SIZE
        if (bytesBuffered > response.length) {
            throw CcidException("Response exceeds declared length")
        }
        System.arraycopy(buffer, HEADER_SIZE, dataBuffer, 0, bytesBuffered)

        while (bytesBuffered < response.length) {
            val remaining = response.length - bytesBuffered
            bytesRead = usbDeviceConnection.bulkTransfer(
                bulkIn, buffer, minOf(buffer.size, remaining), USB_TIMEOUT
            )
            if (bytesRead <= 0) {
                throw CcidException("Failed to read data")
            }
            System.arraycopy(buffer, 0, dataBuffer, bytesBuffered, bytesRead)
            bytesBuffered += bytesRead
        }

        return response.withData(dataBuffer)
    }

    companion object {
        private const val HEADER_SIZE = 10
        private const val CCID_DESCRIPTOR_MIN_LENGTH = 44
        private const val USB_TIMEOUT = 5000

        private const val MESSAGE_TYPE_PC_TO_RDR_ICCPOWERON = 0x62.toByte()
        private const val MESSAGE_TYPE_PC_TO_RDR_ICCPOWEROFF = 0x63.toByte()
        private const val MESSAGE_TYPE_PC_TO_RDR_XFRBLOCK = 0x6F.toByte()
        private const val MESSAGE_TYPE_RDR_TO_PC_DATABLOCK = 0x80.toByte()
    }
}

class CcidException(message: String) : Exception(message)

data class CcidRdrToPcMessage(
    val messageType: Byte,
    val length: Int,
    val slot: Byte,
    val seq: Byte,
    val status: Byte,
    val error: Byte,
    val specific: Byte,
    val data: ByteArray
) {
    fun withData(data: ByteArray): CcidRdrToPcMessage {
        return CcidRdrToPcMessage(
            messageType,
            length,
            slot,
            seq,
            status,
            error,
            specific,
            data
        )
    }

    val iccStatus: Int
        get() = status.toInt() and 0x03

    val commandStatus: Int
        get() = (status.toInt() shr 6) and 0x03

    val isStatusTimeoutExtensionRequest: Boolean
        get() = commandStatus == 0x02

    val isStatusSuccess: Boolean
        get() = commandStatus == 0x00 && iccStatus == 0x00

    companion object {
        fun parseHeader(data: ByteArray): CcidRdrToPcMessage {
            if (data.size < 10) {
                throw CcidException("Incorrect header")
            }
            val length = (data[1].toLong() and 0xff) or
                    ((data[2].toLong() and 0xff) shl 8) or
                    ((data[3].toLong() and 0xff) shl 16) or
                    ((data[4].toLong() and 0xff) shl 24)
            if (length > MAX_MESSAGE_LENGTH) {
                throw CcidException("CCID response is too large: $length bytes")
            }
            return CcidRdrToPcMessage(
                data[0],
                length.toInt(),
                data[5],
                data[6],
                data[7],
                data[8],
                data[9],
                byteArrayOf()
            )
        }

        private const val MAX_MESSAGE_LENGTH = 1024 * 1024L
    }
}
