import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/my_tasks.dart';

class MeRepository {
  MeRepository(this._dio);
  final Dio _dio;

  Future<MyTasksResponse> tasks() async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.myTasks);
    return MyTasksResponse.fromJson(res.data!);
  }
}
