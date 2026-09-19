import 'package:flutter/material.dart';

import 'app.dart';
import 'core/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const LabAssetApp());
}
