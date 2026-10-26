"""Servidor web local para o app Comprovei. Reutiliza a sessão Chrome do núcleo."""
import hmac
import json
import os
import re
import threading
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

from playwright.sync_api import sync_playwright
from nucleo import (BASE, abrir_navegador, carregar_config, classificar,
                    configurar_log, executar_consulta, formatar_data, norm_carga)

WEB = BASE / "webapp"
HOST = os.environ.get("COMPROVEI_APP_HOST", "127.0.0.1")
PORT = int(os.environ.get("COMPROVEI_APP_PORT", "8765"))
TOKEN = os.environ.get("COMPROVEI_APP_TOKEN", "")
MAX_BODY = 256 * 1024
MAX_ITEMS = 100
QUERY_LOCK = threading.Lock()
LOG = configurar_log()

if len(TOKEN) < 24:
    raise SystemExit("Defina COMPROVEI_APP_TOKEN com um token aleatório de pelo menos 24 caracteres antes de iniciar.")


def respond(handler, status, data, content_type="application/json; charset=utf-8"):
    body = data if isinstance(data, bytes) else json.dumps(data, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", content_type)
    handler.send_header("Content-Length", str(len(body)))
    handler.send_header("X-Content-Type-Options", "nosniff")
    handler.send_header("Referrer-Policy", "no-referrer")
    handler.send_header("Cache-Control", "no-store")
    handler.send_header("Content-Security-Policy", "default-src 'self'; connect-src 'self'; style-src 'self'; script-src 'self'; img-src 'self' data:; manifest-src 'self'; base-uri 'none'; frame-ancestors 'none'")
    handler.end_headers()
    handler.wfile.write(body)


class Handler(BaseHTTPRequestHandler):
    server_version = "ComproveiApp/1.0"

    def log_message(self, fmt, *args):
        LOG.info("web %s - %s", self.address_string(), fmt % args)

    def do_GET(self):
        path = urlsplit(self.path).path
        if path == "/api/health":
            return respond(self, 200, {"ok": True, "service": "Comprovei Web App"})
        rel = "index.html" if path in ("", "/") else unquote(path.lstrip("/"))
        target = (WEB / rel).resolve()
        if WEB.resolve() not in target.parents and target != WEB.resolve():
            return respond(self, 404, {"error": "Arquivo não encontrado."})
        if not target.is_file():
            return respond(self, 404, {"error": "Arquivo não encontrado."})
        mime = {".html": "text/html; charset=utf-8", ".css": "text/css; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".json": "application/manifest+json; charset=utf-8", ".svg": "image/svg+xml"}.get(target.suffix, "application/octet-stream")
        return respond(self, 200, target.read_bytes(), mime)

    def do_POST(self):
        if urlsplit(self.path).path != "/api/consultas":
            return respond(self, 404, {"error": "Rota não encontrada."})
        auth = self.headers.get("Authorization", "")
        provided = auth.removeprefix("Bearer ")
        if not hmac.compare_digest(provided, TOKEN):
            return respond(self, 401, {"error": "Token inválido. Confira o token configurado no servidor."})
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return respond(self, 400, {"error": "Tamanho da requisição inválido."})
        if length <= 0 or length > MAX_BODY:
            return respond(self, 413, {"error": "A requisição está vazia ou excede o limite permitido."})
        try:
            body = json.loads(self.rfile.read(length))
            items = body.get("cargas")
            if not isinstance(items, list) or not 1 <= len(items) <= MAX_ITEMS:
                raise ValueError(f"Envie entre 1 e {MAX_ITEMS} cargas por consulta.")
            normalized = []
            for item in items:
                if not isinstance(item, dict):
                    raise ValueError("Cada carga precisa ter número, data_inicial e data_final.")
                carga = norm_carga(item.get("carga"))
                if not re.fullmatch(r"\d{1,30}", carga):
                    raise ValueError("Os números de carga/rota devem conter somente dígitos.")
                de = formatar_data(item.get("data_inicial"))
                ate = formatar_data(item.get("data_final"))
                d1 = datetime.strptime(de, "%d/%m/%Y")
                d2 = datetime.strptime(ate, "%d/%m/%Y")
                if d2 < d1:
                    raise ValueError(f"A data final é anterior à inicial para a carga {carga}.")
                if (d2 - d1).days > 31:
                    raise ValueError(f"O período da carga {carga} ultrapassa 31 dias.")
                normalized.append({"carga": carga, "de": de, "ate": ate})
        except (ValueError, TypeError, json.JSONDecodeError) as exc:
            return respond(self, 400, {"error": str(exc)})

        if not QUERY_LOCK.acquire(blocking=False):
            return respond(self, 409, {"error": "Já existe uma consulta em andamento. Aguarde e tente novamente."})
        try:
            resultados = []
            with sync_playwright() as playwright:
                cfg = carregar_config()
                _, page = abrir_navegador(playwright, cfg)
                page.set_default_timeout(cfg.get("timeout_acao_ms", 10000))
                for item in normalized:
                    txt, status, observacao = executar_consulta(
                        page, cfg, item["carga"], item["de"], item["ate"])
                    resultados.append({"carga": item["carga"], "data_inicial": item["de"],
                                       "data_final": item["ate"], "resultado": txt,
                                       "status": status, "observacao": observacao})
            return respond(self, 200, {"resultados": resultados})
        except Exception as exc:
            LOG.exception("Falha ao executar consultas web")
            return respond(self, 500, {"error": f"Falha no servidor: {type(exc).__name__}. Confira o log local."})
        finally:
            QUERY_LOCK.release()


if __name__ == "__main__":
    print(f"App Comprovei disponível em http://{HOST}:{PORT}")
    print("A autenticação do Comprovei continua sendo feita manualmente no Chrome.")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
