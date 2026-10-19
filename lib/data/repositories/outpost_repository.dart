import 'package:podium/providers/api/podium/models/outposts/createOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/inviteRequestModel.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/outposts/rejectInvitationRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/setReminder.dart';
import 'package:podium/providers/api/podium/models/outposts/updateOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/tag/tag.dart';
import 'package:podium/providers/api/podium/podium.dart';

/// Outposts, their membership, live state, invites and reminders.
class OutpostRepository {
  OutpostRepository(this._api);

  final PodiumApi _api;

  Future<OutpostModel?> getOutpost(String id) => _api.getOutpost(id);

  /// Throws [ApiFailure] so a failed refresh can keep the current list.
  Future<List<OutpostModel>> getOutposts({int? page, int? page_size}) =>
      _api.getOutposts(page: page, page_size: page_size);

  /// Throws [ApiFailure] so a failed refresh can keep the current list.
  Future<List<OutpostModel>> getMyOutposts({
    bool include_archived = true,
    int? page,
    int? page_size,
  }) =>
      _api.getMyOutposts(
        include_archived: include_archived,
        page: page,
        page_size: page_size,
      );

  Future<Map<String, OutpostModel>> getOutpostsByTagId({required int id}) =>
      _api.getOutpostsByTagId(id: id);

  Future<Map<String, OutpostModel>> searchOutpostByName({
    required String name,
  }) =>
      _api.searchOutpostByName(name: name);

  Future<Map<String, TagModel>> searchTag({required String tagName}) =>
      _api.searchTag(tagName: tagName);

  Future<OutpostModel?> createOutpost(CreateOutpostRequest request) =>
      _api.createOutpost(request);

  Future<bool> updateOutpost({required UpdateOutpostRequest request}) =>
      _api.updateOutpost(request: request);

  Future<bool> toggleOutpostArchive(String id, bool archive) =>
      _api.toggleOutpostArchive(id, archive);

  Future<bool> addMeAsMember({required String outpostId, String? inviterId}) =>
      _api.addMeAsMember(outpostId: outpostId, inviterId: inviterId);

  Future<bool> leaveOutpost(String id) => _api.leaveOutpost(id);

  Future<bool> setCreatorJoinedToTrue(String outpostId) =>
      _api.setCreatorJoinedToTrue(outpostId);

  Future<int> getNumberOfOnlineMembers(String outpostId) =>
      _api.getNumberOfOnlineMembers(outpostId);

  Future<OutpostLiveData?> getLatestLiveData({required String outpostId}) =>
      _api.getLatestLiveData(outpostId: outpostId);

  Future<bool> reportOutpost({
    required String outpostId,
    required List<String> reasons,
  }) =>
      _api.reportOutpost(outpostId: outpostId, reasons: reasons);

  Future<bool> scoreOutpost({required String outpostId, required int score}) =>
      _api.scoreOutpost(outpostId: outpostId, score: score);

  Future<bool> setOrRemoveReminder(SetOrRemoveReminderRequest request) =>
      _api.setOrRemoveReminder(request);

  Future<bool> inviteUserToJoinOutpost(InviteRequestModel request) =>
      _api.inviteUserToJoinOutpost(request);

  Future<bool> rejectInvitation(RejectInvitationRequest request) =>
      _api.rejectInvitation(request);
}
