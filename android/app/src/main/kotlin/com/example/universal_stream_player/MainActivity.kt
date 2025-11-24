package com.example.universal_stream_player

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.arthenica.mobileffmpeg.FFmpeg

class MainActivity: FlutterActivity() {
    private val CHANNEL = "universal_stream_player/ffmpeg"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "play" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "A URL não pode ser nula.", null)
                    } else {
                        FFmpeg.cancel() // Para qualquer reprodução anterior
                        val command = "-i \"$url\" -nodisp -autoexit"
                        FFmpeg.executeAsync(command) { _, returnCode ->
                            println("FFmpeg finalizado com código $returnCode")
                        }
                        result.success("Comando de reprodução enviado.")
                    }
                }
                "stop" -> {
                    FFmpeg.cancel()
                    result.success("Comando para parar enviado.")
                }
                else -> result.notImplemented()
            }
        }
    }
}
