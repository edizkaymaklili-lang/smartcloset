@echo off
echo ========================================
echo Stil Asist - GitHub Push Script
echo ========================================
echo.
echo 1. Oncelikle GitHub'da yeni bir repository olusturun:
echo    https://github.com/new
echo.
echo 2. Repository adi: stil-asist (veya Stil-Asist)
echo 3. Public veya Private secin
echo 4. README, .gitignore, license EKLEMEYIN
echo.
echo 5. Repository olusturduktan sonra GitHub'in size verdigi URL'yi girin:
echo    Ornek: https://github.com/USERNAME/stil-asist.git
echo.
set /p REPO_URL="Repository URL'sini yapistiriniz: "

echo.
echo Simdi Git uzak repository ekleniyor...
git remote remove origin 2>nul
git remote add origin %REPO_URL%

echo.
echo GitHub'a push ediliyor...
git push -u origin main

echo.
echo ========================================
echo Tamamlandi!
echo Repository: %REPO_URL%
echo ========================================
pause
