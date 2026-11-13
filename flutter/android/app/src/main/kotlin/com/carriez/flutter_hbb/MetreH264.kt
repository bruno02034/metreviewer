package com.carriez.flutter_hbb

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Surface
import ffi.FFI

// Metre: motor de vídeo do Android no modelo do scrcpy. A tela vai direto da GPU para o codificador
// H.264 do chip (Surface), sem cópia nem conversão de cor no processador; os pacotes prontos vão para
// o núcleo, que só os repassa ao técnico (video_service.rs, metre_h264_run).
// Antes: ImageReader RGBA -> cópia -> conversão NV12 -> FFmpeg h264_mediacodec (fila no FFmpeg).
// Ver METRE-CHANGES.md.
object MetreH264 {
    private const val TAG = "MetreH264"

    // Ligado pelo núcleo quando o técnico usa H.264 e o aparelho tem codificador por hardware.
    @Volatile var wanted = false
    @Volatile var kbps = 1000

    private var codec: MediaCodec? = null
    private var drain: Thread? = null
    @Volatile private var running = false

    /** Codificador H.264 por hardware (ignora os de software do Android). */
    private fun hardwareAvcName(): String? = MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos
        .filter { it.isEncoder && it.supportedTypes.any { t -> t.equals(MediaFormat.MIMETYPE_VIDEO_AVC, true) } }
        .firstOrNull { c ->
            val software = listOf("OMX.google.", "c2.android", "OMX.SEC.").any { c.name.startsWith(it, true) }
            val hw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) c.isHardwareAccelerated else !software
            hw && !software
        }?.name

    /** Cria o codificador e devolve a Surface que a tela (VirtualDisplay) deve desenhar. */
    @Synchronized
    fun start(width: Int, height: Int): Surface? {
        stop()
        val name = hardwareAvcName() ?: run { Log.w(TAG, "sem H.264 por hardware"); return null }
        return try {
            val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
                setInteger(MediaFormat.KEY_BIT_RATE, kbps * 1000)
                setInteger(MediaFormat.KEY_FRAME_RATE, 30)
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 10)
                // tela parada: repete o último quadro para o codificador não segurar a última mudança
                setLong(MediaFormat.KEY_REPEAT_PREVIOUS_FRAME_AFTER, 100_000)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) setInteger(MediaFormat.KEY_PRIORITY, 0)
            }
            val c = MediaCodec.createByCodecName(name)
            c.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            val surface = c.createInputSurface()
            c.start()
            codec = c
            running = true
            drain = Thread({ drainLoop(c) }, "MetreH264").apply { priority = Thread.MAX_PRIORITY; start() }
            Log.i(TAG, "iniciado: $name ${width}x$height ${kbps}kbps")
            surface
        } catch (e: Exception) {
            Log.e(TAG, "falha ao iniciar $name ${width}x$height: $e")
            stop()
            null
        }
    }

    private fun drainLoop(c: MediaCodec) {
        val info = MediaCodec.BufferInfo()
        var config: ByteArray? = null // SPS/PPS, vão junto de cada quadro-chave
        while (running) {
            val idx = try { c.dequeueOutputBuffer(info, 50_000) } catch (e: Exception) { break }
            if (idx < 0) continue
            try {
                val buf = c.getOutputBuffer(idx)
                if (buf != null && info.size > 0) {
                    buf.position(info.offset)
                    buf.limit(info.offset + info.size)
                    val bytes = ByteArray(info.size)
                    buf.get(bytes)
                    if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        config = bytes
                    } else {
                        val key = info.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME != 0
                        val cfg = config
                        val data = if (key && cfg != null) cfg + bytes else bytes
                        FFI.onH264Frame(data, key, info.presentationTimeUs / 1000)
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "drain: $e")
            } finally {
                try { c.releaseOutputBuffer(idx, false) } catch (_: Exception) {}
            }
        }
    }

    fun requestKeyFrame() {
        try {
            codec?.setParameters(Bundle().apply { putInt(MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME, 0) })
        } catch (e: Exception) { Log.w(TAG, "keyframe: $e") }
    }

    fun setBitrate(value: Int) {
        kbps = value
        try {
            codec?.setParameters(Bundle().apply { putInt(MediaCodec.PARAMETER_KEY_VIDEO_BITRATE, value * 1000) })
        } catch (e: Exception) { Log.w(TAG, "bitrate: $e") }
    }

    val isRunning: Boolean get() = codec != null

    @Synchronized
    fun stop() {
        running = false
        try { drain?.join(300) } catch (_: Exception) {}
        drain = null
        codec?.let {
            try { it.stop() } catch (_: Exception) {}
            try { it.release() } catch (_: Exception) {}
        }
        codec = null
    }
}
