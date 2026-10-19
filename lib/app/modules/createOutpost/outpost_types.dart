/// Wire values the backend uses for `enter_type` / `speak_type`.
class BuyableTicketTypes {
  static const onlyFriendTechTicketHolders = 'friend_tech_key_holders';
  static const onlyArenaTicketHolders = 'arena_ticket_holders';
  static const onlyPodiumPassHolders = 'podium_pass_holders';

  static const all = {
    onlyFriendTechTicketHolders,
    onlyArenaTicketHolders,
    onlyPodiumPassHolders,
  };
}

class FreeOutpostAccessTypes {
  static const public = 'everyone';
  static const onlyLink = 'having_link';
  static const invited_users = 'invited_users';
}

class FreeOutpostSpeakerTypes {
  static const everyone = FreeOutpostAccessTypes.public;
  static const invited_users = FreeOutpostAccessTypes.invited_users;
}

class TicketPermissionType {
  static const speak = 'speak';
  static const access = 'access';
}

class TicketTypes {
  static const arena = 'arena';
  static const podium = 'podium';
  static const friendTech = 'friendTech';
}
