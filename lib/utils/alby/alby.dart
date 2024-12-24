import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:podium/env.dart';
import 'package:podium/utils/logger.dart';

void createAblyRealtimeInstance() async {
  // Connect to Ably with your API key
  final realtimeInstance = ably.Realtime(key: Env.albyApiKey);
  realtimeInstance.connection
      .on(ably.ConnectionEvent.connected)
      .listen((ably.ConnectionStateChange stateChange) async {
    print('New state is: ${stateChange.current}');
    switch (stateChange.current) {
      case ably.ConnectionState.connected:
        print('Connected to Ably!');
        break;
      case ably.ConnectionState.failed:
        print('The connection to Ably failed.');
        // Failed connection
        break;
      default:
        break;
    }

    // Create a channel called 'get-started' and register a listener to subscribe to all messages with the name 'first'
    final channel = realtimeInstance.channels.get('get-started');
    channel.subscribe().listen((message) {
      print('Message received: ${message.data}');
    });

    // Publish a message with the name 'first' and the contents 'Here is my first message!'
    await channel.publish(name: 'first', data: "Here is my first message!");

    // Close the connection to Ably
    realtimeInstance.connection.close();
    realtimeInstance.connection
        .on(ably.ConnectionEvent.closed)
        .listen((ably.ConnectionStateChange stateChange) async {
      l.d('New state is: ${stateChange.current}');
      switch (stateChange.current) {
        case ably.ConnectionState.closing:
          l.i('Alby closing.');
          break;
        case ably.ConnectionState.suspended:
          l.f('Alby Suspended');
          break;
        case ably.ConnectionState.disconnected:
          l.f('Alby disconnected');
          break;
        case ably.ConnectionState.connecting:
          l.i('Alby connecting');
          break;
        case ably.ConnectionState.initialized:
          l.i('Alby initialized');
          break;
        case ably.ConnectionState.connected:
          l.i('Connected to Ably!');
          break;
        case ably.ConnectionState.closed:
          l.f('Alby connection closed');
          break;
        case ably.ConnectionState.failed:
          break;
      }
    });
  });
}
