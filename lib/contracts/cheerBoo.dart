import 'package:podium/env.dart';

class CheerBoo {
  static const address = Env.cheerBooAddress_Movement_Devnet;
  static const abi = [
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "target",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address[]",
          "name": "detractors",
          "type": "address[]"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "Boo",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "target",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address[]",
          "name": "supporters",
          "type": "address[]"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "Cheer",
      "type": "event"
    },
    {
      "inputs": [
        {"internalType": "address", "name": "target", "type": "address"},
        {"internalType": "address[]", "name": "addresses", "type": "address[]"},
        {"internalType": "bool", "name": "cheer", "type": "bool"}
      ],
      "name": "cheerOrBoo",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "FEE_ADDRESS",
      "outputs": [
        {"internalType": "address", "name": "", "type": "address"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "FEE_PERCENTAGE",
      "outputs": [
        {"internalType": "uint256", "name": "", "type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ];
}
