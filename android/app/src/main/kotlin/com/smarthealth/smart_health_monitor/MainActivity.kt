package com.smarthealth.smart_health_monitor

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smart_health/buzzer")
            .setMethodCallHandler { call, result ->
                if (call.method != "beep") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val tone = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
                tone.startTone(ToneGenerator.TONE_PROP_BEEP, 160)
                val handler = Handler(Looper.getMainLooper())
                handler.postDelayed({
                    tone.startTone(ToneGenerator.TONE_PROP_BEEP2, 220)
                }, 190)
                handler.postDelayed({
                    tone.release()
                    result.success(true)
                }, 460)
            }
    }
}
