import 'package:flutter/material.dart';
import 'package:podium/app/modules/records/views/records.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppPageHeader(
                title: 'Records',
                subtitle: 'Your outpost replays and recordings',
                showBack: true,
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.accent.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_iphone_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Recordings are saved locally on your device',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Records(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
