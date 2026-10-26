# Comprovei Web App (REA)

Esta versão transforma a automação de consulta em uma interface web responsiva e instalável como PWA. Ela preserva o motor Python + Playwright e usa a sessão do Chrome do computador que executa o servidor.

## O que o app faz

- Recebe números de carga/rota e datas pelo navegador, inclusive no celular.
- Valida números, datas e períodos de até 31 dias.
- Consulta cada carga usando o núcleo existente.
- Exibe resultado, status e observação e permite baixar um CSV.
- Armazena os arquivos estáticos para abrir a interface; consultas exigem o servidor e uma conexão ativa.

## Hospedagem e acesso remoto

GitHub Pages hospeda somente arquivos estáticos; não executa Python, Playwright nem Chrome. Para consultas reais, o computador Windows autenticado precisa ficar ligado e conectado ao Comprovei, ou o backend deve ser instalado em um servidor próprio autorizado. O GitHub é o repositório do código, não o servidor que executa a automação.

Por padrão, o servidor escuta apenas em `127.0.0.1`. Não o exponha diretamente à internet. Para acessar de outro dispositivo, use uma VPN privada ou um túnel privado com HTTPS, controle de acesso e regras de firewall. O token do app é uma proteção adicional; não substitui autenticação de usuários nem segurança de rede.

## Instalador Windows

O instalador `AutomacaoComprovei-Setup.exe` instala o app em `%LOCALAPPDATA%`, instala Python 3.14.9 se necessário, prepara um ambiente isolado, instala ou valida o Chrome e baixa as bibliotecas necessárias, cria configuração local e atalhos. É necessária conexão com a internet durante a instalação. O primeiro login no Comprovei é sempre manual.

Para reconstruir o instalador em Windows, execute `installer\build_installer.ps1 -OutputPath <caminho>` com o IExpress incluído no Windows.

## Preparar manualmente o Windows

1. Copie `config.example.json` para `config.json` e confira `chrome_caminho`, `perfil_dir` e `url_consulta`. O `config.json` local, o perfil autenticado, planilhas operacionais, logs, capturas e traces estão excluídos do Git.
2. Instale as dependências:

   ```powershell
   python -m pip install -r requirements.txt
   ```

3. Abra o Chrome usando o perfil separado e faça login manual no Comprovei (`python login.py`). Resolva CAPTCHA ou autenticação em dois fatores diretamente no navegador.
4. Inicie o app. O script cria e protege um token do Windows na primeira execução e o mostra no terminal:

   ```powershell
   .\start_app.ps1
   ```

5. No computador, abra `http://127.0.0.1:8765`, cole o token do terminal e use o painel. Para outro dispositivo, conecte primeiro à rede privada que dá acesso ao servidor.

O token é gerado na primeira inicialização e guardado protegido pelo Windows para esse usuário; ele fica disponível no terminal ao iniciar o servidor e deve ser colado no navegador. A API serializa as consultas para evitar disputa pelo mesmo Chrome e aceita no máximo 100 cargas por envio.

## Publicação no GitHub

O repositório pode conter o código-fonte, `app_server.py`, a pasta `webapp`, `config.example.json`, `requirements.txt`, `cargas_exemplo.xlsx`, `.gitignore` e esta documentação. Não inclua `config.json`, `.venv`, perfil do Chrome, planilhas operacionais ou backups, logs, prints, traces e arquivos de inspeção: eles podem revelar sessão autenticada ou dados de operação.

Para disponibilizar o app pela internet, hospede o backend em ambiente privado/controlado e configure HTTPS, autenticação de usuários e firewall antes de permitir consultas remotas. O frontend é servido pelo backend na mesma origem para evitar expor uma API aberta.

## Interface

`webapp/` contém HTML, CSS e JavaScript sem dependências de terceiros. O service worker armazena os arquivos estáticos; chamadas `/api/` permanecem online e precisam do servidor.





