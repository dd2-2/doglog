import 'package:flutter/widgets.dart';

/// 웹: image_picker가 돌려주는 path는 blob: URL이라 NetworkImage로 바로 로드 가능.
ImageProvider photoImageProvider(String path) => NetworkImage(path);
