import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

class ChainDataWrapper {
  // static final List<ChainMetadata> chains = [
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.blue,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['1']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.cyan,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['42161']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.purple,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['137']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.red.shade300,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['43114']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.yellow.shade600,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['56']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.red.shade900,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['10']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.green.shade900,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['100']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.purple.shade50,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['324']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.blue.shade100,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['8453']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.yellow,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['42220']!,
  //   ),
  //   ChainMetadata(
  //     type: ChainType.eip155,
  //     color: Colors.green.shade100,
  //     w3mChainInfo: ReownAppKitModalNetworks.chains['1313161554']!,
  //   ),
  // const ChainMetadata(
  //   type: ChainType.solana,
  //   chainId: 'solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ',
  //   name: 'Solana',
  //   logo: 'TODO',
  //   color: Colors.black,
  //   rpc: [
  //     "https://solana-api.projectserum.com",
  //   ],
  // ),
  // ChainMetadata(
  //   type: ChainType.kadena,
  //   chainId: 'kadena:mainnet01',
  //   name: 'Kadena',
  //   logo: 'TODO',
  //   color: Colors.purple.shade600,
  //   rpc: [
  //     "https://api.testnet.chainweb.com",
  //   ],
  // ),
  // ];
}

// String getChainName(String chain) {
//   try {
//     return ChainDataWrapper.chains
//         .where((element) => element.w3mChainInfo.namespace == chain)
//         .first
//         .w3mChainInfo
//         .chainName;
//   } catch (e) {
//     debugPrint('[ExampleApp] getChainName, Invalid chain: $chain');
//   }
//   return 'Unknown';
// }

// ChainMetadata getChainMetadataFromChain(String namespace) {
//   try {
//     return ChainDataWrapper.chains
//         .where((element) => element.w3mChainInfo.namespace == namespace)
//         .first;
//   } catch (_) {
//     return ChainMetadata(
//       color: Colors.blue,
//       type: ChainType.eip155,
//       w3mChainInfo: ReownAppKitModalNetworks.supported['eip155']!.firstWhere(
//         (e) => e.name == namespace,
//       ),
//     );
//   }
// }
