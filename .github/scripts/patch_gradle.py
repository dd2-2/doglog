"""flutter_local_notifications v17+는 core library desugaring이 필요함.
flutter create가 생성하는 android/app/build.gradle(.kts)을 찾아 패치한다.
"""
import re
import sys
from pathlib import Path

app_dir = Path(sys.argv[1])
kts = app_dir / "build.gradle.kts"
groovy = app_dir / "build.gradle"

if kts.exists():
    path = kts
    is_kts = True
elif groovy.exists():
    path = groovy
    is_kts = False
else:
    print("build.gradle(.kts) not found, skip")
    sys.exit(0)

content = path.read_text(encoding="utf-8")

if "coreLibraryDesugaring" in content:
    print(f"{path} already patched, skip")
    sys.exit(0)

if is_kts:
    desugar_flag = "        isCoreLibraryDesugaringEnabled = true\n"
    desugar_dep = '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n'
else:
    desugar_flag = "        coreLibraryDesugaringEnabled true\n"
    desugar_dep = "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n"

# compileOptions { ... } 블록 맨 앞에 desugaring 활성화 플래그 삽입
match = re.search(r"(compileOptions\s*\{\n)", content)
if not match:
    print(f"ERROR: compileOptions block not found in {path}")
    sys.exit(1)
content = content[: match.end()] + desugar_flag + content[match.end() :]

# dependencies { ... } 블록이 있으면 맨 앞에 추가, 없으면 파일 끝에 새로 생성
dep_match = re.search(r"(dependencies\s*\{\n)", content)
if dep_match:
    content = content[: dep_match.end()] + desugar_dep + content[dep_match.end() :]
else:
    content += f"\ndependencies {{\n{desugar_dep}}}\n"

path.write_text(content, encoding="utf-8")
print(f"patched {path}")
