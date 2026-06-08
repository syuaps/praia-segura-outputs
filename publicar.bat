@echo off
setlocal

REM ====== CAMINHOS (BACKEND) ======
set SRC_OUTPUTS=E:\praia_segura_backend\outputs
set SRC_STATIC=E:\praia_segura_backend\data_static

REM ====== CAMINHO (REPOSITORIO LOCAL) ======
set REPO=E:\praia-segura-outputs

cd /d "%REPO%"
if errorlevel 1 (
  echo ERRO: nao consegui acessar a pasta do repositorio: %REPO%
  exit /b 1
)

echo === Sincronizando outputs (copia so o que mudou) ===
robocopy "%SRC_OUTPUTS%" "%REPO%\outputs" /E /XO /FFT /R:2 /W:2
set RC1=%ERRORLEVEL%

echo === Sincronizando data_static (copia so o que mudou) ===
robocopy "%SRC_STATIC%" "%REPO%\data_static" /E /XO /FFT /R:2 /W:2
set RC2=%ERRORLEVEL%

REM Robocopy: 0-7 = sucesso (com ou sem copias). >=8 = erro real.
if %RC1% GEQ 8 (
  echo ERRO no robocopy outputs. Codigo: %RC1%
  exit /b %RC1%
)
if %RC2% GEQ 8 (
  echo ERRO no robocopy data_static. Codigo: %RC2%
  exit /b %RC2%
)

echo === Atualizando rodada_atual.json ===
powershell -NoProfile -Command ^
  "$t=(Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz');" ^
  "$obj=@{updated_at=$t};" ^
  "$obj | ConvertTo-Json | Out-File -Encoding UTF8 '%REPO%\rodada_atual.json'"

echo === Commitando e enviando para o GitHub (so se tiver mudanca) ===
git add -A

REM Checa se tem mudanças staged; se não tiver, não comita
git diff --cached --quiet
if %ERRORLEVEL%==0 (
  echo Sem mudancas para publicar.
  exit /b 0
)

git commit -m "Atualizacao automatica"
git push
if errorlevel 1 (
  echo ERRO no git push. Pode ser autenticacao.
  exit /b 1
)

echo === OK! Publicado. ===
endlocal