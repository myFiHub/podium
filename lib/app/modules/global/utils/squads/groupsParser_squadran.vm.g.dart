// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: WorkerGenerator 6.0.6
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'groupsParser_squadran.dart';

void _start$GroupsParser(WorkerRequest command) {
  /// VM entry point for GroupsParser
  run($GroupsParserInitializer, command);
}

EntryPoint $getGroupsParserActivator(SquadronPlatformType platform) {
  if (platform.isVm) {
    return _start$GroupsParser;
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
