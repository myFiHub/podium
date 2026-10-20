import 'package:get/get.dart';
import 'package:podium/app/modules/login/views/prejoin_referral_view.dart';
import 'package:podium/app/modules/myProfile/views/connected_accounts_view.dart';
import 'package:podium/app/modules/outpostDetail/views/outpost_by_id_landing.dart';
import 'package:podium/app/modules/records/bindings/records_binding.dart';
import 'package:podium/app/modules/records/views/records_view.dart';
import 'package:podium/app/modules/replay/bindings/replay_binding.dart';
import 'package:podium/app/modules/replay/views/replay_view.dart';

import '../modules/allOutposts/views/tag_outposts_view.dart';
import '../modules/hostAnalytics/views/host_dashboard_view.dart';
import '../modules/hostAnalytics/views/host_outpost_analytics_view.dart';
import '../modules/createOutpost/bindings/create_outpost_binding.dart';
import '../modules/createOutpost/views/create_outpost_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/myProfile/bindings/my_profile_binding.dart';
import '../modules/ongoingOutpostCall/views/ongoing_outpost_call_view.dart';
import '../modules/outpostDetail/bindings/outpost_detail_binding.dart';
import '../modules/outpostDetail/views/outpost_detail_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/tabs/bindings/tabs_binding.dart';
import '../modules/tabs/views/tabs_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    for (final name in [
      _Paths.HOME,
      _Paths.ALL_OUTPOSTS,
      _Paths.SEARCH,
      _Paths.NOTIFICATIONS,
      _Paths.MY_PROFILE,
    ])
      GetPage(
        name: name,
        page: () => const TabsView(),
        binding: TabsBinding(),
        transition: Transition.noTransition,
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
      page: () => const OutpostDetailView(),
      binding: GroupDetailBinding(),
      children: [
        GetPage(
          name: '/:id',
          page: () => const GroupByIdLandingScreen(),
          transition: Transition.native,
          preventDuplicates: false,
        ),
      ],
    ),
    GetPage(
      name: _Paths.ONGOING_OUTPOST_CALL,
      page: () => const OngoingGroupCallView(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.CONNECTED_ACCOUNTS,
      page: () => const ConnectedAccountsView(),
      binding: MyProfileBinding(),
    ),
    GetPage(
      name: _Paths.RECORDS,
      page: () => const RecordsPage(),
      binding: RecordsBinding(),
    ),
    GetPage(
      name: _Paths.REPLAY,
      page: () => const ReplayView(),
      binding: ReplayBinding(),
    ),
    GetPage(
      name: _Paths.TAG_OUTPOSTS,
      page: () => const TagOutpostsView(),
      preventDuplicates: false,
    ),
    GetPage(
      name: _Paths.HOST_DASHBOARD,
      page: () => const HostDashboardView(),
    ),
    GetPage(
      name: _Paths.HOST_OUTPOST_ANALYTICS,
      page: () => const HostOutpostAnalyticsView(),
      preventDuplicates: false,
    ),
  ];
}
