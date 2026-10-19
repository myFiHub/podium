package com.web3podium

import android.content.Intent
import android.os.Bundle
import com.facebook.react.modules.core.PermissionListener
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import org.jitsi.meet.sdk.JitsiMeetActivityDelegate
import org.jitsi.meet.sdk.JitsiMeetActivityInterface

// Hosts the background Jitsi conference (see JitsiMeetBackgroundSession in the SDK), which
// needs a FragmentActivity that implements JitsiMeetActivityInterface.
class MainActivity : FlutterFragmentActivity(), JitsiMeetActivityInterface {
    private var callOverlay: CallOverlayPlugin? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Flutter would treat a replay file's URI as a route to open.
        if (savedInstanceState == null && ReplayImportChannel.handle(this, intent)) {
            intent = Intent(Intent.ACTION_MAIN)
        }
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        if (ReplayImportChannel.handle(this, intent)) {
            super.onNewIntent(Intent(Intent.ACTION_MAIN))
            return
        }
        super.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callOverlay?.dispose()
        callOverlay = CallOverlayPlugin.register(this, flutterEngine.dartExecutor.binaryMessenger)
        ReplayImportChannel.register(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        callOverlay?.dispose()
        callOverlay = null
        ReplayImportChannel.unregister()
        super.onDestroy()
    }

    override fun requestPermissions(
        permissions: Array<String>,
        requestCode: Int,
        listener: PermissionListener?
    ) {
        JitsiMeetActivityDelegate.requestPermissions(this, permissions, requestCode, listener)
    }
}
