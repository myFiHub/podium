package com.web3podium

import com.facebook.react.modules.core.PermissionListener
import io.flutter.embedding.android.FlutterFragmentActivity
import org.jitsi.meet.sdk.JitsiMeetActivityDelegate
import org.jitsi.meet.sdk.JitsiMeetActivityInterface

// Hosts the background Jitsi conference (see JitsiMeetBackgroundSession in the SDK), which
// needs a FragmentActivity that implements JitsiMeetActivityInterface.
class MainActivity : FlutterFragmentActivity(), JitsiMeetActivityInterface {
    override fun requestPermissions(
        permissions: Array<String>,
        requestCode: Int,
        listener: PermissionListener?
    ) {
        JitsiMeetActivityDelegate.requestPermissions(this, permissions, requestCode, listener)
    }
}
