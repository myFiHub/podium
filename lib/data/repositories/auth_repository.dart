import 'package:podium/providers/api/podium/models/auth/additionalDataForLogin.dart';
import 'package:podium/providers/api/podium/models/auth/loginRequest.dart';
import 'package:podium/providers/api/podium/models/metadata/metadata.dart';
import 'package:podium/providers/api/podium/models/users/connect_new_account_request.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/providers/api/podium/podium.dart';
import 'package:podium/utils/logger.dart';

typedef SocketConnector = Future<bool> Function(String token);

/// Session lifecycle and account-level settings.
class AuthRepository {
  AuthRepository(this._api, {required SocketConnector connectSocket})
      : _connectSocket = connectSocket;

  final PodiumApi _api;
  final SocketConnector _connectSocket;

  /// Logs in, then opens the websocket and loads the profile in parallel.
  /// Returns the user, or an error message and HTTP status when it fails.
  Future<(UserModel?, String?, int?)> login({
    required LoginRequest request,
    required AdditionalDataForLogin additionalData,
  }) async {
    final auth = await _api.authenticate(request);
    final token = auth.token;
    if (token == null) {
      return (null, auth.error, auth.statusCode);
    }
    try {
      final results = await Future.wait<Object?>([
        _connectSocket(token),
        _api.getMyUserData(additionalData: additionalData),
      ]);
      return (results[1] as UserModel?, null, auth.statusCode);
    } catch (e) {
      l.e(e);
      return (
        null,
        'Login error, try again in a few minutes',
        auth.statusCode,
      );
    }
  }

  /// Reopens the websocket with the current session token.
  Future<bool> reconnectSocket() async {
    final token = _api.token;
    if (token == null) {
      return false;
    }
    return _connectSocket(token);
  }

  Future<PodiumAppMetadata> appMetadata() => _api.appMetadata();

  Future<bool> connectNewAccount(ConnectNewAccountRequest request) =>
      _api.connectNewAccount(request);

  Future<bool> setAccountAsPrimary({required String address}) =>
      _api.setAccountAsPrimary(address: address);

  Future<bool> deactivateAccount() => _api.deactivateAccount();
}
