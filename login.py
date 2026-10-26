"""Primeiro login manual. Nenhuma credencial é lida ou gravada pelo script."""
from playwright.sync_api import sync_playwright
from nucleo import carregar_config, abrir_navegador, configurar_log

cfg = carregar_config()
log = configurar_log()
with sync_playwright() as p:
    ctx, page = abrir_navegador(p, cfg)
    if cfg.get("url_sistema") and page.url in ("about:blank", "chrome://newtab/"):
        page.goto(cfg["url_sistema"])
    print("\n>>> Faça o login manualmente na janela do Chrome (incluindo CAPTCHA/2FA, se houver).")
    print(">>> Navegue até Rotas > Consulta e copie a URL da barra de endereço para 'url_consulta' no config.json.")
    input(">>> Quando a tela ROTAS / CONSULTA estiver aberta, pressione Enter aqui... ")
    log.info("Login concluído. URL atual: %s", page.url)
    print("URL atual:", page.url)
    print("A janela do Chrome continua aberta (modo cdp) para manter a sessão.")
