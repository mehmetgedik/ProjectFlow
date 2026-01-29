' Emulatoru konsol penceresi acmadan baslatir; sadece cihaz penceresi gorunur.
Set sh = CreateObject("WScript.Shell")
emulatorPath = sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Android\Sdk\emulator\emulator.exe"
sh.Run """" & emulatorPath & """ -avd Medium_Phone_API_36.1", 0, False
