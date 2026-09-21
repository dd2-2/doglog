import 'package:flutter/widgets.dart';

/// 'asset:'로 시작하면 pubspec에 번들된 이미지(데모 사진 등).
/// 그 외엔 image_picker가 돌려주는 blob: URL이라 NetworkImage로 바로 로드 가능.
ImageProvider photoImageProvider(String path) {
  if (path.startsWith('asset:')) return AssetImage(path.substring('asset:'.length));
  return NetworkImage(path);
}
