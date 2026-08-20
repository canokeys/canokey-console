package im.nfc.ccid

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class CcidMessageTest {
    @Test
    fun parseHeaderReadsLittleEndianLength() {
        val message = CcidRdrToPcMessage.parseHeader(
            byteArrayOf(
                0x80.toByte(),
                0x34, 0x12, 0x00, 0x00,
                0x00, 0x07, 0x00, 0x00, 0x00
            )
        )

        assertEquals(0x1234, message.length)
        assertEquals(0x07, message.seq.toInt())
    }

    @Test
    fun parseHeaderRejectsTruncatedHeaders() {
        assertThrows(CcidException::class.java) {
            CcidRdrToPcMessage.parseHeader(ByteArray(9))
        }
    }

    @Test
    fun parseHeaderRejectsOversizedResponses() {
        assertThrows(CcidException::class.java) {
            CcidRdrToPcMessage.parseHeader(
                byteArrayOf(
                    0x80.toByte(),
                    0x01, 0x00, 0x10, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00
                )
            )
        }
    }
}
