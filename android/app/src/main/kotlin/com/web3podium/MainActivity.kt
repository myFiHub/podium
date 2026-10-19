package com.web3podium

import com.facebook.react.modules.core.PermissionListener
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import org.jitsi.meet.sdk.JitsiMeetActivityDelegate
import org.jitsi.meet.sdk.JitsiMeetActivityInterface

// Hosts the background Jitsi conference (see JitsiMeetBackgroundSession in the SDK), which
// needs a FragmentActivity that implements JitsiMeetActivityInterface.
class MainActivity : FlutterFragmentActivity(), JitsiMeetActivityInterface {
    private var callOverlay: CallOverlayPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callOverlay?.dispose()
        callOverlay = CallOverlayPlugin.register(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        callOverlay?.dispose()
        callOverlay = null
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
