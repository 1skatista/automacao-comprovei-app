"""Lista campos, botões, rótulos e colunas REAIS da página para ajustar seletores."""
import json
from datetime import datetime
from playwright.sync_api import sync_playwright
from nucleo import carregar_config, abrir_navegador, BASE

JS = """() => {
 const q = s => [...document.querySelectorAll(s)];
 const info = e => ({tag:e.tagName.toLowerCase(), id:e.id||null, name:e.getAttribute('name'),
   type:e.getAttribute('type'), placeholder:e.getAttribute('placeholder'),
   aria:e.getAttribute('aria-label'), role:e.getAttribute('role'), for:e.getAttribute('for'),
   classe:(e.className && e.className.toString().slice(0,80))||null,
   texto:(e.innerText||e.value||'').trim().slice(0,60),
   visivel:!!(e.offsetWidth||e.offsetHeight)});
 const v = a => a.map(info).filter(i=>i.visivel);
 return {url:location.href,
   campos:v(q('input,select,textarea,[role=combobox]')), botoes:v(q('button,[role=button]')),
   labels:v(q('label')), cabecalhos:v(q('th,[role=columnheader]')),
   dialogos:v(q('[role=dialog],.modal,.modal-dialog'))};
}"""
JS_LINHA = """() => { const r=document.querySelector('tbody tr, [role=row]:not(:first-child)');
  return r ? r.outerHTML.slice(0,5000) : null; }"""

cfg = carregar_config()
saida = BASE / "inspecao"
saida.mkdir(exist_ok=True)
with sync_playwright() as p:
    ctx, page = abrir_navegador(p, cfg)
    if cfg.get("url_consulta"):
        page.goto(cfg["url_consulta"])
    input("1) Clique em 'Filtros' (painel aberto) e pressione Enter aqui... ")
    d1 = page.evaluate(JS)
    page.screenshot(path=str(saida / "1_filtros.png"))
    input("2) Preencha uma Rota, clique em Filtrar, espere a tabela e pressione Enter aqui... ")
    d2 = page.evaluate(JS)
    d2["primeira_linha_html"] = page.evaluate(JS_LINHA)
    page.screenshot(path=str(saida / "2_resultado.png"))
    carimbo = datetime.now().strftime("%Y%m%d_%H%M%S")
    arq = saida / f"inspecao_{carimbo}.json"
    arq.write_text(json.dumps({"painel_filtros": d1, "tabela": d2}, ensure_ascii=False, indent=2), encoding="utf-8")
    print("\nCAMPOS DO PAINEL:")
    for c in d1["campos"]:
        print("  ", {k: v for k, v in c.items() if v})
    print("\nCABEÇALHOS DA TABELA:", [h["texto"] for h in d2["cabecalhos"]])
    print("\nRelatório salvo em:", arq)
