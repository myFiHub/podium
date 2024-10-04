// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groupsParser_squadran.dart';

// **************************************************************************
// Generator: WorkerGenerator 6.0.6
// **************************************************************************

/// WorkerService class for GroupsParser
base class _$GroupsParserWorkerService extends GroupsParser
    implements WorkerService {
  _$GroupsParserWorkerService() : super();

  @override
  late final Map<int, CommandHandler> operations =
      Map.unmodifiable(<int, CommandHandler>{
    _$parseGroupsId: ($) =>
        parseGroups(_$X.$0($.args[0]), _$X.$2($.args[1])).then(_$X.$3),
  });

  static const int _$parseGroupsId = 1;
}

/// Service initializer for GroupsParser
WorkerService $GroupsParserInitializer(WorkerRequest $$) =>
    _$GroupsParserWorkerService();

/// Worker for GroupsParser
base class GroupsParserWorker extends Worker implements GroupsParser {
  GroupsParserWorker(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($GroupsParserActivator(Squadron.platformType));

  GroupsParserWorker.vm(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($GroupsParserActivator(SquadronPlatformType.vm));

  GroupsParserWorker.js(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($GroupsParserActivator(SquadronPlatformType.js),
            threadHook: threadHook, exceptionManager: exceptionManager);

  GroupsParserWorker.wasm(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($GroupsParserActivator(SquadronPlatformType.wasm));

  @override
  Future<Map<String, FirebaseGroup>> parseGroups(
          [dynamic data, String? myId]) =>
      send(_$GroupsParserWorkerService._$parseGroupsId, args: [data, myId])
          .then(_$X.$5);
}

/// Worker pool for GroupsParser
base class GroupsParserWorkerPool extends WorkerPool<GroupsParserWorker>
    implements GroupsParser {
  GroupsParserWorkerPool(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => GroupsParserWorker(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  GroupsParserWorkerPool.vm(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => GroupsParserWorker.vm(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  GroupsParserWorkerPool.js(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => GroupsParserWorker.js(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  GroupsParserWorkerPool.wasm(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => GroupsParserWorker.wasm(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  @override
  Future<Map<String, FirebaseGroup>> parseGroups(
          [dynamic data, String? myId]) =>
      execute((w) => w.parseGroups(data, myId));
}

sealed class _$X {
  static final $0 = Squadron.converter.value<dynamic>();
  static final $1 = Squadron.converter.value<String>();
  static final $2 = Squadron.converter.nullable($1);
  static final $3 = Squadron.converter.map<String, FirebaseGroup>();
  static final $4 = Squadron.converter.value<FirebaseGroup>();
  static final $5 = Squadron.converter
      .map<String, FirebaseGroup>(kcast: _$X.$1, vcast: _$X.$4);
}
