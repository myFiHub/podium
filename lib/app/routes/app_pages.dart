import 'package:get/get.dart';
import 'package:podium/app/modules/login/views/prejoin_referral_view.dart';
import 'package:podium/app/modules/outpostDetail/views/outpost_by_id_landing.dart';
import 'package:podium/app/modules/records/bindings/records_binding.dart';
import 'package:podium/app/modules/records/views/records_view.dart';

import '../modules/allOutposts/bindings/all_groups_binding.dart';
import '../modules/allOutposts/views/all_outposts_view.dart';
import '../modules/chat/bindings/chat_binding.dart';
import '../modules/chat/views/chat_view.dart';
import '../modules/createOutpost/bindings/create_outpost_binding.dart';
import '../modules/createOutpost/views/create_outpost_view.dart';
import '../modules/editGroup/bindings/edit_group_binding.dart';
import '../modules/editGroup/views/edit_group_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/myProfile/bindings/my_profile_binding.dart';
import '../modules/myProfile/views/my_profile_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/ongoingOutpostCall/bindings/ongoing_group_call_binding.dart';
import '../modules/ongoingOutpostCall/views/ongoing_outpost_call_view.dart';
import '../modules/outpostDetail/bindings/outpost_detail_binding.dart';
import '../modules/outpostDetail/views/outpost_detail_view.dart';
import '../modules/playground/bindings/playground_binding.dart';
import '../modules/playground/views/playground_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import '../modules/wallet/bindings/wallet_binding.dart';
import '../modules/wallet/views/wallet_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.PREJOIN_REFERRAL_PAGE,
      page: () => const PrejoinReferralView.PreJoin(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REFERRED,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.WEB3AUTH_REDIRECTED,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.WEB3AUTH_REDIRECTED_AUTH,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_OUTPOST,
      page: () => const CreateGroupView(),
      binding: CreateGroupBinding(),
    ),
    GetPage(
      name: _Paths.OUTPOST_DETAIL,
      page: () => const GroupDetailView(),
      binding: GroupDetailBinding(),
      children: [
        GetPage(
          name: '/:id',
          page: () => GroupByIdLandingScreen(),
          transition: Transition.native,
          preventDuplicates: false,
        ),
      ],
    ),
    GetPage(
      name: _Paths.EDIT_OUTPOST,
      page: () => const EditGroupView(),
      binding: EditGroupBinding(),
    ),
    GetPage(
      name: _Paths.CHAT,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: _Paths.ONGOING_OUTPOST_CALL,
      page: () => const OngoingGroupCallView(),
      binding: OngoingGroupCallBinding(),
    ),
    GetPage(
      name: _Paths.WALLET,
      page: () => const WalletView(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.MY_PROFILE,
      page: () => const MyProfileView(),
      binding: MyProfileBinding(),
    ),
    GetPage(
      name: _Paths.RECORDS,
      page: () => const RecordsPage(),
      binding: RecordsBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATIONS,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: _Paths.ALL_OUTPOSTS,
      page: () => const AllOutpostsView(),
      binding: AllGroupsBinding(),
    ),
    GetPage(
      name: _Paths.PLAYGROUND,
      page: () => const PlaygroundView(),
      binding: PlaygroundBinding(),
    ),
  ];
}
