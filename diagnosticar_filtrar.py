"""Mostra o que existe de verdade na tela para o botão 'Filtrar' (cole a saída no chat)."""
import re
import time
from playwright.sync_api import sync_playwright
from nucleo import abrir_navegador, carregar_config, _garantir_tela

JS = """() => {
  const el = [...document.querySelectorAll('button,input[type=submit],input[type=button],a,span,div')]
    .filter(e => /^\\s*Filtrar\\s*$/.test((e.innerText || e.value || '')));
  return el.map(e => ({tag: e.tagName.toLowerCase(), id: e.id || null, classe: (e.className||'').toString().slice(0,80),
    type: e.getAttribute('type'), visivel: !!(e.offsetWidth || e.offsetHeight),
    ariaHiddenNoAncestral: !!e.closest('[aria-hidden=true]'), disabled: e.disabled || false,
    html: e.outerHTML.slice(0, 300)}));
}"""

cfg = carregar_config()
with sync_playwright() as p:
    ctx, page = abrir_navegador(p, cfg)
    for rodada in (1, 2):
        btn = _garantir_tela(page, cfg)
        btn.click()
        for espera in (0.5, 3.0):
            time.sleep(espera)
            print(f"\n=== rodada {rodada}, {espera}s depois de clicar em Filtros ===")
            print("iframes:", len(page.frames) - 1)
            for e in page.evaluate(JS):
                print(e)
        page.locator("#RoutesNumber").fill("4698878")
        page.locator("#RoutesNumber").press("Enter")
        time.sleep(4)
        print("Após Enter -> URL:", page.url)
