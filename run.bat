@echo off

zig build -freference-trace -Dtarget=native-native-msvc
@REM -Dtarget=native-native-gnu
if %ERRORLEVEL% neq 0 (
    @echo build failed
    exit /b
)

zig-out\bin\z_test.exe "D:\data\busi_wx\WXWork\1688856204307952\Cache\Video\2023-06\3B7EC2B2FCB0FA79E3149C22FD339154.mp4"

echo.
