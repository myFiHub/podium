import 'package:get/get.dart';
import 'package:particle_base/model/chain_info.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:http/http.dart';

final movementChain = ReownAppKitModalNetworkInfo(
  name: 'Movement Testnet',
  chainId: '30732',
  chainIcon: "https://docs.movementnetwork.xyz/img/logo.svg",
  currency: 'MOVE',
  rpcUrl: 'https://mevm.devnet.imola.movementlabs.xyz',
  explorerUrl: 'https://explorer.devnet.imola.movementlabs.xyz',
);
final movementChainOnParticle = ChainInfo(
  int.parse(movementChain.chainId),
  'Movement',
  'evm',
  movementChain.chainIcon!,
  movementChain.name,
  movementChain.chainId == '30732' ? 'Testnet' : 'Mainnet',
  'https://docs.movementnetwork.xyz',
  ChainInfoNativeCurrency('Movement', 'MOVE', 18),
  movementChain.rpcUrl,
  '',
  movementChain.explorerUrl,
  [ChainInfoFeature(Env.chainNamespace.toUpperCase())],
);

class BlockChainUtils {
  static Future<ReownAppKitModal> initializewm3Service(
    ReownAppKitModal _w3mService,
    RxString connectedWalletAddress,
    RxBool w3serviceInitialized,
  ) async {
    // W3MChainPresets.chains.addAll(W3MChainPresets.testChains);
    _w3mService.addListener(() {
      if (_w3mService.session == null) {
        connectedWalletAddress.value = '';
        return;
      }
      final address = retrieveConnectedWallet(_w3mService);
      connectedWalletAddress.value = address;
      log.i('Connected Wallet Address: ${connectedWalletAddress.value}');
    });
    void _onModalConnect(ModalConnect? event) {
      log.i('[initializewm3Service] _onModalConnect ${event?.toString()}');
    }

    // ignore: unused_element
    void _onModalUpdate(ModalConnect? event) {
      log.i('[initializewm3Service] _onModalUpdate ${event?.toString()}');
    }

    void _onModalNetworkChange(ModalNetworkChange? event) {
      log.i(
          '[initializewm3Service] _onModalNetworkChange ${event?.toString()}');
      if (event != null) {
        GlobalController globalController = Get.find<GlobalController>();
        globalController.externalWalletChainId.value = event.chainId;
        globalController.switchExternalWalletChain(event.chainId);
      }
    }

    void _onModalDisconnect(ModalDisconnect? event) {
      log.i('[initializewm3Service] _onModalDisconnect ${event?.toString()}');
    }

    void _onModalError(ModalError? event) {
      log.i('[initializewm3Service] _onModalError ${event?.toString()}');
      // When user connected to Coinbase Wallet but Coinbase Wallet does not have a session anymore
      // (for instance if user disconnected the dapp directly within Coinbase Wallet)
      // Then Coinbase Wallet won't emit any event
      if ((event?.message ?? '').contains('Coinbase Wallet Error')) {
        // service.disconnect();
      }
    }

    void _onSessionExpired(SessionExpire? event) {
      log.i('[initializewm3Service] _onSessionExpired ${event?.toString()}');
    }

    void _onSessionUpdate(SessionUpdate? event) {
      log.i('[initializewm3Service] _onSessionUpdate ${event?.toString()}');
    }

    void _onSessionEvent(SessionEvent? event) {
      log.i('[initializewm3Service] _onSessionEvent ${event?.toString()}');
    }

    void _onRelayClientConnect(EventArgs? event) {
      // final BuildContext context = Get.context!;
      // showTextToast(text: 'Relay connected', context: context);
      log.i('Relay connected');
    }

    void _onRelayClientError(EventArgs? event) {
      log.i('[initializewm3Service] _onRelayClientError ${event?.toString()}');
    }

    void _onRelayClientDisconnect(EventArgs? event) {
      log.i('Relay disconnected: ${event?.toString()}');
    }

    _w3mService.onModalConnect.subscribe(_onModalConnect);
    _w3mService.onModalNetworkChange.subscribe(_onModalNetworkChange);
    _w3mService.onModalDisconnect.subscribe(_onModalDisconnect);
    _w3mService.onModalError.subscribe(_onModalError);
    // session related subscriptions
    _w3mService.onSessionExpireEvent.subscribe(_onSessionExpired);
    _w3mService.onSessionUpdateEvent.subscribe(_onSessionUpdate);
    _w3mService.onSessionEventEvent.subscribe(_onSessionEvent);
    // relayClient subscriptions
    _w3mService.appKit!.core.relayClient.onRelayClientConnect.subscribe(
      _onRelayClientConnect,
    );
    _w3mService.appKit!.core.relayClient.onRelayClientError.subscribe(
      _onRelayClientError,
    );
    _w3mService.appKit!.core.relayClient.onRelayClientDisconnect.subscribe(
      _onRelayClientDisconnect,
    );

    try {
      await _w3mService.init();
      _startListeningToCheerBoEvents();
      final chainId = externalWalletChianId;
      // ignore: unnecessary_null_comparison
      if (chainId != null && chainId.isNotEmpty) {
        await _w3mService.selectChain(
          ReownAppKitModalNetworks.getNetworkById(Env.chainNamespace, chainId),
          switchChain: true,
        );
        _w3mService.loadAccountData().then((_) {
          w3serviceInitialized.value = true;
        });
      }
    } catch (e) {
      log.f('Error initializing W3MService', error: e);
    }
    return _w3mService;
  }

  static String retrieveConnectedWallet(ReownAppKitModal _w3mService) {
    final GlobalController globalController = Get.find<GlobalController>();
    if (globalController.web3ModalService.session == null) {
      return '';
    }
    final session = _w3mService.session!;
    final accounts = session.getAccounts();
    final currentNamespace = '${Env.chainNamespace}:${externalWalletChianId}';
    if (accounts != null && accounts.isNotEmpty) {
      final chainsNamespaces = NamespaceUtils.getChainsFromAccounts(accounts);
      if (chainsNamespaces.contains(currentNamespace)) {
        final account = accounts.firstWhere(
          (account) => account.contains('$currentNamespace:'),
        );
        final address = account.replaceFirst('$currentNamespace:', '');
        return address;
      } else {
        return '';
      }
    } else {
      return '';
    }
  }

  static _startListeningToCheerBoEvents() {
    ////
    final cheerEventToListenTo = _getContractEventListener(
        contract: cheerBooContract, eventName: 'Cheer');
    // cheerEventToListenTo.take(1).listen((event) {
    //   log.i('^^^^^^^^^^^^^^^^^^^^Cheer event: $event^^^^^^^^^^^^^^^^^^^');
    // });
    ////
    final booEventToListenTo =
        _getContractEventListener(contract: cheerBooContract, eventName: 'Boo');
    // booEventToListenTo.take(1).listen((event) {
    //   log.i('^^^^^^^^^^^^^^^Boo event: $event^^^^^^^^^^^^^^^^^^^^^');
    // });
    ////
  }
}

Stream<FilterEvent> _getContractEventListener({
  required DeployedContract contract,
  required String eventName,
  chainId = Env.initialExternalWalletChainId,
}) {
  final chain = ReownAppKitModalNetworks.getNetworkById(Env.chainNamespace,
      chainId)!; // final GlobalController globalController = Get.find<GlobalController>();
  // final web3ModalService = globalController.web3ModalService;
  // final web3Client = web3ModalService.reconnectRelay();
  // final web3Client = Web3Client(chain.rpcUrl, Client());
  final client = Web3Client(
    chain.rpcUrl,
    Client(),
    // socketConnector: () {
    //   return IOWebSocketChannel.connect(chain.rpcUrl.replaceAll('https', 'ws'))
    //       .cast<String>();
    // },
  );

  final event = contract.event(eventName);

  final options = FilterOptions(
    address: contract.address,
    fromBlock: BlockNum.genesis(),
    toBlock: BlockNum.current(),
    topics: [
      // [bytesToHex(event.signature, padToEvenLength: true, include0x: true)],
    ],
  );
  // final options = FilterOptions.events(
  //   contract: contract,
  //   event: event,
  // );
  return client.events(options);
}
