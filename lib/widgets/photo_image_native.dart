import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider photoImageProvider(String path) => FileImage(File(path));
