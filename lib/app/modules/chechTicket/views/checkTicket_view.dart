import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/chechTicket/controllers/checkTicket_controller.dart';
import 'package:podium/app/modules/global/utils/extractAddressFromUserModel.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';

class CheckTicketView extends GetWidget<CheckticketController> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Container(
          color: ColorName.cardBackground,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.close();
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              space10,
              Obx(
                () {
                  final isLoading = controller.loadingUsers.value;
                  final allUsersToBuyTicketFrom =
                      controller.allUsersToBuyTicketFrom.value;
                  final allUsersList = allUsersToBuyTicketFrom.values.toList();
                  return isLoading
                      ? CircularProgressIndicator()
                      : SingleChildScrollView(
                          child: Container(
                            height: Get.height - 190,
                            child: ListView.builder(
                              itemCount: allUsersList.length,
                              itemBuilder: (context, index) {
                                final userInfo = allUsersList[index].userInfo;
                                final boughtTicketToAccess =
                                    allUsersList[index].boughtTicketToAccess;
                                final boughtTicketToSpeak =
                                    allUsersList[index].boughtTicketToSpeak;
                                final checking = allUsersList[index].checking;
                                final address = allUsersList[index].address;
                                final shouldBuyTicketToAccess =
                                    !boughtTicketToAccess;
                                final shouldBuyTicketToSpeak =
                                    !boughtTicketToSpeak;
                                String actionButtonText = '';
                                if (shouldBuyTicketToSpeak) {
                                  actionButtonText = 'Buy ticket to speak';
                                } else if (shouldBuyTicketToAccess) {
                                  actionButtonText = 'Buy ticket to Enter';
                                }
                                if (shouldBuyTicketToSpeak &&
                                    shouldBuyTicketToAccess) {
                                  actionButtonText =
                                      'Buy ticket to Enter and speak';
                                }
                                return Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: ColorName.pageBackground,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: Get.width - 170,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userInfo.fullName,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            space10,
                                            Text(
                                              truncate(
                                                address,
                                                length: 16,
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        child: checking
                                            ? SizedBox(
                                                child:
                                                    CircularProgressIndicator(),
                                                width: 20,
                                                height: 20,
                                              )
                                            : boughtTicketToAccess &&
                                                    boughtTicketToSpeak
                                                ? Icon(
                                                    Icons.check,
                                                    color: Colors.green,
                                                  )
                                                : Tooltip(
                                                    message: actionButtonText,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        controller.buyTicket(
                                                          userToBuyFrom:
                                                              userInfo,
                                                        );
                                                      },
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.green,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        padding:
                                                            EdgeInsets.all(5),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            if (shouldBuyTicketToAccess)
                                                              Icon(
                                                                Icons.login,
                                                              ),
                                                            if (shouldBuyTicketToSpeak)
                                                              Icon(
                                                                Icons.mic,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
