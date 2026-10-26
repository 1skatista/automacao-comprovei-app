"""Confere se o Chrome instalado existe e se o Playwright o controla."""
import os
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

CANDIDATOS = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"),
    "/usr/bin/google-chrome", "/usr/bin/google-chrome-stable",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
]
chrome = next((c for c in CANDIDATOS if Path(c).exists()), None)
if not chrome:
    sys.exit("Chrome NÃO encontrado. Instale o Google Chrome ou informe o caminho no config.json.")
print("Chrome encontrado em:", chrome)

with sync_playwright() as p:
    b = p.chromium.launch(executable_path=chrome, headless=False)
    print("Versão controlada pelo Playwright:", b.version)
    pg = b.new_page()
    pg.goto("https://example.com")
    print("Título da página de teste:", pg.title())
    pg.goto("chrome://version")
    for linha in pg.inner_text("body").splitlines():
        if any(k in linha for k in ("Google Chrome", "Executable", "Executável", "remote-debugging")):
            print("  chrome://version ->", linha.strip()[:160])
    print("OK: se a linha acima mostra 'Google Chrome' e o caminho do seu chrome.exe, "
          "o Playwright está controlando o Chrome instalado.")
    pg.wait_for_timeout(4000)
    b.close()
