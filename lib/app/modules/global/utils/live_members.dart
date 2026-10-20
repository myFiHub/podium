import 'package:podium/providers/api/podium/models/outposts/liveData.dart';

/// Splits [members] into stage and audience, keeping each group in member
/// order but putting whoever is speaking first on stage.
({List<LiveMember> stage, List<LiveMember> audience, int talking})
    partitionLiveMembers(
  Iterable<LiveMember> members, {
  required bool Function(LiveMember member) isOnStage,
}) {
  final speaking = <LiveMember>[];
  final silent = <LiveMember>[];
  final audience = <LiveMember>[];
  for (final member in members) {
    if (!isOnStage(member)) {
      audience.add(member);
    } else if (member.is_speaking) {
      speaking.add(member);
    } else {
      silent.add(member);
    }
  }
  return (
    stage: [...speaking, ...silent],
    audience: audience,
    talking: speaking.length,
  );
}

/// Same members in the same order, by identity.
bool sameMemberOrder(List<LiveMember> a, List<LiveMember> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}
