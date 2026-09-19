import 'package:connectivity_plus/connectivity_plus.dart';

/// Có mạng (wifi/di động/ethernet…) hay không.
Future<bool> hasNetwork() async {
  final results = await Connectivity().checkConnectivity();
  return results.any((r) => r != ConnectivityResult.none);
}

/// Luồng thay đổi mạng, đã rút gọn còn true/false và bỏ trùng.
Stream<bool> networkChanges() => Connectivity().onConnectivityChanged
    .map((rs) => rs.any((r) => r != ConnectivityResult.none))
    .distinct();
