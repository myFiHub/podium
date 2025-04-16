import 'dart:io';

Uri resolveRedirectUrl() {
  if (Platform.isAndroid) {
    return Uri.parse('podium://com.web3podium');
  } else {
    return Uri.parse('com.web3podium://auth');
  }
}
