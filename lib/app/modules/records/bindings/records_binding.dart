import 'package:get/get.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';

final recordsBindings = [
  Bind.put<RecordsController>(RecordsController(), permanent: true),
];

class RecordsBinding extends Binding {
  @override
  List<Bind> dependencies() => recordsBindings;
}
