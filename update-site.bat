@echo off
chcp 65001 >nul
setlocal
title 发布我的知识库站点

set "PROJ=D:\quartz-site"
set "REPO=ssh://git@ssh.github.com:443/xiaqingteng54-tech/my-productivity-site.git"

echo ============================================
echo   发布知识库站点
echo ============================================
echo.

cd /d "%PROJ%"
if errorlevel 1 (
  echo [失败] 找不到工程目录 %PROJ%
  goto fail
)

if not exist "scripts\build-dashboard.mjs" (
  echo [失败] 找不到 scripts\build-dashboard.mjs
  echo        请确认这个文件已经放进 %PROJ%\scripts\ 目录
  goto fail
)

if not exist "node_modules" (
  echo [1/4] 首次运行，安装依赖，可能要几分钟 ...
  call npm install
  if errorlevel 1 goto fail
) else (
  echo [1/4] 依赖已就绪
)

echo [2/4] 生成每日工作台数据 ...
call node scripts\build-dashboard.mjs
if errorlevel 1 (
  echo.
  echo [失败] 看板生成出错，把上面的提示整段发我
  goto fail
)

echo.
echo [3/4] 构建站点 ...
call npx quartz build
if errorlevel 1 (
  echo.
  echo [失败] 站点构建出错，把上面的提示整段发我
  goto fail
)

if not exist "public\index.html" (
  echo [失败] 没有生成 public\index.html，构建可能没跑完
  goto fail
)

if not exist "public\static\dashboard.html" (
  echo [注意] 没有找到 public\static\dashboard.html
  echo        站点照样发布，但工作台页可能是 404，把这条提示发我
)

echo.
echo [4/4] 推送到线上 ...
cd public
if not exist ".git" (
  echo       初始化发布仓库 ...
  git init >nul
  git checkout -b gh-pages >nul 2>nul
)
git config user.email >nul 2>nul
if errorlevel 1 git config user.email "site-bot@local"
git config user.name >nul 2>nul
if errorlevel 1 git config user.name "site-bot"
git add -A
git commit -m "publish %date% %time%" >nul 2>nul
git remote get-url origin >nul 2>nul
if errorlevel 1 git remote add origin "%REPO%"
git push -f origin HEAD:gh-pages
if errorlevel 1 goto fail

cd /d "%PROJ%"
echo.
echo ============================================
echo   发布完成
echo.
echo   工作台：https://xiaqingteng54-tech.github.io/my-productivity-site/static/dashboard.html
echo   首页　：https://xiaqingteng54-tech.github.io/my-productivity-site/
echo.
echo   GitHub 需要 1 到 2 分钟才生效，刷新时按 Ctrl+F5
echo ============================================
pause
exit /b 0

:fail
echo.
echo --------------------------------------------
echo   发布中断。把上面这段文字整段复制发我
echo --------------------------------------------
pause
exit /b 1
