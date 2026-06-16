#!/bin/bash
export FLUTTER_ROOT="/c/flutter"
export PUB_HOSTED_URL="https://pub.dartlang.org"
export FLUTTER_STORAGE_BASE_URL="https://storage.googleapis.com"

# All paths Flutter/Gradle/Windows needs
export PATH="/c/flutter/bin/cache/dart-sdk/bin:/c/flutter/bin:/c/flutter/bin/mingit:/mingw64/bin:/c/Program Files/Git/cmd:/c/Windows/System32/WindowsPowerShell/v1.0:/c/Windows/System32:/c/Windows:$PATH"

exec /c/flutter/bin/cache/dart-sdk/bin/dart.exe /c/flutter/bin/cache/flutter_tools.snapshot "$@"
