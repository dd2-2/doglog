# petlog (반려동물 관리수첩) 현황

## 개요
반려동물 일정(예방접종/심장사상충/구충/목욕/미용/양치)·건강기록(체중/병원방문/투약)·월별 지출을 관리하는
안드로이드 앱. Flutter + Riverpod + drift(sqlite) + flutter_local_notifications. 다견(여러 마리)뿐 아니라
개 외 다른 반려동물도 등록 가능(품종 자유 입력, 종 하드코딩 없음) — UI 문구도 "반려견"이 아닌 "반려동물"로 통일.
**프로젝트 폴더/GitHub 저장소 이름은 `doglog`로 유지**(최초 생성 이름), 앱 자체의 표시 이름/패키지만 `petlog`로 변경.

## 빌드 방식 (중요)
이 개발 PC에는 Flutter/Android SDK/Java가 설치되어 있지 않아 로컬 빌드가 불가능함.
**GitHub Actions에서 클라우드 빌드**하도록 설계됨:
- `android/` 폴더는 git에 커밋하지 않음(.gitignore) — CI가 매 빌드마다 빈 임시 디렉토리에서
  `flutter create --platforms=android --org com.petlog --project-name petlog`로 새로 생성한 뒤 `android/`만
  복사(리포 루트에서 바로 `flutter create .`을 돌리면 기존 pubspec.yaml/lib/와 충돌해 실패함 — 처음 겪은 버그)
- `.github/scripts/patch_manifest.py`: 알림 권한(POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED)과 부팅 후
  알림 재등록용 리시버, 앱 라벨("petlog")을 자동 패치
- `.github/scripts/patch_gradle.py`: core library desugaring 활성화(flutter_local_notifications v17+ 필수,
  android/app/build.gradle(.kts) 둘 다 대응)
- `.github/workflows/build-apk.yml` 순서: flutter create → manifest patch → gradle patch → pub get →
  `dart run flutter_launcher_icons`(앱 아이콘 생성) → `dart run build_runner build`(drift 코드젠) →
  `flutter build apk --release` → 아티팩트 업로드
- `*.g.dart`(drift 생성 코드), 런처 아이콘 산출물도 커밋하지 않고 CI에서 매번 생성
- GitHub 저장소: https://github.com/dd2-2/doglog (public)
- 이 PC에 `gh` cli 설치+로그인 완료(계정 dd2-2, winget 설치, device flow 로그인) — Actions 로그를 API 토큰
  없이 직접 조회 가능. 실패 시 `gh run view <id> --repo dd2-2/doglog --log-failed`로 원인 확인 후 수정 반복

## 디자인
- 완전한 화이트 대신 은은한 페이퍼 그레이 톤 배경(`AppColors.paper` #EEEBE6) + 오프화이트 카드(#FBFAF7)에
  소프트 그림자(elevation+shadowColor)를 줘서 "종이 위에 살짝 떠있는" 느낌 (사용자가 소프트 뉴모피즘 스타일
  레퍼런스 이미지 제공, 2026-09-18)
- 포인트 컬러: 톤다운된 테라코타 코랄(#E8896B), 보조 민트(#7FB89A)
- 앱 아이콘: Kling(gpt-image-2)으로 생성한 코랄 발바닥 아이콘, `assets/icon/icon.png` → CI에서
  `flutter_launcher_icons`로 런처 아이콘 자동 생성 (adaptive icon 없이 legacy 아이콘만, 단순화)

## 완료된 것
- 데이터 모델(drift): Dogs / ScheduleItems / WeightRecords / HealthLogs / Expenses
- 화면 5개: 홈(대시보드, 프로필 사진 표시) / 일정(캘린더+리마인더) / 건강(체중그래프+기록) / 지출(월별+파이차트) / 설정(반려동물 관리)
- 반려동물 등록/수정/삭제 + 사진(image_picker) + 다중 전환 UI(상단 칩), 홈 화면에도 등록 사진 반영
- 일정 추가 시 로컬 알림 자동 예약(flutter_local_notifications), 완료 체크 시 주기만큼 다음 알림 재예약
- 일정 저장 실패 시(DB/알림 예약 오류) 폼을 닫지 않고 스낵바로 에러 안내, 성공 시에만 닫힘
- 한국어 로케일(flutter_localizations)

## 다음 단계
1. 실기기 설치 테스트 (알림 권한 허용, 일정 추가→알림 도착 확인, 반려동물 등록/전환, 지출/건강 기록 등) — 사용자가 직접
