import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/web3AuthClient.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';

const movementIcon =
    "https://pbs.twimg.com/profile_images/1744477796301496320/z7AIB7_W_400x400.jpg";
////////// Aptos chains (these are just to format things and keep things in shape,
/// they are not used for anything else since they are not supported by the appkit)

final movementAptosBardokChain = ReownAppKitModalNetworkInfo(
  name: 'Movement Testnet',
  chainId: '250',
  chainIcon: movementIcon,
  currency: 'MOVE',
  rpcUrl: 'https://aptos.testnet.bardock.movementlabs.xyz/v1',
  explorerUrl: 'https://explorer.movementlabs.xyz',
);

final movementTestnet = ReownAppKitModalNetworkInfo(
  name: 'Movement Aptos Testnet',
  chainId: '177',
  chainIcon: movementIcon,
  currency: 'MOVE',
  rpcUrl: 'https://aptos.testnet.porto.movementlabs.xyz/v1',
  explorerUrl: 'https://explorer.movementlabs.xyz',
);

///////////////////
final movementEVMMainNetChain = ReownAppKitModalNetworkInfo(
  name: 'Movement',
  chainId: '126',
  chainIcon: movementIcon,
  currency: 'MOVE',
  rpcUrl: 'https://mainnet.movementnetwork.xyz/v1',
  explorerUrl: 'https://explorer.movementnetwork.xyz/?network=mainnet',
);

final movementEVMDevnetChain = ReownAppKitModalNetworkInfo(
  name: 'Movement Testnet',
  chainId: '30732',
  chainIcon: movementIcon,
  currency: 'MOVE',
  rpcUrl: 'https://mevm.devnet.imola.movementlabs.xyz',
  explorerUrl: 'https://explorer.devnet.imola.movementlabs.xyz',
);
final movementEVMChain = movementEVMDevnetChain;

class BlockChainUtils {
  static Future<ReownAppKitModal> initializewm3Service(
    ReownAppKitModal _w3mService,
    RxString connectedWalletAddress,
    RxBool w3serviceInitialized,
  ) async {
    // W3MChainPresets.chains.addAll(W3MChainPresets.testChains);
    _w3mService.addListener(() async {
      if (_w3mService.session == null) {
        connectedWalletAddress.value = '';
        return;
      }
      final address = await retrieveConnectedWallet(_w3mService);
      connectedWalletAddress.value = address;
    });
    void _onModalConnect(ModalConnect? event) async {
      if (_w3mService.session == null) {
        connectedWalletAddress.value = '';
        return;
      }
      final address = await retrieveConnectedWallet(_w3mService);
      connectedWalletAddress.value = address;
      if (event != null) {
        String chainId = event.session.chainId;
        if (chainId.contains(':')) {
          chainId = chainId.split(':')[1];
        }
        if (chainId == externalWalletChianId) return;
        final GlobalController globalController = Get.find<GlobalController>();
        await globalController.switchExternalWalletChain(chainId);
      }
      l.d('Connected Wallet Address: ${connectedWalletAddress.value}, chainId: ${_w3mService.session?.chainId}');
      l.i('[initializewm3Service] _onModalConnect ${event?.toString()}');
    }

    // ignore: unused_element
    void _onModalUpdate(ModalConnect? event) {
      l.i('[initializewm3Service] _onModalUpdate ${event?.toString()}');
    }

    void _onModalNetworkChange(ModalNetworkChange? event) async {
      l.i('[initializewm3Service] _onModalNetworkChange ${event?.toString()}');
      if (event != null) {
        GlobalController globalController = Get.find<GlobalController>();

        String chainId = event.chainId;
        if (chainId.contains(':')) {
          chainId = chainId.split(':')[1];
        }
        if (chainId == externalWalletChianId) return;
        await globalController.switchExternalWalletChain(chainId);
      }
    }

    void _onModalDisconnect(ModalDisconnect? event) {
      l.i('[initializewm3Service] _onModalDisconnect ${event?.toString()}');
    }

    void _onModalError(ModalError? event) {
      l.i('[initializewm3Service] _onModalError ${event?.toString()}');
      // When user connected to Coinbase Wallet but Coinbase Wallet does not have a session anymore
      // (for instance if user disconnected the dapp directly within Coinbase Wallet)
      // Then Coinbase Wallet won't emit any event
      if ((event?.message ?? '').contains('Coinbase Wallet Error')) {
        // service.disconnect();
      }
    }

    void _onSessionExpired(SessionExpire? event) {
      l.i('[initializewm3Service] _onSessionExpired ${event?.toString()}');
    }

    void _onSessionUpdate(SessionUpdate? event) {
      l.i('[initializewm3Service] _onSessionUpdate ${event?.toString()}');
    }

    void _onSessionEvent(SessionEvent? event) {
      l.i('[initializewm3Service] _onSessionEvent ${event?.toString()}');
      String? eventChainId = event?.chainId;
      if (eventChainId != null && eventChainId.isNotEmpty) {
        if (eventChainId.contains(':')) {
          eventChainId = eventChainId.split(':')[1];
        }
        if (eventChainId == externalWalletChianId) return;
        final GlobalController globalController = Get.find<GlobalController>();
        globalController.switchExternalWalletChain(eventChainId);
      }
    }

    void _onRelayClientConnect(EventArgs? event) {
      // final BuildContext context = Get.context!;
      // showTextToast(text: 'Relay connected', context: context);
      l.i('Relay connected');
    }

    void _onRelayClientError(EventArgs? event) {
      l.i('[initializewm3Service] _onRelayClientError ${event?.toString()}');
    }

    void _onRelayClientDisconnect(EventArgs? event) {
      l.i('Relay disconnected: ${event?.toString()}');
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
          ReownAppKitModalNetworks.getNetworkInfo(Env.chainNamespace, chainId),
          switchChain: true,
        );
        _w3mService.loadAccountData().then((_) {
          w3serviceInitialized.value = true;
        });
      }
    } catch (e) {
      l.f(
        'Error initializing W3MService',
        error: e,
      );
    }
    return _w3mService;
  }

  static Future<String> retrieveConnectedWallet(
      ReownAppKitModal _w3mService) async {
    final GlobalController globalController = Get.find<GlobalController>();
    if (globalController.web3ModalService.session == null) {
      return '';
    }
    if (_w3mService.session == null) {
      return '';
    }
    final session = _w3mService.session;
    final connectedChain = session!.chainId;
    String chainId = connectedChain;

    // if (externalWalletAddress != null && externalWalletAddress!.isNotEmpty) {
    //   final globalController = Get.find<GlobalController>();
    //   if (connectedChain != externalWalletChianId) {
    //     if (chainId.contains(':')) {
    //       chainId = chainId.split(':')[1];
    //     }
    //     await globalController.switchExternalWalletChain(chainId);
    //   }
    // }

    final accounts = session.getAccounts();
    final currentNamespace = '${Env.chainNamespace}:${chainId}';
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
    //
    // final cheerEventToListenTo = _getContractEventListener(
    //   contract: getDeployedContract(
    //     contract: Contracts.cheerboo,
    //     chainId: movementChain.chainId,
    //   )!,
    //   eventName: 'Cheer',
    // );
    // cheerEventToListenTo.take(1).listen((event) {
    //   l.i('^^^^^^^^^^^^^^^^^^^^Cheer event: $event^^^^^^^^^^^^^^^^^^^');
    // });
    // //
    // final booEventToListenTo = _getContractEventListener(
    //   contract: getDeployedContract(
    //     contract: Contracts.cheerboo,
    //     chainId: movementChain.chainId,
    //   )!,
    //   eventName: 'Boo',
    // );
    // booEventToListenTo.take(1).listen((event) {
    //   l.i('^^^^^^^^^^^^^^^Boo event: $event^^^^^^^^^^^^^^^^^^^^^');
    // });
    //
  }
}

Stream<FilterEvent> _getContractEventStream({
  required DeployedContract contract,
  required String eventName,
}) {
  final event = contract.event(eventName);
  final filter = FilterOptions.events(
    contract: contract,
    event: event,
    fromBlock: const BlockNum.current(),
    toBlock: const BlockNum.current(),
  );
  final movementClient = evmClientByChainId(movementEVMChain.chainId);
  Stream<FilterEvent> eventStream = movementClient.events(filter);
  return eventStream;
}
