package com.web3podium

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Receives replay files opened with or shared to Podium. Each one is copied into the cache,
 * since Dart can't read content:// URIs, and queued until Dart takes it with
 * `takePendingImports`; `replayImportAvailable` tells a running app to take it.
 */
object ReplayImportChannel {
    private const val TAG = "ReplayImport"
    private const val CHANNEL = "podium/replay_import"
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pending = mutableListOf<String>()
    private var channel: MethodChannel? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takePendingImports" -> {
                        val paths = pending.toList()
                        pending.clear()
                        result.success(paths)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    fun unregister() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    /** Returns true if [intent] carried a replay, which is then being imported. */
    fun handle(activity: Activity, intent: Intent?): Boolean {
        val uri = replayUri(intent) ?: return false
        val context = activity.applicationContext
        Thread {
            val path = try {
                copyToCache(context, uri)
            } catch (e: Exception) {
                Log.e(TAG, "Could not read $uri", e)
                null
            }
            mainHandler.post {
                if (path != null) pending.add(path)
                channel?.invokeMethod("replayImportAvailable", null)
            }
        }.start()
        return true
    }

    private fun replayUri(intent: Intent?): Uri? {
        intent ?: return null
        return when (intent.action) {
            Intent.ACTION_VIEW -> intent.data?.takeIf { it.scheme == "content" || it.scheme == "file" }
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            else -> null
        }
    }

    private fun copyToCache(context: android.content.Context, uri: Uri): String {
        val dir = File(context.cacheDir, "replay_imports").apply { mkdirs() }
        val out = File(dir, "import_${System.currentTimeMillis()}.podium")
        val input = context.contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("No stream for $uri")
        input.use { source -> out.outputStream().use { source.copyTo(it) } }
        return out.absolutePath
    }
}
