@echo off

setlocal enabledelayedexpansion


call :clone_or_pull "https://github.com/JuliaLang/METADATA.jl", METADATA

for /f "delims=" %%f in ('dir /b /a:d-h-s METADATA') do (
  for /f "delims=" %%a in ('type METADATA\%%f\url') do set u=%%a
  call :clone_or_pull "%u%", %%f
)

exit /b %errorlevel%


:clone_or_pull

set "url=%~1"
set "pkg=%~2"

if exist "%pkg%" (
  cd %pkg%
  echo %pkg%
  git pull
  cd ..
) else (
  echo %pkg%
  git clone -q %url% %pkg%
)

exit /b 0
