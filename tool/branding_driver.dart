import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      for (final path in [
        '../docs/superpowers/handoff/ppt/labasset/images',
        '../labasset-web/public/ppt/labasset/images',
        '../labasset-web/public/ppt/medone/images',
      ]) {
        await File('$path/$name.png').writeAsBytes(bytes);
      }
      return true;
    },
  );
}
