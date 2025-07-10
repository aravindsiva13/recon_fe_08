@echo off
start powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\IT\Downloads\recon_updated (1)\Recon (2)\Recon\Process_PayTm.ps1"
start powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\IT\Downloads\recon_updated (1)\Recon (2)\Recon\Process_PhonePe.ps1"
start powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\IT\Downloads\recon_updated (1)\Recon (2)\Recon\Process_iCloud_Payment.ps1"
start powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\IT\Downloads\recon_updated (1)\Recon (2)\Recon\Process_iCloud_Refund.ps1"



@REM @echo off
@REM REM Change to the directory where this batch file is located
@REM cd /d "%~dp0"

@REM REM Now you can use just the filenames instead of full paths:
@REM start /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Process_PayTm.ps1"
@REM start /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Process_PhonePe.ps1" 
@REM start /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Process_iCloud_Payment.ps1"
@REM start /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Process_iCloud_Refund.ps1"