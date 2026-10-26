"""Uso:
  Teste único   : python consultar.py --carga 999001 --de 01/09/2026 --ate 30/09/2026 --debug
  Teste de lote : python consultar.py --cargas 999001,999002 --de 29/09/2026 --ate 04/10/2026
  Planilha      : python consultar.py                (em blocos, rápido)
                  python consultar.py --individual   (uma por vez, modo antigo)
  Opções        : --limite N | --linha N | --reprocessar-tudo | --debug
"""
import argparse
import shutil
import time
from datetime import datetime, timedelta

from playwright.sync_api import sync_playwright
from nucleo import (BASE, STATUS_FINAIS, ConsultaErro, DadosInvalidos, abrir_navegador,
                    abrir_planilha, carregar_config, classificar, configurar_log,
                    consultar_lote, executar_consulta, formatar_data, norm_carga)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="config.json")
    ap.add_argument("--carga")
    ap.add_argument("--cargas", help="várias cargas separadas por vírgula (teste de lote)")
    ap.add_argument("--de")
    ap.add_argument("--ate")
    ap.add_argument("--linha", type=int)
    ap.add_argument("--limite", type=int)
    ap.add_argument("--individual", action="store_true")
    ap.add_argument("--reprocessar-tudo", action="store_true")
    ap.add_argument("--debug", action="store_true")
    args = ap.parse_args()

    cfg = carregar_config(args.config)
    log = configurar_log()
    prints = None
    if args.debug:
        prints = BASE / "prints"
        prints.mkdir(exist_ok=True)

    with sync_playwright() as p:
        ctx, page = abrir_navegador(p, cfg)
        page.set_default_timeout(cfg.get("timeout_acao_ms", 10000))
        if args.debug:
            try:
                ctx.tracing.start(screenshots=True, snapshots=True)
            except Exception as e:
                log.warning("Trace indisponível: %s", e)
        inicio = time.time()
        try:
            hoje = datetime.now()
            de = args.de or (hoje - timedelta(days=30)).strftime("%d/%m/%Y")
            ate = args.ate or hoje.strftime("%d/%m/%Y")
            if args.carga:
                res, status, obs = executar_consulta(page, cfg, norm_carga(args.carga), de, ate, prints)
                log.info("carga=%s | resultado=%s | status=%s | obs=%s", args.carga, res, status, obs)
                print(f"\n>>> {args.carga}: {res or '-'}  ->  {status}  ({obs})")
            elif args.cargas:
                lista = [norm_carga(c) for c in args.cargas.split(",") if c.strip()]
                r = consultar_lote(page, cfg, lista, de, ate, prints)
                for c in lista:
                    print(f">>> {c}: {r[c] if c in r else 'INDETERMINADA (consultaria individualmente)'}")
            else:
                lote(page, cfg, args, prints, log)
        finally:
            log.info("Tempo total: %.0f s", time.time() - inicio)
            if args.debug:
                try:
                    destino = BASE / "traces"
                    destino.mkdir(exist_ok=True)
                    ctx.tracing.stop(path=str(destino / f"trace_{datetime.now():%Y%m%d_%H%M%S}.zip"))
                except Exception:
                    pass
        if cfg["modo_navegador"] == "cdp":
            print("O Chrome foi mantido aberto (modo cdp).")


def salvar(wb, caminho, log, insistir=False):
    while True:
        try:
            wb.save(caminho)
            return True
        except PermissionError:
            if not insistir:
                log.warning("Não consegui salvar (planilha aberta no Calc?). Tentarei novamente.")
                return False
            input("Feche a planilha no LibreOffice Calc e pressione Enter para salvar... ")


def gravar(ws, col, linha, carga, res, status, obs, log):
    c = ws.cell(linha, col["resultado"], res)
    c.number_format = "@"
    ws.cell(linha, col["status"], status)
    ws.cell(linha, col["observacao"], obs)
    log.info("linha=%d | carga=%s | resultado=%s | status=%s | obs=%s", linha, carga, res or "-", status, obs)


def lote(page, cfg, args, prints, log):
    caminho, wb, ws, col = abrir_planilha(cfg)
    backup = caminho.with_name(f"{caminho.stem}_backup_{datetime.now():%Y%m%d_%H%M%S}{caminho.suffix}")
    shutil.copy2(caminho, backup)
    log.info("Backup da planilha: %s", backup.name)

    pend = []
    for linha in range(2, ws.max_row + 1):
        if args.linha and linha != args.linha:
            continue
        carga = norm_carga(ws.cell(linha, col["carga"]).value)
        if not carga:
            continue
        atual = str(ws.cell(linha, col["status"]).value or "").strip().upper()
        if atual in STATUS_FINAIS and not args.reprocessar_tudo:
            continue
        if args.limite and len(pend) >= args.limite:
            break
        pend.append((linha, carga, ws.cell(linha, col["data_inicial"]).value,
                     ws.cell(linha, col["data_final"]).value))
    log.info("%d carga(s) a processar.", len(pend))

    grupos, feitas, individuais = {}, 0, 0
    for linha, carga, de, ate in pend:
        try:
            chave = (formatar_data(de), formatar_data(ate))
        except DadosInvalidos as e:
            gravar(ws, col, linha, carga, "", "ERRO", str(e), log)
            continue
        grupos.setdefault(chave, []).append((linha, carga))

    tamanho = cfg.get("lote_tamanho", 50)
    for (de_s, ate_s), itens in grupos.items():
        for i in range(0, len(itens), tamanho):
            bloco = itens[i:i + tamanho]
            cargas = list(dict.fromkeys(c for _, c in bloco))
            res = {}
            if not args.individual:
                try:
                    res = consultar_lote(page, cfg, cargas, de_s, ate_s, prints)
                except DadosInvalidos as e:
                    for linha, carga in bloco:
                        gravar(ws, col, linha, carga, "", "ERRO", str(e), log)
                    continue
                except Exception as e:
                    log.warning("Lote falhou (%s); consultando uma a uma.", str(e).splitlines()[0])
                    res = {}
            for linha, carga in bloco:
                if carga in res:
                    try:
                        txt, status, obs = classificar(res[carga])
                    except ConsultaErro as e:
                        txt, status, obs = "", "ERRO", str(e)
                else:
                    txt, status, obs = executar_consulta(page, cfg, carga, de_s, ate_s, prints)
                    individuais += 1
                    time.sleep(cfg["intervalo_segundos"])
                gravar(ws, col, linha, carga, txt, status, obs, log)
                feitas += 1
            salvar(wb, caminho, log)

    salvar(wb, caminho, log, insistir=True)
    log.info("Fim. %d carga(s) gravadas (%d consultadas individualmente). Planilha: %s",
             feitas, individuais, caminho)


if __name__ == "__main__":
    main()

