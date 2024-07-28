generateKeyForStorageAndObserver(
    {required String groupId, required String userId, required bool like}) {
  return userId + groupId + (like ? '_like' : '_dislike');
}
