@echo off
echo ========================================
echo   智能菜谱推荐助手 - 邮箱验证码服务
echo ========================================
echo.

echo [1/2] 检查依赖...
if not exist "node_modules" (
    echo     首次运行，正在安装依赖...
    npm install
    echo     依赖安装完成！
) else (
    echo     依赖已安装
)

echo.
echo [2/2] 启动服务...
echo.
node server.js

pause
