@echo -off
mode 80 25
cls

echo ========================================
echo PonchoOS Bootloader Startup Script
echo ========================================
echo.

REM Try current directory first
if exist .\EFI\BOOT\main.efi then
  echo Found bootloader in current directory
  .\EFI\BOOT\main.efi
  goto END
endif

REM Try with backslash path
if exist \EFI\BOOT\main.efi then
  echo Found bootloader at \EFI\BOOT\main.efi
  \EFI\BOOT\main.efi
  goto END
endif

REM Search available filesystems
echo Searching available filesystems...
echo.

if exist fs0:\EFI\BOOT\main.efi then
 fs0:
 echo [SUCCESS] Found bootloader on fs0:
 cd \EFI\BOOT
 main.efi
 goto END
endif

if exist fs1:\EFI\BOOT\main.efi then
 fs1:
 echo [SUCCESS] Found bootloader on fs1:
 cd \EFI\BOOT
 main.efi
 goto END
endif

if exist fs2:\EFI\BOOT\main.efi then
 fs2:
 echo [SUCCESS] Found bootloader on fs2:
 cd \EFI\BOOT
 main.efi
 goto END
endif

if exist fs3:\EFI\BOOT\main.efi then
 fs3:
 echo [SUCCESS] Found bootloader on fs3:
 cd \EFI\BOOT
 main.efi
 goto END
endif

if exist fs4:\EFI\BOOT\main.efi then
 fs4:
 echo [SUCCESS] Found bootloader on fs4:
 cd \EFI\BOOT
 main.efi
 goto END
endif

if exist fs5:\EFI\BOOT\main.efi then
 fs5:
 echo [SUCCESS] Found bootloader on fs5:
 cd \EFI\BOOT
 main.efi
 goto END
if exist fs6:\EFI\BOOT\main.efi then
 fs6:
 echo [SUCCESS] Found bootloader on fs6:
 cd \EFI\BOOT
 main.efi
 goto END
endif

if exist fs7:\EFI\BOOT\main.efi then
 fs7:
 echo [SUCCESS] Found bootloader on fs7:
 cd \EFI\BOOT
 main.efi
 goto END
endif

echo.
echo ========================================
echo [ERROR] Bootloader not found!
echo ========================================
echo Searched locations:
echo  - .\EFI\BOOT\main.efi
echo  - \EFI\BOOT\main.efi
echo  - fs0-fs7:\EFI\BOOT\main.efi
echo.
echo Boot halted. Manual intervention required.
echo ========================================
 
:END
echo.
echo ========================================
echo End of startup script
echo ========================================