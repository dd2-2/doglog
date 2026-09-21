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

## 2026-09-18 (추가 작업)
- **일정 추가 안 되는 버그 근본 원인 발견+수정**: `notification_service.dart`의 `init()`이
  `tz.setLocalLocation(...)`을 호출하지 않고 있었음 → `scheduleForItem`이 내부적으로 쓰는 `tz.local`이
  미설정 상태라 항상 예외 발생 → 당시엔 `_save()`가 DB저장과 알림예약을 하나의 try/catch로 묶어놨었기
  때문에, 알림예약 단계에서 나는 예외 때문에 사용자 입장에선 일정 저장 자체가 항상 실패하는 것처럼
  보였음. `tz.setLocalLocation(tz.getLocation('Asia/Seoul'))` 추가로 근본 원인 해결 + 앞으로 같은 종류
  버그를 방지하기 위해 DB저장 try/catch와 알림예약 try/catch를 분리(알림예약 실패는 더 이상 저장 자체를
  막지 않음, DB저장 실패만 스낵바+폼 유지)
- **일정 추가 폼 간소화**: 종류(type) 드롭다운과 알림 on/off 스위치 제거, 제목/날짜/메모/반복주기
  (없음·1주일마다·1개월마다)만 남김. DB의 `type` 컬럼은 항상 `ScheduleType.other`로 고정 저장(스키마는
  안 건드림)
- **일정 캘린더 날짜 선택 연동**: `+` FAB 또는 캘린더 날짜 더블탭 시 선택된(또는 포커스된) 날짜가 미리
  채워진 상태로 일정 추가 폼이 열리도록 `ScheduleFormScreen`에 `initialDate` 파라미터 추가
- **디자인 전면 재전환(소프트페이퍼 → 화이트+블랙)**: 사용자가 "전체적으로 너무 칙칙하다 클리어한 느낌의
  화이트 & 세련된 블랙으로 가자"고 요청 → `AppColors` 전체를 그레이스케일/블랙 위주로 교체(배경/카드 순백
  #FFFFFF, 포인트 컬러 #1A1A1A~#000000 계열, 식별자명 coral/mint 등은 디프 최소화를 위해 그대로 유지하고
  값만 교체). 듀얼 그림자 뉴모피즘 `SoftCard`는 순백 배경에서 잘 안 보여 단일 그림자+얇은 보더 방식으로
  재설계. 지출 화면 카테고리 색상도 그레이스케일 램프로 교체
- **앱 아이콘 재생성**: "아이콘은 너가 대충 만들어줘"라는 요청으로 Kling(gpt-image-2)으로 흰 배경에 검정
  발바닥(#141414) 아이콘 재생성, 기존 코랄 발바닥 아이콘 교체
- 빌드 성공(run 35312681163) 확인 후 APK를 `build\petlog.apk`로 다운로드, Appetize.io에 재업로드
  (새 publicKey는 `reference_appetize_petlog.md` 참고)
- 체중 기록이 1개뿐일 때 fl_chart 라인차트가 x축 범위 0~0인 축소 상태로 이상하게 표시되던 문제 →
  기록 1개일 때는 그래프 대신 카드형 숫자 표시로 대체(2개 이상일 땐 기존 그래프 + 아래 개별 목록)
- 체중/건강 기록 각 항목을 더블탭하면 수정 팝업이 뜨도록 추가(삭제 버튼도 같이 제공),
  `AppDatabase`에 `updateWeight`/`updateHealthLog` 메서드 추가
- 체중/건강 기록 추가·수정 팝업에서 저장 버튼을 하단 전체폭 버튼 → 제목 옆 상단 우측 TextButton으로 이동
  (수정 모드에서는 삭제 아이콘도 그 옆에 나란히 배치)

## 2026-09-21 웹 프리뷰 버전 추가
Appetize.io는 월 30분 제한이 있어 사용자가 더 가볍게 바로 열어볼 수 있는 브라우저 버전을 요청
("프리뷰하게 웹페이지 버전도 만들어줘") → 같은 Flutter 소스를 `flutter build web`으로도 빌드해
GitHub Pages(`https://dd2-2.github.io/doglog/`)에 배포하도록 확장.

**문제**: 기존 데이터 계층이 drift+sqlite3 FFI(`dart:ffi`, `dart:io`, `path_provider`)로 짜여있어
그대로는 웹 컴파일 자체가 안 됨(dart:ffi는 web 타겟에 없음). sqlite3 wasm 바이너리를 받아 진짜
persistent DB를 웹에서 돌리는 방법도 있지만, 버전 호환이 안 맞는 wasm을 받으면 로컬 검증 없이
CI만으로 여러 번 삽질할 위험이 커서 이번엔 채택 안 함.

**해결**: 화면들은 `databaseProvider`(Riverpod) 하나만 통해서 DB를 참조하고 있던 구조를 활용해,
- `lib/data/petlog_db.dart`: `AppDatabase`/웹용 구현체가 공통으로 구현하는 추상 인터페이스 `PetlogDb` 신설
- `lib/data/mock_database.dart`: `PetlogDb`를 구현하는 인메모리 `MockAppDatabase` 신설 — 실제 sqlite 없이
  `List` + `Stream.multi`로 drift의 `watch()` 반응형 스트림을 흉내냄, 데모 데이터(반려견 1마리+일정/체중/
  건강/지출 샘플)로 시드. 새로고침하면 초기 상태로 리셋(웹 프리뷰 용도라 영구저장 불필요하다고 판단)
- `lib/providers/database_provider.dart`: `kIsWeb`이면 `MockAppDatabase`, 아니면 기존 `AppDatabase`를
  반환하도록 분기, 타입을 `Provider<PetlogDb>`로 변경
- `lib/data/database.dart`의 `_openConnection`(dart:io/ffi 사용)을 `lib/data/connection/` 아래
  조건부 임포트(`if (dart.library.io)`)로 분리 — 이렇게 해야 `database.dart` 자체가 웹 컴파일 유닛에
  포함돼도 dart:ffi를 끌어오지 않음(AppDatabase는 웹에서 아예 생성되지 않으므로 connection_stub.dart의
  UnsupportedError는 실제로 호출 안 됨)
- 알림(`NotificationService`)은 `kIsWeb`이면 init/schedule/cancel 전부 즉시 return하도록 가드 — 웹
  프리뷰에서 브라우저 알림 권한 팝업이 뜨는 걸 방지
- 반려동물 사진(`dog.photoPath`)을 `FileImage(File(...))`로 읽던 3곳(dog_selector.dart, home_screen.dart,
  dog_form_screen.dart)을 `lib/widgets/photo_image.dart` 조건부 임포트로 교체 — 네이티브는 기존과 동일
  `FileImage`, 웹은 image_picker가 돌려주는 blob: URL을 `NetworkImage`로 바로 로드
- `.github/workflows/deploy-web.yml` 신규: `flutter create --platforms=web`으로 web/ 폴더를 매 빌드마다
  새로 생성(android/와 동일 패턴, git에 커밋 안 함) → `flutter build web --release --base-href /doglog/`
  → `actions/upload-pages-artifact` + `actions/deploy-pages`로 GitHub Pages 배포
- **알려진 한계**: 웹 버전은 데이터가 브라우저 세션에만 존재(새로고침 시 리셋), 로컬 알림 없음, 반려동물
  등록 시 사진은 그 세션 동안만 보임(파일로 영구 저장 안 됨) — "진짜 앱"이 아니라 UI/기능 프리뷰 목적
- **사용자 확인 필요**: GitHub 저장소(dd2-2/doglog) Settings → Pages에서 Source가 "GitHub Actions"로
  되어 있어야 배포됨(레포에 Pages를 처음 켜는 경우 수동 설정이 필요할 수 있음) — 빌드 성공해도 이 설정이
  안 돼 있으면 실제 페이지가 안 뜰 수 있어 확인 필요
