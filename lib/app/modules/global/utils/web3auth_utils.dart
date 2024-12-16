import 'dart:io';

Uri resolveRedirectUrl() {
  if (Platform.isAndroid) {
    return Uri.parse('podium://com.web3podium/web3auth');
  } else {
    return Uri.parse('com.web3podium://web3auth');
  }
}
