import 'dart:io';

import 'package:flutter/widgets.dart';

/// 'asset:'로 시작하면 pubspec에 번들된 이미지(데모 사진 등), 아니면 실제 파일 경로.
ImageProvider photoImageProvider(String path) => path.startsWith('asset:')
    ? AssetImage(path.substring('asset:'.length))
    : FileImage(File(path));
