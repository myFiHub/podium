import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/logger.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

final movementChain = W3MChainInfo(
  chainName: 'Movement Testnet',
  namespace: 'eip155:30732',
  chainId: '30732',
  chainIcon: "https://docs.movementnetwork.xyz/img/logo.svg",
  tokenName: 'MOVE',
  rpcUrl: 'https://mevm.testnet.imola.movementlabs.xyz',
  blockExplorer: W3MBlockExplorer(
    name: 'movement explorer',
    url: 'https://explorer.testnet.imola.movementlabs.xyz',
  ),
);

class BlockChainUtils {
  static Future<W3MService> initializewm3Service(
    W3MService _w3mService,
    RxString connectedWalletAddress,
    RxBool w3serviceInitialized,
  ) async {
    W3MChainPresets.chains.addAll({
      '30732': movementChain,
    });
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
    _w3mService.web3App!.core.relayClient.onRelayClientConnect.subscribe(
      _onRelayClientConnect,
    );
    _w3mService.web3App!.core.relayClient.onRelayClientError.subscribe(
      _onRelayClientError,
    );
    _w3mService.web3App!.core.relayClient.onRelayClientDisconnect.subscribe(
      _onRelayClientDisconnect,
    );

    try {
      await _w3mService.init();
      const chainId = Env.chainId;
      // ignore: unnecessary_null_comparison
      if (chainId != null && chainId.isNotEmpty) {
        await _w3mService.selectChain(
          W3MChainPresets.chains[chainId],
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

  static String retrieveConnectedWallet(W3MService _w3mService) {
    if (w3mService.session == null) {
      return '';
    }
    final session = _w3mService.session!;
    final accounts = session.getAccounts();
    final currentNamespace = _w3mService.selectedChain?.namespace;
    if (accounts != null) {
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
}
