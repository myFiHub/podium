import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';

class ReportForm extends GetView<RecordsController> {
  final String userId;
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  ReportForm({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report User',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'User ID: $userId',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter reason for reporting...',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a reason';
              }
              if (value.length < 10) {
                return 'Reason must be at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    // TODO: Implement report submission
                    Get.back();
                    Get.snackbar(
                      'Success',
                      'Report submitted successfully',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  }
                },
                child: const Text('Submit Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
