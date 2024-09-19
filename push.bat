@echo off

git config user.name jemuky
git config user.email jymkyu@outlook.com
git add .
git commit

if %ERRORLEVEL% neq 0 (
    @echo error: nothing to commit or commit failed
) else (
    git push
)
