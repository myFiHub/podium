import 'package:flutter/material.dart';

final defaultAvatar = 'https://ui-avatars.com/api/?name=Oo.png';

avatarPlaceHolder(String? name) {
  final n = (name == null || name.isEmpty) ? 'Oo' : name;
  return 'https://ui-avatars.com/api/?name=${n.replaceAll(' ', '+')}.png';
}

class Constants {
  static const smallScreen = 640;
  static const String aud = 'https://walletconnect.org/login';
  static const String domain = 'walletconnect.org';
  static const String logoUrl =
      "https://firebasestorage.googleapis.com/v0/b/podium-b809c.appspot.com/o/logo.png?alt=media&token=3c44b7b8-e2a3-46b4-81ad-a565df0ff172";

  static const defaultProfilePic =
      'https://static.vecteezy.com/system/resources/previews/021/548/095/original/default-profile-picture-avatar-user-avatar-icon-person-icon-head-icon-profile-picture-icons-default-anonymous-user-male-and-female-businessman-photo-placeholder-social-network-avatar-portrait-free-vector.jpg';
}

class StyleConstants {
  static const Color primaryColor = Color.fromARGB(255, 16, 165, 206);
  static const Color secondaryColor = Color(0xFF1A1A1A);
  static const Color grayColor = Color.fromARGB(255, 180, 180, 180);
  static const Color titleTextColor = Color(0xFFFFFFFF);

  // Linear
  static const double linear8 = 8;
  static const double linear16 = 16;
  static const double linear24 = 24;
  static const double linear32 = 32;
  static const double linear48 = 48;
  static const double linear40 = 40;
  static const double linear56 = 56;
  static const double linear72 = 72;
  static const double linear80 = 80;

  // Magic Number
  static const double magic10 = 10;
  static const double magic14 = 14;
  static const double magic20 = 20;
  static const double magic40 = 40;
  static const double magic64 = 64;

  // Width
  static const double maxWidth = 400;

  // Text styles
  static const TextStyle titleText = TextStyle(
    color: Colors.black,
    fontSize: linear32,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle subtitleText = TextStyle(
    color: Colors.black,
    fontSize: linear24,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle buttonText = TextStyle(
    color: Colors.black,
    fontSize: magic14,
    fontWeight: FontWeight.w600,
  );
}

class StringConstants {
  // General
  static const String cancel = 'Cancel';
  static const String close = 'Close';
  static const String ok = 'OK';
  static const String delete = 'Delete';

  // Main Page
  static const String appTitle = 'WalletConnect v2 Flutter dApp Demo';
  static const String basicPageTitle = 'Basic';
  static const String wcmPageTitle = 'WalletConnect Modal';
  static const String w3mPageTitle = 'Podium';
  static const String w3mPageTitleV3 = 'Podium';
  static const String pairingsPageTitle = 'Pairings';
  static const String sessionsPageTitle = 'Sessions';
  static const String authPageTitle = 'Auth';
  static const String settingsPageTitle = 'Settings';
  static const String receivedPing = 'Received Ping';
  static const String receivedEvent = 'Received Event';

  // Sign Page
  static const String selectChains = 'Select chains:';
  static const String testnetsOnly = 'Testnets only?';
  static const String scanQrCode = 'Scan QR Code';
  static const String copiedToClipboard = 'Copied to clipboard';
  static const String bareBonesSign = 'Connect Bare Bones';
  static const String connectionEstablished = 'Session established';
  static const String connectionFailed = 'Session setup failed';
  static const String authSucceeded = 'Authentication Successful';
  static const String authFailed = 'Authentication Failed';

  // Pairings Page
  static const String pairings = 'Pairings';
  static const String deletePairing = 'Delete Pairing?';

  // Sessions Page
  static const String sessions = 'Sessions';
  static const String noSessionSelected = 'No session selected';
  static const String sessionTopic = 'Session Topic: ';
  static const String methods = 'Methods';
  static const String events = 'Events';
}
