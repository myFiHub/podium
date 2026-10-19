import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});
  @override
  Widget build(BuildContext context) {
    return const PageWrapper(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(title: 'Chat', showBack: true),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: AppEmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Chat with user',
                      message: 'Messages will show up here.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
