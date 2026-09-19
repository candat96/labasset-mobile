import 'package:get/get.dart';

class ShellController extends GetxController {
  final RxInt index = 0.obs;

  void select(int i) => index.value = i;
}
