package com.pramaan.app.frontend

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayList

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pramaan.app/speech"
    private val RECORD_AUDIO_PERMISSION_CODE = 2001
    private var speechRecognizer: SpeechRecognizer? = null
    private var pendingResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    val lang = call.argument<String>("language") ?: "en-IN"
                    pendingResult = result

                    // Check RECORD_AUDIO permission
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), RECORD_AUDIO_PERMISSION_CODE)
                        return@setMethodCallHandler
                    }

                    startHeadlessSpeechRecognition(lang)
                }
                "stopListening" -> {
                    mainHandler.post {
                        speechRecognizer?.stopListening()
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startHeadlessSpeechRecognition(lang: String) {
        mainHandler.post {
            try {
                speechRecognizer?.destroy()
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                }

                speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {}
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {}

                    override fun onError(error: Int) {
                        // Error 7: No match; Error 6: Speecher timeout
                        pendingResult?.error("ERROR", "Speech recognizer code: $error", null)
                        pendingResult = null
                    }

                    override fun onResults(results: Bundle?) {
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        if (!matches.isNullOrEmpty()) {
                            pendingResult?.success(matches[0])
                        } else {
                            pendingResult?.error("NO_MATCH", "No speech recognized", null)
                        }
                        pendingResult = null
                    }

                    override fun onPartialResults(partialResults: Bundle?) {}
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                // Starts headless in-app listening with ZERO black Google dialog popups
                speechRecognizer?.startListening(intent)
            } catch (e: Exception) {
                pendingResult?.error("UNAVAILABLE", e.message, null)
                pendingResult = null
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == RECORD_AUDIO_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startHeadlessSpeechRecognition("en-IN")
            } else {
                pendingResult?.error("PERMISSION_DENIED", "Microphone permission required", null)
                pendingResult = null
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        speechRecognizer?.destroy()
    }
}
