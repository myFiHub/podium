// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: WorkerGenerator 6.0.6
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'jsoner.dart';

void _start$Jsoner(WorkerRequest command) {
  /// VM entry point for Jsoner
  run($JsonerInitializer, command);
}

EntryPoint $getJsonerActivator(SquadronPlatformType platform) {
  if (platform.isVm) {
    return _start$Jsoner;
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
