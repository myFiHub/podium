import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/widgets/button/button.dart';

class ReportForm extends GetView<OngoingOutpostCallController> {
  final _formKey = GlobalKey<FormState>();

  final _maxLength = 250;

  ReportForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          TextFormField(
            maxLines: 3,
            maxLength: _maxLength,
            onChanged: (value) => controller.reportReason.value = value,
            decoration: const InputDecoration(
              hintText: 'Enter reason for reporting...',
              border: OutlineInputBorder(),
              counterText: '',
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
          Align(
            alignment: Alignment.centerRight,
            child: Obx(() => Text(
                  '${controller.reportReason.value.length}/$_maxLength',
                  style: TextStyle(
                    color: controller.reportReason.value.length >= _maxLength
                        ? Colors.red
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                )),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.reportReason.value = '';
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              Obx(() {
                final isFormValid = _isFormValid();
                final reason = controller.reportReason.value;
                return Button(
                  text: 'Submit Report',
                  size: ButtonSize.SMALL,
                  type: ButtonType.solid,
                  color: isFormValid ? Colors.green : Colors.grey,
                  onPressed: isFormValid
                      ? () {
                          if (_formKey.currentState?.validate() ?? false) {
                            Navigator.pop(context);
                            controller.report();
                          }
                        }
                      : null,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    final reason = controller.reportReason.value;
    return reason.isNotEmpty &&
        reason.length >= 10 &&
        reason.length <= _maxLength;
  }
}
