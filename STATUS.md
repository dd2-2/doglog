# doglog (강아지 관리수첩) 현황

## 개요
반려견 일정(예방접종/심장사상충/구충/목욕/미용/양치)·건강기록(체중/병원방문/투약)·월별 지출을 관리하는
안드로이드 앱. Flutter + Riverpod + drift(sqlite) + flutter_local_notifications. 다견(여러 마리) 지원.

## 빌드 방식 (중요)
이 개발 PC에는 Flutter/Android SDK/Java가 설치되어 있지 않아 로컬 빌드가 불가능함.
**GitHub Actions에서 클라우드 빌드**하도록 설계됨:
- `android/` 폴더는 git에 커밋하지 않음(.gitignore) — CI가 매 빌드마다
  `flutter create --platforms=android`로 새로 생성한 뒤, `.github/scripts/patch_manifest.py`가
  알림 권한(POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED)과 부팅 후 알림 재등록용 리시버,
  앱 라벨("강아지 관리수첩")을 자동 패치함
- `.github/workflows/build-apk.yml`: push 시 flutter_create → manifest patch →
  `.github/scripts/patch_gradle.py`(core library desugaring 활성화, flutter_local_notifications
  v17+ 필수) → pub get → `dart run build_runner build`(drift 코드젠) → `flutter build apk --release`
  → 아티팩트 업로드
- `*.g.dart`(drift 생성 코드)도 커밋하지 않고 CI에서 매번 생성
- GitHub 저장소: https://github.com/dd2-2/doglog (public)

## 빌드 성공 (2026-09-18)
로컬 미검증 코드라 4번 반복 수정 끝에 CI 그린 — intl 버전 충돌(flutter_localizations가 ^0.20.3 요구) →
flutter_local_notifications 16.3.3의 bigLargeIcon 컴파일 버그(17.0.0으로 업그레이드, desugaring 패치
추가) → zonedSchedule의 uiLocalNotificationDateInterpretation 필수 파라미터 누락. 빌드된 APK는
`H:\000_AI\project\doglog\build\doglog.apk` (약 60MB). 로그 확인용으로 이 PC에 `gh` cli 설치+로그인함
(github.com 계정 dd2-2).

## 완료된 것
- 데이터 모델(drift): Dogs / ScheduleItems / WeightRecords / HealthLogs / Expenses
- 화면 5개: 홈(대시보드) / 일정(캘린더+리마인더) / 건강(체중그래프+기록) / 지출(월별+파이차트) / 설정(반려견관리)
- 반려견 등록/수정/삭제 + 사진(image_picker) + 다견 전환 UI(상단 칩)
- 일정 추가 시 로컬 알림 자동 예약(flutter_local_notifications), 완료 체크 시 주기만큼 다음 알림 재예약
- Material 3 기반 커스텀 테마(크림 배경 + 코랄 포인트 컬러), 한국어 로케일(flutter_localizations)

## 다음 단계
1. 실기기 설치 테스트 (알림 권한 허용, 일정 추가→알림 도착 확인, 반려견 등록/전환, 지출/건강 기록 등) — 사용자가 직접
2. 앱 아이콘 커스터마이징 (현재 기본 Flutter 아이콘)
