import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';

const movementIcon =
    "https://pbs.twimg.com/profile_images/1744477796301496320/z7AIB7_W_400x400.jpg";
////////// Aptos chains (these are just to format things and keep things in shape,
/// they are not used for anything else since they are not supported by the appkit)

const movementAptosBardokChain = ReownAppKitModalNetworkInfo(
  name: 'Movement Testnet',
  chainId: '250',
  chainIcon: movementIcon,
  currency: 'MOVE',
  rpcUrl: 'https://aptos.testnet.bardock.movementlabs.xyz/v1',
  explorerUrl: 'https://explorer.movementlabs.xyz',
);

const movementTestnet = ReownAppKitModalNetworkInfo(
  name: 'Movement Aptos Testnet',
  chainId: '177',
  chainIcon: movementIcon,
  currency: 'MOVE',
  rpcUrl: 'https://aptos.testnet.porto.movementlabs.xyz/v1',
  explorerUrl: 'https://explorer.movementlabs.xyz',
);

///////////////////
const movementEVMMainNetChain = ReownAppKitModalNetworkInfo(
  name: 'Movement',
  chainId: '126',
  chainIcon: movementIcon,
  currency: 'MOVE',
  rpcUrl: 'https://mainnet.movementnetwork.xyz/v1',
  explorerUrl: 'https://explorer.movementnetwork.xyz/?network=mainnet',
);

const movementEVMDevnetChain = ReownAppKitModalNetworkInfo(
  name: 'Movement Testnet',
  chainId: '30732',
  chainIcon: movementIcon,
  currency: 'MOVE',
  rpcUrl: 'https://mevm.devnet.imola.movementlabs.xyz',
  explorerUrl: 'https://explorer.devnet.imola.movementlabs.xyz',
);
const movementEVMChain = movementEVMDevnetChain;

class BlockChainUtils {
  static Future<ReownAppKitModal> initializewm3Service(
    ReownAppKitModal w3mService,
    RxString connectedWalletAddress,
    RxBool w3serviceInitialized,
  ) async {
    w3mService.addListener(() async {
      if (w3mService.session == null) {
        connectedWalletAddress.value = '';
        return;
      }
      final address = await retrieveConnectedWallet(w3mService);
      connectedWalletAddress.value = address;
    });
    void onModalConnect(ModalConnect? event) async {
      if (w3mService.session == null) {
        connectedWalletAddress.value = '';
        return;
      }
      final address = await retrieveConnectedWallet(w3mService);
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
      l.d('Connected Wallet Address: ${connectedWalletAddress.value}, chainId: ${w3mService.session?.chainId}');
      l.i('[initializewm3Service] _onModalConnect ${event?.toString()}');
    }

    // ignore: unused_element
    void onModalUpdate(ModalConnect? event) {
      l.i('[initializewm3Service] _onModalUpdate ${event?.toString()}');
    }

    void onModalNetworkChange(ModalNetworkChange? event) async {
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

    void onModalDisconnect(ModalDisconnect? event) {
      l.i('[initializewm3Service] _onModalDisconnect ${event?.toString()}');
    }

    void onModalError(ModalError? event) {
      l.i('[initializewm3Service] _onModalError ${event?.toString()}');
    }

    void onSessionExpired(SessionExpire? event) {
      l.i('[initializewm3Service] _onSessionExpired ${event?.toString()}');
    }

    void onSessionUpdate(SessionUpdate? event) {
      l.i('[initializewm3Service] _onSessionUpdate ${event?.toString()}');
    }

    void onSessionEvent(SessionEvent? event) {
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

    void onRelayClientConnect(EventArgs? event) {
      l.i('Relay connected');
    }

    void onRelayClientError(EventArgs? event) {
      l.i('[initializewm3Service] _onRelayClientError ${event?.toString()}');
    }

    void onRelayClientDisconnect(EventArgs? event) {
      l.i('Relay disconnected: ${event?.toString()}');
    }

    w3mService.onModalConnect.subscribe(onModalConnect);
    w3mService.onModalNetworkChange.subscribe(onModalNetworkChange);
    w3mService.onModalDisconnect.subscribe(onModalDisconnect);
    w3mService.onModalError.subscribe(onModalError);
    // session related subscriptions
    w3mService.onSessionExpireEvent.subscribe(onSessionExpired);
    w3mService.onSessionUpdateEvent.subscribe(onSessionUpdate);
    w3mService.onSessionEventEvent.subscribe(onSessionEvent);
    // relayClient subscriptions
    w3mService.appKit!.core.relayClient.onRelayClientConnect.subscribe(
      onRelayClientConnect,
    );
    w3mService.appKit!.core.relayClient.onRelayClientError.subscribe(
      onRelayClientError,
    );
    w3mService.appKit!.core.relayClient.onRelayClientDisconnect.subscribe(
      onRelayClientDisconnect,
    );

    try {
      await w3mService.init();
      final chainId = externalWalletChianId;
      // ignore: unnecessary_null_comparison
      if (chainId != null && chainId.isNotEmpty) {
        await w3mService.selectChain(
          ReownAppKitModalNetworks.getNetworkInfo(Env.chainNamespace, chainId),
          switchChain: true,
        );
        w3mService.loadAccountData().then((_) {
          w3serviceInitialized.value = true;
        });
      }
    } catch (e) {
      l.f(
        'Error initializing W3MService',
        error: e,
      );
    }
    return w3mService;
  }

  static Future<String> retrieveConnectedWallet(
      ReownAppKitModal w3mService) async {
    final GlobalController globalController = Get.find<GlobalController>();
    if (globalController.web3ModalService.session == null) {
      return '';
    }
    if (w3mService.session == null) {
      return '';
    }
    final session = w3mService.session;
    final connectedChain = session!.chainId;
    String chainId = connectedChain;

    final accounts = session.getAccounts();
    final currentNamespace = '${Env.chainNamespace}:$chainId';
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
}
