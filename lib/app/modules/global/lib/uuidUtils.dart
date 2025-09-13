import 'package:uuid/uuid.dart';

String? validateUuid(String? value) {
  if (value == null || value.isEmpty) {
    return null; // Allow empty values, validation only when user enters something
  }

  // Check if it's a valid UUID format
  try {
    // Remove any whitespace
    final cleanValue = value.trim();

    // Check if it matches UUID pattern (8-4-4-4-12 format)
    if (!RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(cleanValue)) {
      return 'Please enter a valid UUID format (e.g., 123e4567-e89b-12d3-a456-426614174000)';
    }

    // Try to parse as UUID to ensure it's valid
    Uuid.parse(cleanValue);
    return null; // Valid UUID
  } catch (e) {
    return 'Please enter a valid UUID';
  }
}
