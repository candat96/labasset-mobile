import 'dart:io';

import 'package:image/image.dart' as img;

const _sourcePath = 'assets/brand/logo-1024.png';
const _outputPath = 'assets/brand/logo-adaptive.png';
const _canvasSize = 1024;
const _paddingFraction = 0.18;

void main() {
  final source = img.decodePng(File(_sourcePath).readAsBytesSync());
  if (source == null) {
    throw StateError('Không đọc được $_sourcePath');
  }

  final contentSize = (_canvasSize * (1 - 2 * _paddingFraction)).round();
  final logo = img.copyResize(
    source,
    width: contentSize,
    height: contentSize,
    interpolation: img.Interpolation.average,
  );
  final canvas = img.Image(
    width: _canvasSize,
    height: _canvasSize,
    numChannels: 4,
  );
  img.compositeImage(
    canvas,
    logo,
    dstX: (_canvasSize - contentSize) ~/ 2,
    dstY: (_canvasSize - contentSize) ~/ 2,
  );

  File(_outputPath).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Đã tạo $_outputPath (${contentSize}px, padding 18%).');
}
