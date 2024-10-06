// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jsoner.dart';

// **************************************************************************
// Generator: WorkerGenerator 6.0.6
// **************************************************************************

/// WorkerService class for Jsoner
base class _$JsonerWorkerService extends Jsoner implements WorkerService {
  _$JsonerWorkerService() : super();

  @override
  late final Map<int, CommandHandler> operations =
      Map.unmodifiable(<int, CommandHandler>{
    _$jsonerId: ($) => jsoner(_$X.$0($.args[0])),
  });

  static const int _$jsonerId = 1;
}

/// Service initializer for Jsoner
WorkerService $JsonerInitializer(WorkerRequest $$) => _$JsonerWorkerService();

/// Worker for Jsoner
base class JsonerWorker extends Worker implements Jsoner {
  JsonerWorker(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($JsonerActivator(Squadron.platformType));

  JsonerWorker.vm(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($JsonerActivator(SquadronPlatformType.vm));

  JsonerWorker.js(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($JsonerActivator(SquadronPlatformType.js),
            threadHook: threadHook, exceptionManager: exceptionManager);

  JsonerWorker.wasm(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($JsonerActivator(SquadronPlatformType.wasm));

  @override
  Future<dynamic> jsoner([dynamic data]) =>
      send(_$JsonerWorkerService._$jsonerId, args: [data]).then(_$X.$0);
}

/// Worker pool for Jsoner
base class JsonerWorkerPool extends WorkerPool<JsonerWorker> implements Jsoner {
  JsonerWorkerPool(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => JsonerWorker(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  JsonerWorkerPool.vm(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => JsonerWorker.vm(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  JsonerWorkerPool.js(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => JsonerWorker.js(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  JsonerWorkerPool.wasm(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => JsonerWorker.wasm(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  @override
  Future<dynamic> jsoner([dynamic data]) => execute((w) => w.jsoner(data));
}

sealed class _$X {
  static final $0 = Squadron.converter.value<dynamic>();
}
