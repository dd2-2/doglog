"""flutter create로 생성된 AndroidManifest.xml에
flutter_local_notifications 사용에 필요한 권한/리시버를 삽입한다.
(android/ 폴더는 git에 커밋하지 않고 CI에서 매번 새로 생성하므로 빌드 때마다 실행됨)
"""
import re
import sys

path = sys.argv[1]

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

if "POST_NOTIFICATIONS" not in content:
    permissions = (
        '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n'
        '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n'
    )
    content = re.sub(r"(<manifest[^>]*>\n)", r"\1" + permissions, content, count=1)

content = re.sub(
    r'android:label="[^"]*"',
    'android:label="petlog"',
    content,
    count=1,
)

if "ScheduledNotificationBootReceiver" not in content:
    match = re.search(r"([ \t]*)</application>", content)
    indent = match.group(1) if match else "    "
    receivers_lines = [
        '<receiver android:exported="false" '
        'android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">',
        "    <intent-filter>",
        '        <action android:name="android.intent.action.BOOT_COMPLETED"/>',
        '        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>',
        '        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>',
        '        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>',
        "    </intent-filter>",
        "</receiver>",
        '<receiver android:exported="false" '
        'android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>',
    ]
    snippet = "".join(f"{indent}{line}\n" for line in receivers_lines)
    content = re.sub(
        r"[ \t]*</application>",
        snippet + indent + "</application>",
        content,
        count=1,
    )

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"patched {path}")
