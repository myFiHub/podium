import 'package:podium/app/modules/global/utils/allSetteled.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/luma/models/addGuest.dart';
import 'package:podium/providers/api/luma/models/addHost.dart';
import 'package:podium/providers/api/luma/models/createEvent.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

/// Creates a one-hour Luma event pointing at the outpost and invites
/// [hosts] and [guests]. Returns the Luma event id, or null on failure.
Future<String?> createLumaEventForOutpost({
  required String outpostId,
  required String outpostName,
  required int scheduledFor,
  required List<AddHostModel> hosts,
  required List<AddGuestModel> guests,
}) async {
  try {
    final start = DateTime.fromMillisecondsSinceEpoch(scheduledFor).toUtc();
    final createdEvent = await HttpApis.lumaApi.createEvent(
      event: LumaCreateEvent(
        name: outpostName,
        start_at: start.toIso8601String(),
        end_at: start.add(const Duration(hours: 1)).toIso8601String(),
        timezone: 'UTC',
        meeting_url: generateOutpostShareUrl(outpostId: outpostId),
      ),
    );
    if (createdEvent == null) return null;

    final eventId = createdEvent.event.api_id;
    // Failed hosts are ignored; they can be added later from Luma.
    await allSettled({
      for (final host in hosts)
        host.email: HttpApis.lumaApi.addHost(
          host: AddHostModel(
            event_api_id: eventId,
            email: host.email,
            name: host.name,
          ),
        ),
    });
    final guestsAdded =
        await HttpApis.lumaApi.addGuests(eventId: eventId, guests: guests);
    if (guestsAdded == true) {
      Toast.success(message: 'Luma Event Created');
      return eventId;
    }
  } catch (e) {
    l.e(e);
  }
  return null;
}
