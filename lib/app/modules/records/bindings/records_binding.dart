import 'package:get/get.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/app/modules/records/controllers/replays_controller.dart';

final recordsBindings = [
  Bind.put<RecordsController>(RecordsController(), permanent: true),
  Bind.put<ReplaysController>(ReplaysController(), permanent: true),
];

class RecordsBinding extends Binding {
  @override
  List<Bind> dependencies() => recordsBindings;
}
