@echo off
rem ============================================================
rem  eraTW kojo verification pipeline - one-click launcher
rem  Just double-click this file. Everything else is in Chinese
rem  inside the PowerShell window that opens.
rem  (It runs start_pipeline.ps1 located in the same folder.)
rem ============================================================
title eraTW kojo verification console
rem -STA is required so the folder-picker dialog (FolderBrowserDialog) runs in-process
rem (avoids the child-powershell stdout codepage that turned "・" into "?").
powershell -STA -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_pipeline.ps1"
