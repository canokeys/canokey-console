package org.canokeys.console

import android.app.PendingIntent
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import im.nfc.flutter_nfc_kit.FlutterNfcKitPlugin

class MainActivity : FlutterActivity() {
    private var audioPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val kind = call.argument<String>("kind")
                    val set = call.argument<Int>("set")
                    if (kind !in AUDIO_KINDS || set == null || set !in 0 until AUDIO_SET_COUNT) {
                        result.error("invalid_audio", "Invalid NFC interaction sound", null)
                    } else {
                        playAudio("${kind}${set + 1}.aac")
                        result.success(null)
                    }
                }

                "stop" -> {
                    releaseAudioPlayer()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            this, 0, Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_MUTABLE
        )
        adapter?.enableForegroundDispatch(this, pendingIntent, null, null)
    }

    override fun onPause() {
        super.onPause()
        releaseAudioPlayer()
        val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
        adapter?.disableForegroundDispatch(this)
    }

    override fun onNewIntent(intent: Intent) {
        val tag: Tag? = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
        tag?.apply(FlutterNfcKitPlugin::handleTag)
    }

    private fun playAudio(assetName: String) {
        releaseAudioPlayer()
        try {
            val descriptor = assets.openFd(assetName)
            val player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                        .build()
                )
                setDataSource(
                    descriptor.fileDescriptor,
                    descriptor.startOffset,
                    descriptor.length
                )
                setOnPreparedListener(MediaPlayer::start)
                setOnCompletionListener { completed ->
                    if (audioPlayer === completed) audioPlayer = null
                    completed.release()
                }
                setOnErrorListener { failed, what, extra ->
                    Log.w(TAG, "Failed to play $assetName: $what/$extra")
                    if (audioPlayer === failed) audioPlayer = null
                    failed.release()
                    true
                }
            }
            descriptor.close()
            audioPlayer = player
            player.prepareAsync()
        } catch (error: Exception) {
            Log.w(TAG, "Failed to load $assetName", error)
            releaseAudioPlayer()
        }
    }

    private fun releaseAudioPlayer() {
        val player = audioPlayer ?: return
        audioPlayer = null
        player.setOnPreparedListener(null)
        player.setOnCompletionListener(null)
        player.setOnErrorListener(null)
        player.release()
    }

    companion object {
        private const val TAG = "CanoKeyAudio"
        private const val AUDIO_CHANNEL = "org.canokeys.console/audio"
        private const val AUDIO_SET_COUNT = 3
        private val AUDIO_KINDS = setOf("poll", "finish", "error")
    }
}
