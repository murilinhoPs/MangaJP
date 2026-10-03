package dev.murilinhops.mlkit_harness

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/// Device-only M0.3 bake-off runner. Decodes crops with Android BitmapFactory
/// (not Dart zlib) and runs bundled ML Kit Japanese text recognition.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "paths" -> {
                        val dir = appFilesDir()
                        result.success(
                            mapOf(
                                "cropsDir" to File(dir, "crops").absolutePath,
                                "outPath" to File(dir, "mlkit_predictions.json").absolutePath,
                            ),
                        )
                    }
                    "runBakeoff" -> {
                        val cropsDir =
                            call.argument<String>("cropsDir")
                                ?: File(appFilesDir(), "crops").absolutePath
                        val outPath =
                            call.argument<String>("outPath")
                                ?: File(appFilesDir(), "mlkit_predictions.json").absolutePath
                        executor.execute {
                            try {
                                val payload = runBakeoff(File(cropsDir), File(outPath))
                                mainHandler.post { result.success(payload) }
                            } catch (e: Exception) {
                                Log.e(TAG, "runBakeoff failed", e)
                                mainHandler.post {
                                    result.error("MLKIT", e.message, e.stackTraceToString())
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun appFilesDir(): File = filesDir

    private fun runBakeoff(
        cropsDir: File,
        outFile: File,
    ): Map<String, Any> {
        if (!cropsDir.isDirectory) {
            throw IllegalArgumentException("crops dir missing: ${cropsDir.absolutePath}")
        }
        val byStem = linkedMapOf<String, MutableList<File>>()
        val listed = cropsDir.listFiles() ?: emptyArray()
        for (file in listed.sortedBy { it.name }) {
            val name = file.name
            val stem =
                when {
                    name.endsWith(".png", ignoreCase = true) -> name.dropLast(4)
                    name.endsWith(".jpg", ignoreCase = true) -> name.dropLast(4)
                    name.endsWith(".jpeg", ignoreCase = true) -> name.dropLast(5)
                    else -> continue
                }
            byStem.getOrPut(stem) { mutableListOf() }.add(file)
        }
        if (byStem.isEmpty()) {
            throw IllegalStateException("no PNG/JPEG crops in ${cropsDir.absolutePath}")
        }

        val recognizer =
            TextRecognition.getClient(JapaneseTextRecognizerOptions.Builder().build())
        val predictions = JSONObject()
        val errors = JSONObject()
        val decode = JSONObject()
        try {
            for ((cropId, candidates) in byStem) {
                Log.i(TAG, "crop $cropId")
                var recognized = false
                var lastErr: String? = null
                val ordered =
                    candidates.sortedBy { file ->
                        if (file.name.endsWith(".png", ignoreCase = true)) 0 else 1
                    }
                for (file in ordered) {
                    val bitmap = decodeBitmap(file)
                    if (bitmap == null) {
                        lastErr = "BitmapFactory.decodeFile returned null for ${file.name}"
                        Log.w(TAG, lastErr!!)
                        continue
                    }
                    decode.put(
                        cropId,
                        "${file.name} BitmapFactory ${bitmap.width}x${bitmap.height}",
                    )
                    try {
                        val image = InputImage.fromBitmap(bitmap, 0)
                        val text = Tasks.await(recognizer.process(image), 120, TimeUnit.SECONDS)
                        predictions.put(cropId, text.text ?: "")
                        recognized = true
                    } catch (e: Exception) {
                        lastErr = "${e.javaClass.simpleName}: ${e.message}"
                        Log.e(TAG, "ML Kit failed for $cropId", e)
                    } finally {
                        bitmap.recycle()
                    }
                    if (recognized) {
                        break
                    }
                }
                if (!recognized) {
                    errors.put(cropId, lastErr ?: "unknown")
                }
            }
        } finally {
            recognizer.close()
        }

        val version =
            "com.google.mlkit:text-recognition-japanese:16.0.1 (bundled); " +
                "decode=Android BitmapFactory; API ${android.os.Build.VERSION.SDK_INT}"
        val root = JSONObject()
        root.put("engine_id", "mlkit_ja")
        root.put("version", version)
        root.put("predictions", predictions)
        root.put("errors", errors)
        root.put("decode", decode)

        outFile.parentFile?.mkdirs()
        FileOutputStream(outFile).use { fos ->
            fos.write(root.toString(2).toByteArray(Charsets.UTF_8))
            fos.write('\n'.code)
        }
        File(outFile.parentFile, "DONE").writeText("ok\n")
        Log.i(
            TAG,
            "wrote ${outFile.absolutePath} preds=${predictions.length()} errors=${errors.length()}",
        )
        return mapOf(
            "outPath" to outFile.absolutePath,
            "nPredictions" to predictions.length(),
            "nErrors" to errors.length(),
            "nCrops" to byStem.size,
            "version" to version,
        )
    }

    private fun decodeBitmap(file: File): Bitmap? {
        Log.i(
            TAG,
            "decode ${file.absolutePath} exists=${file.exists()} canRead=${file.canRead()} len=${file.length()}",
        )
        fun opts(): BitmapFactory.Options {
            val o = BitmapFactory.Options()
            o.inPreferredConfig = Bitmap.Config.ARGB_8888
            return o
        }
        try {
            file.inputStream().use { stream ->
                val fromStream = BitmapFactory.decodeStream(stream, null, opts())
                if (fromStream != null) {
                    return fromStream
                }
            }
            val bytes = file.readBytes()
            val fromBytes = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts())
            if (fromBytes != null) {
                return fromBytes
            }
            return BitmapFactory.decodeFile(file.absolutePath, opts())
        } catch (e: Exception) {
            Log.e(TAG, "decode exception for ${file.name}", e)
            return null
        }
    }

    companion object {
        private const val CHANNEL = "cer_bakeoff/mlkit_ja"
        private const val TAG = "MLKIT_CER"
        private val executor = Executors.newSingleThreadExecutor()
        private val mainHandler = Handler(Looper.getMainLooper())
    }
}
