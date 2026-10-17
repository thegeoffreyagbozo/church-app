import 'dart:typed_data';

/// The pixel size of an image.
class ImageSize {
  const ImageSize(this.width, this.height);
  final int width;
  final int height;
}

const _signature = [137, 80, 78, 71, 13, 10, 26, 10];

/// The size of the PNG in [bytes], read from its header; null when it isn't a PNG.
ImageSize? pngSize(Uint8List bytes) {
  if (bytes.length < 24) return null;
  for (var i = 0; i < _signature.length; i++) {
    if (bytes[i] != _signature[i]) return null;
  }
  if (String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') return null;
  final data = ByteData.sublistView(bytes);
  return ImageSize(data.getUint32(16), data.getUint32(20));
}
