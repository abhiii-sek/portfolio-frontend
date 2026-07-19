import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/modules/admin/controllers/admin_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminController>(() => AdminController());
  }
}
