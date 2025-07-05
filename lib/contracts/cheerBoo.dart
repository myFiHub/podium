class CheerBoo {
  static const abi = [
    {
      "address":
          "0xd2f0d0cf38a4c64620f8e9fcba104e0dd88f8d82963bef4ad57686c3ee9ed7aa",
      "name": "CheerOrBooPodium",
      "friends": [],
      "exposed_functions": [
        {
          "name": "add_param_admin",
          "visibility": "public",
          "is_entry": true,
          "is_view": false,
          "generic_type_params": [],
          "params": ["&signer", "address"],
          "return": []
        },
        {
          "name": "cheer_or_boo",
          "visibility": "public",
          "is_entry": true,
          "is_view": false,
          "generic_type_params": [],
          "params": [
            "&signer",
            "address",
            "vector<address>",
            "bool",
            "u64",
            "u64",
            "vector<u8>"
          ],
          "return": []
        },
        {
          "name": "emergency_pause_upgrades",
          "visibility": "public",
          "is_entry": true,
          "is_view": false,
          "generic_type_params": [],
          "params": ["&signer"],
          "return": []
        },
        {
          "name": "get_config",
          "visibility": "public",
          "is_entry": false,
          "is_view": true,
          "generic_type_params": [],
          "params": [],
          "return": [
            "u64",
            "address",
            "u64",
            "u64",
            "u64",
            "u64",
            "vector<address>",
            "address"
          ]
        },
        {
          "name": "get_max_participants",
          "visibility": "public",
          "is_entry": false,
          "is_view": true,
          "generic_type_params": [],
          "params": [],
          "return": ["u64"]
        },
        {
          "name": "get_migration_status",
          "visibility": "public",
          "is_entry": false,
          "is_view": true,
          "generic_type_params": [],
          "params": [],
          "return": ["u64", "u64", "vector<u64>"]
        },
        {
          "name": "get_upgrade_status",
          "visibility": "public",
          "is_entry": false,
          "is_view": true,
          "generic_type_params": [],
          "params": [],
          "return": ["u64", "u64", "bool", "bool"]
        },
        {
          "name": "initialize",
          "visibility": "public",
          "is_entry": true,
          "is_view": false,
          "generic_type_params": [],
          "params": ["&signer"],
          "return": []
        },
        {
          "name": "is_core_admin",
          "visibility": "public",
          "is_entry": false,
          "is_view": true,
          "generic_type_params": [],
          "params": ["address"],
          "return": ["bool"]
        },
        {
          "name": "is_param_admin",
          "visibility": "public",
          "is_entry": false,
          "is_view": true,
          "generic_type_params": [],
          "params": ["address"],
          "return": ["bool"]
        },
        {
          "name": "remove_param_admin",
          "visibility": "public",
          "is_entry": true,
          "is_view": false,
          "generic_type_params": [],
          "params": ["&signer", "address"],
          "return": []
        },
        {
          "name": "resume_upgrades",
          "visibility": "public",
          "is_entry": true,
          "is_view": false,
          "generic_type_params": [],
          "params": ["&signer"],
          "return": []
        },
        {
          "name": "safe_upgrade",
          "visibility": "public",
          "is_entry": true,
          "is_view": false,
          "generic_type_params": [],
          "params": ["&signer", "vector<u8>", "vector<vector<u8>>", "u64"],
          "return": []
        },
        {
          "name": "update_config",
          "visibility": "public",
          "is_entry": true,
          "is_view": false,
          "generic_type_params": [],
          "params": ["&signer", "u64", "address", "u64", "u64", "u64", "u64"],
          "return": []
        },
        {
          "name": "update_core_admin",
          "visibility": "public",
          "is_entry": true,
          "is_view": false,
          "generic_type_params": [],
          "params": ["&signer", "address"],
          "return": []
        }
      ],
      "structs": [
        {
          "name": "AdminUpdateEvent",
          "is_native": false,
          "abilities": ["drop", "store"],
          "generic_type_params": [],
          "fields": [
            {"name": "admin_address", "type": "address"},
            {"name": "is_add", "type": "bool"},
            {"name": "is_param_admin", "type": "bool"},
            {"name": "timestamp", "type": "u64"}
          ]
        },
        {
          "name": "BooEvent",
          "is_native": false,
          "abilities": ["copy", "drop", "store"],
          "generic_type_params": [],
          "fields": [
            {"name": "target", "type": "address"},
            {"name": "participants", "type": "vector<address>"},
            {"name": "amount", "type": "u64"},
            {"name": "target_allocation", "type": "u64"},
            {"name": "unique_identifier", "type": "vector<u8>"}
          ]
        },
        {
          "name": "CheerEvent",
          "is_native": false,
          "abilities": ["copy", "drop", "store"],
          "generic_type_params": [],
          "fields": [
            {"name": "target", "type": "address"},
            {"name": "participants", "type": "vector<address>"},
            {"name": "amount", "type": "u64"},
            {"name": "target_allocation", "type": "u64"},
            {"name": "unique_identifier", "type": "vector<u8>"},
            {"name": "is_self_cheer", "type": "bool"}
          ]
        },
        {
          "name": "Config",
          "is_native": false,
          "abilities": ["key"],
          "generic_type_params": [],
          "fields": [
            {"name": "fee_percentage", "type": "u64"},
            {"name": "fee_address", "type": "address"},
            {"name": "max_participants", "type": "u64"},
            {"name": "cheer_target_percentage", "type": "u64"},
            {"name": "boo_target_percentage", "type": "u64"},
            {"name": "self_cheer_target_percentage", "type": "u64"},
            {"name": "param_admins", "type": "vector<address>"},
            {"name": "core_admin", "type": "address"},
            {
              "name": "config_events",
              "type":
                  "0x1::event::EventHandle<0xd2f0d0cf38a4c64620f8e9fcba104e0dd88f8d82963bef4ad57686c3ee9ed7aa::CheerOrBooPodium::ConfigUpdateEvent>"
            },
            {
              "name": "admin_events",
              "type":
                  "0x1::event::EventHandle<0xd2f0d0cf38a4c64620f8e9fcba104e0dd88f8d82963bef4ad57686c3ee9ed7aa::CheerOrBooPodium::AdminUpdateEvent>"
            }
          ]
        },
        {
          "name": "ConfigUpdateEvent",
          "is_native": false,
          "abilities": ["drop", "store"],
          "generic_type_params": [],
          "fields": [
            {"name": "fee_percentage", "type": "u64"},
            {"name": "fee_address", "type": "address"},
            {"name": "max_participants", "type": "u64"},
            {"name": "cheer_target_percentage", "type": "u64"},
            {"name": "boo_target_percentage", "type": "u64"},
            {"name": "self_cheer_target_percentage", "type": "u64"},
            {"name": "timestamp", "type": "u64"},
            {"name": "updated_by", "type": "address"}
          ]
        },
        {
          "name": "MigrationError",
          "is_native": false,
          "abilities": ["store"],
          "generic_type_params": [],
          "fields": [
            {"name": "version", "type": "u64"},
            {"name": "timestamp", "type": "u64"},
            {"name": "error_code", "type": "u64"},
            {"name": "error_message", "type": "0x1::string::String"}
          ]
        },
        {
          "name": "MigrationEvent",
          "is_native": false,
          "abilities": ["drop", "store"],
          "generic_type_params": [],
          "fields": [
            {"name": "from_version", "type": "u64"},
            {"name": "to_version", "type": "u64"},
            {"name": "timestamp", "type": "u64"},
            {"name": "success", "type": "bool"},
            {"name": "error_code", "type": "0x1::option::Option<u64>"}
          ]
        },
        {
          "name": "MigrationStatus",
          "is_native": false,
          "abilities": ["key"],
          "generic_type_params": [],
          "fields": [
            {"name": "current_version", "type": "u64"},
            {"name": "last_successful_migration", "type": "u64"},
            {
              "name": "failed_migrations",
              "type":
                  "0x1::table::Table<u64, 0xd2f0d0cf38a4c64620f8e9fcba104e0dd88f8d82963bef4ad57686c3ee9ed7aa::CheerOrBooPodium::MigrationError>"
            },
            {"name": "completed_migrations", "type": "vector<u64>"}
          ]
        },
        {
          "name": "UpgradeCapability",
          "is_native": false,
          "abilities": ["key"],
          "generic_type_params": [],
          "fields": [
            {"name": "version", "type": "u64"},
            {"name": "last_upgrade_time", "type": "u64"},
            {"name": "upgrade_in_progress", "type": "bool"},
            {"name": "emergency_pause", "type": "bool"},
            {
              "name": "upgrade_events",
              "type":
                  "0x1::event::EventHandle<0xd2f0d0cf38a4c64620f8e9fcba104e0dd88f8d82963bef4ad57686c3ee9ed7aa::CheerOrBooPodium::UpgradeEvent>"
            },
            {
              "name": "migration_events",
              "type":
                  "0x1::event::EventHandle<0xd2f0d0cf38a4c64620f8e9fcba104e0dd88f8d82963bef4ad57686c3ee9ed7aa::CheerOrBooPodium::MigrationEvent>"
            }
          ]
        },
        {
          "name": "UpgradeEvent",
          "is_native": false,
          "abilities": ["drop", "store"],
          "generic_type_params": [],
          "fields": [
            {"name": "old_version", "type": "u64"},
            {"name": "new_version", "type": "u64"},
            {"name": "timestamp", "type": "u64"},
            {"name": "success", "type": "bool"},
            {"name": "metadata", "type": "vector<u8>"}
          ]
        }
      ]
    }
  ];
}
