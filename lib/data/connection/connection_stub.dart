import 'package:drift/drift.dart';

/// 웹 등 네이티브 파일시스템이 없는 플랫폼용 기본 구현.
/// 이 플랫폼에서는 AppDatabase 대신 MockAppDatabase를 쓰므로 실제로 호출되지 않는다.
QueryExecutor openConnection() {
  throw UnsupportedError(
    'AppDatabase는 이 플랫폼에서 지원하지 않습니다. MockAppDatabase를 사용하세요.',
  );
}
