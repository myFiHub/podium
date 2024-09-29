// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: WorkerGenerator 6.0.3
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'groupsParser_squadran.dart';

void main() {
  /// Web entry point for GroupsParser
  run($GroupsParserInitializer);
}

EntryPoint $getGroupsParserActivator(SquadronPlatformType platform) {
  if (platform.isJs) {
    return Squadron.uri('~/workers/groupsParser_squadran.web.g.dart.js');
  } else if (platform.isWasm) {
    return Squadron.uri('~/workers/groupsParser_squadran.web.g.dart.wasm');
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
