import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/luma/models/eventModel.dart';
import 'package:podium/providers/api/luma/models/guest.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class LumaDetailsDialog extends GetView<OutpostDetailController> {
  const LumaDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final mycurrentIsoTime = DateTime.now().toIso8601String();
    final eventStartAt = controller.lumaEventDetails.value?.event.start_at;
    final isStarted = DateTime.parse(mycurrentIsoTime)
        .isAfter(DateTime.parse(eventStartAt ?? ''));
    return SafeArea(
      child: Material(
        child: Container(
          color: ColorName.cardBackground,
          padding: const EdgeInsets.all(20),
          height: Get.height * 0.5,
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Luma Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isStarted) ...[
                    space10,
                    Shimmer.fromColors(
                      baseColor: Colors.white,
                      highlightColor: Colors.green,
                      child: const Text(
                        "Started",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Get.close();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const _Info(),
              space10,
              const _Contents(),
              space10,
              const _DoneButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatefulWidget {
  const _Info({super.key});

  @override
  State<_Info> createState() => _InfoState();
}

class _InfoState extends State<_Info> {
  late final ScrollController eventNameController;
  late final ScrollController descriptionController;
  final OutpostDetailController controller =
      Get.find<OutpostDetailController>();

  @override
  void initState() {
    super.initState();
    eventNameController = ScrollController();
    descriptionController = ScrollController();
  }

  @override
  void dispose() {
    eventNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void startAutoScroll(ScrollController controller) {
    if (!mounted) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (controller.hasClients) {
        final maxScroll = controller.position.maxScrollExtent;
        if (maxScroll > 0) {
          controller
              .animateTo(
            maxScroll,
            duration: const Duration(seconds: 3),
            curve: Curves.linear,
          )
              .then((_) {
            if (!mounted) return;
            Future.delayed(const Duration(seconds: 1), () {
              if (!mounted) return;
              controller
                  .animateTo(
                0,
                duration: const Duration(seconds: 3),
                curve: Curves.linear,
              )
                  .then((_) {
                if (mounted) {
                  startAutoScroll(controller);
                }
              });
            });
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 5, top: 5),
      decoration: BoxDecoration(
        color: ColorName.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColorName.primaryBlue),
      ),
      width: Get.width - 10,
      child: Obx(() {
        final event = controller.lumaEventDetails.value;
        final outpost = controller.outpost.value;
        final mycurrentIsoTime = DateTime.now().toIso8601String();
        final eventStartAt = controller.lumaEventDetails.value?.event.start_at;
        final isStarted = DateTime.parse(mycurrentIsoTime)
            .isAfter(DateTime.parse(eventStartAt ?? ''));

        // Start auto-scrolling when the widget is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          startAutoScroll(eventNameController);
          startAutoScroll(descriptionController);
        });

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Event Name:',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                space10,
                Expanded(
                  child: SingleChildScrollView(
                    controller: eventNameController,
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      event?.event.name ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (outpost?.subject.isNotEmpty ?? false) ...[
              space10,
              Row(
                children: [
                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  space10,
                  Expanded(
                    child: SingleChildScrollView(
                      controller: descriptionController,
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        outpost?.subject ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            space10,
            Row(
              children: [
                const Text(
                  'Time Zone:',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                space10,
                Text(
                  event?.event.timezone ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (!isStarted) ...[
              space10,
              Row(
                children: [
                  const Text(
                    'Start Time:',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  space10,
                  Text(
                    _isoStringToDate(event?.event.start_at ?? ''),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ]
          ],
        );
      }),
    );
  }
}

String _isoStringToDate(String isoString) {
  final date = DateTime.parse(isoString);
  return DateFormat('yyyy/MM/dd hh:mm a').format(date);
}

class _Contents extends GetView<OutpostDetailController> {
  const _Contents({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            toolbarHeight: 0,
            bottom: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: ColorName.primaryBlue,
              labelColor: ColorName.primaryBlue,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Obx(() {
                  final hosts = controller.lumaHosts.value;
                  return Tab(text: "Hosts (${hosts.length})");
                }),
                Obx(() {
                  final guests = controller.lumaEventGuests.value;
                  return Tab(text: "Guests (${guests.length})");
                }),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Obx(() {
                final hosts = controller.lumaHosts.value;
                return ListView.builder(
                  itemBuilder: (context, index) {
                    return _HostItem(host: hosts[index]);
                  },
                  itemCount: hosts.length,
                );
              }),
              Obx(() {
                final guests = controller.lumaEventGuests.value;
                return ListView.builder(
                  itemBuilder: (context, index) {
                    return _GuestItem(guest: guests[index]);
                  },
                  itemCount: guests.length,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _HostItem extends StatelessWidget {
  final Luma_HostModel host;
  const _HostItem({super.key, required this.host});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 5, top: 5),
      decoration: BoxDecoration(
        color: ColorName.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColorName.primaryBlue),
      ),
      width: Get.width - 10,
      child: Row(
        children: [
          Img(src: host.avatar_url),
          space10,
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (host.name.isNotEmpty)
                Text(
                  host.name ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                truncate(host.email) ?? '',
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestItem extends StatelessWidget {
  final GuestDataModel guest;
  const _GuestItem({super.key, required this.guest});

  @override
  Widget build(BuildContext context) {
    final status = guest.approval_status;
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 5, top: 5),
      decoration: BoxDecoration(
        color: ColorName.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ColorName.primaryBlue,
        ),
      ),
      width: Get.width - 10,
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (guest.user_name?.isNotEmpty ?? false)
                Text(
                  guest.user_name ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                truncate(guest.user_email) ?? '',
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (status == 'pending')
            const Icon(
              Icons.pending,
              color: Colors.yellow,
            ),
          if (status == 'approved')
            const Icon(
              Icons.check,
              color: Colors.green,
            ),
          if (status == 'rejected')
            const Icon(
              Icons.close,
              color: Colors.red,
            ),
        ],
      ),
    );
  }
}

class _DoneButton extends GetView<OutpostDetailController> {
  const _DoneButton({super.key});
  @override
  Widget build(BuildContext context) {
    final eventLink = controller.lumaEventDetails.value?.event.url;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: Get.width / 2 - 25,
          child: Button(
            type: ButtonType.outline,
            size: ButtonSize.LARGE,
            color: ColorName.primaryBlue,
            textStyle: const TextStyle(
              fontSize: 12,
              color: ColorName.primaryBlue,
            ),
            text: 'Share Luma Link',
            onPressed: () {
              Share.share(
                eventLink ?? '',
              );
            },
          ),
        ),
        space10,
        SizedBox(
          width: Get.width / 2 - 25,
          child: Button(
            type: ButtonType.outline,
            size: ButtonSize.LARGE,
            textColor: Colors.red,
            color: Colors.red,
            text: 'Close',
            onPressed: () {
              Get.close();
            },
          ),
        ),
      ],
    );
  }
}

openLumaDetailsDialog() {
  Get.dialog(
    const LumaDetailsDialog(),
  );
}
