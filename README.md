# Comprovei — aplicativo web de consulta

O projeto agora inclui uma interface web responsiva e instalável para consultar cargas no Comprovei pelo computador ou celular conectado à rede privada do servidor. O backend reutiliza a automação Python/Playwright e a sessão do Chrome autenticada no computador host.

- Guia do app, instalação e limites de hospedagem: [README_APP.md](README_APP.md)
- Interface: `webapp/`
- Servidor local: `app_server.py`
- Exemplo de configuração sem credenciais: `config.example.json`

**Hospedagem:** GitHub Pages não executa Python, Playwright nem Chrome. Para consultas reais, é necessário manter o backend rodando em um computador/servidor autorizado e disponibilizá-lo somente por VPN/túnel privado com HTTPS e controle de acesso. Não envie `config.json`, perfil de Chrome, dados, planilhas operacionais, logs, traces ou capturas ao GitHub.

---

## Automação local legada
# Automação TNS Gestão de Entregas (Comprovei)

Automação para consulta de cargas no **TNS / Comprovei**, utilizando **Python + Playwright + Google Chrome**.

O programa lê as cargas cadastradas em `cargas.xlsx`, acessa **Rotas > Consulta**, consulta as cargas em lote, identifica a quantidade de documentos finalizados e grava o resultado na planilha.

### Exemplo

* `12/12` → **COMPLETA**
* `8/9` → **INCOMPLETA**
* Carga não localizada → **NÃO ENCONTRADA**
* Falha técnica → **ERRO**

> **Importante:** o programa é externo ao LibreOffice Calc. O Calc é utilizado apenas para preencher e visualizar a planilha.

---

# 1. Requisitos

Computador Windows com:

* Windows 10 ou 11
* Google Chrome instalado
* Python 3.12
* LibreOffice Calc (para editar a planilha)
* Acesso ao TNS / Comprovei
* Usuário e senha de acesso ao sistema

O programa utiliza o **Google Chrome instalado no computador**, e não o Chromium fornecido pelo Playwright.

---

# 2. Instalação — PRIMEIRA VEZ

> Esta etapa normalmente precisa ser realizada somente na primeira utilização em um computador novo.

Abra o **PowerShell**.

## 2.1 Instalar o Python

```powershell
winget install -e --id Python.Python.3.12
```

Depois da instalação, **feche e abra novamente o PowerShell**.

Verifique:

```powershell
py --version
```

Deve aparecer algo semelhante a:

```text
Python 3.12.x
```

---

# 3. Copiar o programa

Crie a pasta principal:

```powershell
mkdir C:\AutomacaoComprovei
cd C:\AutomacaoComprovei
```

Copie a pasta:

```text
comprovei_automacao
```

do pendrive para:

```text
C:\AutomacaoComprovei\
```

A estrutura deverá ficar:

```text
C:\AutomacaoComprovei\
└── comprovei_automacao\
```

Entre na pasta:

```powershell
cd C:\AutomacaoComprovei\comprovei_automacao
```

---

# 4. Criar o ambiente Python

Crie o ambiente virtual:

```powershell
py -m venv .venv
```

Ative:

```powershell
.\.venv\Scripts\Activate.ps1
```

Se o PowerShell bloquear a execução:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Depois:

```powershell
.\.venv\Scripts\Activate.ps1
```

Quando estiver ativado, o terminal deverá mostrar algo semelhante a:

```text
(.venv) PS C:\AutomacaoComprovei\comprovei_automacao>
```

---

# 5. Instalar as dependências

Atualize o `pip`:

```powershell
python -m pip install --upgrade pip
```

Instale as dependências:

```powershell
python -m pip install -r requirements.txt
```

## Não é necessário executar:

```powershell
playwright install
```

O sistema utiliza o **Google Chrome já instalado no computador**.

---

# 6. Problema conhecido: erro do Greenlet

Em algumas instalações do Windows pode aparecer:

```text
ModuleNotFoundError: No module named 'greenlet._greenlet'
```

Se isso acontecer, execute:

```powershell
python -m pip uninstall greenlet -y
```

Depois:

```powershell
python -m pip install --no-cache-dir greenlet
```

Teste:

```powershell
python -c "import greenlet; print(greenlet.__version__)"
```

Depois teste o Playwright:

```powershell
python -c "from playwright.sync_api import sync_playwright; print('Playwright OK')"
```

Se aparecer:

```text
Playwright OK
```

o ambiente está funcionando.

---

# 7. Estrutura do programa

Depois da instalação, a estrutura deverá ser semelhante a:

```text
C:\AutomacaoComprovei\
│
├── perfil_chrome\
│   └── sessão/login do Comprovei
│
└── comprovei_automacao\
    │
    ├── .venv\
    │
    ├── config.json
    ├── cargas.xlsx
    ├── requirements.txt
    │
    ├── nucleo.py
    ├── verificar_ambiente.py
    ├── login.py
    ├── inspecionar.py
    ├── consultar.py
    │
    ├── logs\
    ├── prints\
    ├── traces\
    └── inspecao\
```

### Arquivos principais

| Arquivo                 | Função                                         |
| ----------------------- | ---------------------------------------------- |
| `config.json`           | Configurações do sistema                       |
| `cargas.xlsx`           | Planilha de cargas                             |
| `nucleo.py`             | Lógica principal compartilhada                 |
| `login.py`              | Realiza o primeiro login                       |
| `verificar_ambiente.py` | Testa Chrome + Playwright                      |
| `inspecionar.py`        | Auxilia na identificação dos campos do sistema |
| `consultar.py`          | Executa as consultas                           |
| `requirements.txt`      | Dependências Python                            |

As pastas `logs`, `prints`, `traces` e `inspecao` são criadas/atualizadas durante a utilização.

---

# 8. Configuração do Chrome

O programa utiliza um **perfil separado do Chrome**.

Exemplo:

```json
"modo_navegador": "cdp",
"chrome_caminho": "C:/Program Files/Google/Chrome/Application/chrome.exe",
"perfil_dir": "C:/AutomacaoComprovei/perfil_chrome"
```

### IMPORTANTE

**Nunca coloque como `perfil_dir` a pasta principal do seu Chrome.**

O programa deve utilizar:

```text
C:\AutomacaoComprovei\perfil_chrome
```

e não a pasta:

```text
C:\Users\SEU_USUARIO\AppData\Local\Google\Chrome\User Data
```

Isso evita conflitos com o Chrome utilizado normalmente pelo funcionário.

---

# 9. Verificar o ambiente

Antes de utilizar o sistema pela primeira vez, execute:

```powershell
python verificar_ambiente.py
```

O teste deve:

1. Abrir o Google Chrome;
2. Utilizar o perfil separado;
3. Acessar uma página de teste;
4. Identificar a versão do Chrome;
5. Confirmar que o navegador utilizado é o Google Chrome.

Se houver problema, verifique o caminho:

```powershell
Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

Se retornar:

```text
True
```

o Chrome foi encontrado.

---

# 10. Se o Chrome não abrir

Feche o Chrome e execute:

```powershell
taskkill /F /IM chrome.exe
```

Depois tente novamente:

```powershell
python verificar_ambiente.py
```

Se necessário, atualize o Playwright:

```powershell
python -m pip install -U playwright
```

---

# 11. Primeiro login no Comprovei

O primeiro login precisa ser realizado manualmente.

Execute:

```powershell
python login.py
```

O programa abrirá o Chrome utilizando o perfil separado.

Faça o login normalmente.

Se o sistema solicitar:

* senha;
* CAPTCHA;
* autenticação em dois fatores;
* código de segurança;

o procedimento deve ser realizado manualmente.

### O programa não recebe nem armazena a senha.

Depois de entrar no sistema:

1. Acesse **Rotas**;
2. Entre em **Consulta**;
3. Copie a URL da página;
4. Coloque essa URL em:

```text
config.json
```

no campo:

```json
"url_consulta": "URL_DA_PAGINA_DE_CONSULTA"
```

Depois pressione **Enter no terminal**, caso o `login.py` esteja aguardando essa confirmação.

A sessão ficará salva em:

```text
C:\AutomacaoComprovei\perfil_chrome
```

---

# 12. Sessão do sistema

O modo padrão é:

```json
"modo_navegador": "cdp"
```

Nesse modo:

* o Chrome fica aberto;
* a sessão permanece disponível;
* o programa consegue reutilizar o navegador;
* normalmente não é necessário realizar login novamente a cada execução.

Se a sessão expirar, execute:

```powershell
python login.py
```

e faça o login novamente.

---

# 13. Descobrir/ajustar seletores

O programa procura os elementos da página principalmente por:

* textos visíveis;
* rótulos;
* cabeçalhos;
* botões;
* campos conhecidos.

Por exemplo:

```text
Rota
De
Até
Filtros
Filtrar
DOC. FINALIZADOS
```

Como esses elementos podem mudar caso o TNS/Comprovei seja atualizado, existe o script:

```powershell
python inspecionar.py
```

Ele auxilia na identificação de:

* `id`;
* `name`;
* `placeholder`;
* campos;
* cabeçalhos;
* elementos da página.

Os resultados ficam em:

```text
inspecao\
```

Se necessário, os seletores podem ser ajustados em:

```text
config.json
```

Exemplo:

```json
"campo_rota": "#idDoCampo"
```

ou:

```json
"campo_rota": "input[name='rota']"
```

---

# 14. Testar uma única carga

Antes de executar centenas de cargas, recomenda-se testar uma carga.

Exemplo:

```powershell
python consultar.py --carga 999001 --de 29/09/2026 --ate 04/10/2026 --debug
```

O `--debug` gera informações adicionais para diagnóstico.

Os arquivos de diagnóstico ficam em:

```text
prints\
traces\
logs\
```

O teste individual não deve alterar a planilha principal.

### Limite de período

O sistema trabalha com período máximo de **31 dias**.

---

# 15. Preparar a planilha

Abra:

```text
cargas.xlsx
```

no LibreOffice Calc.

Preencha as cargas que precisam ser consultadas.

As colunas devem seguir os nomes configurados em:

```text
config.json
```

As datas devem estar no formato:

```text
DD/MM/AAAA
```

Exemplo:

```text
02/10/2026
```

---

# 16. IMPORTANTE — Fechar o LibreOffice

Antes de executar a automação:

### SALVE E FECHE O `cargas.xlsx`.

Não deixe a planilha aberta no LibreOffice enquanto o programa estiver trabalhando.

Fluxo correto:

```text
Preencher planilha
       ↓
Salvar
       ↓
Fechar LibreOffice
       ↓
Executar automação
       ↓
Automação salva os resultados
       ↓
Abrir planilha novamente
```

Se o arquivo estiver aberto, o programa poderá não conseguir salvar as alterações.

---

# 17. Executar todas as cargas pendentes

Ative o ambiente virtual:

```powershell
cd C:\AutomacaoComprovei\comprovei_automacao
.\.venv\Scripts\Activate.ps1
```

Depois:

```powershell
python consultar.py
```

O programa processará as cargas que ainda precisam ser consultadas.

---

# 18. Testar somente algumas cargas

Para executar somente 3:

```powershell
python consultar.py --limite 3
```

Recomendado para testar o programa antes de executar um lote grande.

---

# 19. Executar uma linha específica

Para processar somente a linha 5:

```powershell
python consultar.py --linha 5
```

---

# 20. Reprocessar todas as cargas

Para forçar uma nova consulta em todas as cargas:

```powershell
python consultar.py --reprocessar-tudo
```

Isso é útil quando cargas que estavam anteriormente como:

```text
INCOMPLETA
```

podem ter sido finalizadas posteriormente.

---

# 21. Como funciona o processamento

O programa consulta as cargas em lotes.

Exemplo:

```text
50 cargas
↓
Consulta no Comprovei
↓
Lê os resultados
↓
Atualiza a planilha
↓
Próximo lote
```

As consultas são realizadas de forma **sequencial**.

Não são executadas várias consultas simultaneamente.

Isso reduz o risco de sobrecarregar o sistema ou gerar conflitos de sessão.

---

# 22. Backup automático

No início da execução, o programa cria um backup da planilha.

Exemplo:

```text
cargas_backup_20261004_200416.xlsx
```

O formato é:

```text
cargas_backup_AAAAMMDD_HHMMSS.xlsx
```

Assim, existe uma cópia da planilha antes do processamento.

---

# 23. Interpretação dos resultados

O principal resultado é o número de documentos finalizados.

### Exemplo:

```text
12/12
```

Significa:

```text
12 documentos finalizados
12 documentos esperados
```

Resultado:

```text
COMPLETA
```

---

### Exemplo:

```text
8/9
```

Significa:

```text
8 documentos finalizados
9 documentos esperados
```

Resultado:

```text
INCOMPLETA
```

Nesse caso:

```text
Faltam 1
```

---

# 24. Status possíveis

| Status           | Significado                                   |
| ---------------- | --------------------------------------------- |
| `COMPLETA`       | Todos os documentos foram finalizados         |
| `INCOMPLETA`     | Existem documentos ainda não finalizados      |
| `NÃO ENCONTRADA` | A carga não apareceu no resultado da consulta |
| `ERRO`           | Ocorreu uma falha técnica durante a consulta  |

---

# 25. Regra do X/Y

A interpretação é:

```text
X = documentos finalizados
Y = documentos esperados
```

Exemplos:

```text
12/12 → COMPLETA
10/12 → INCOMPLETA
1/2   → INCOMPLETA
0/0   → ERRO
```

Se:

```text
X > Y
```

o resultado também será tratado como:

```text
ERRO
```

A causa será registrada na coluna **Observação**.

### Atenção

Datas como:

```text
02/10/2026
```

não devem ser confundidas com resultados:

```text
8/9
```

O programa possui tratamento para essa situação.

---

# 26. Reexecução automática

Para evitar consultas desnecessárias, o programa normalmente pula cargas que já possuem resultado final.

São pulados:

```text
COMPLETA
INCOMPLETA
NÃO ENCONTRADA
```

Linhas:

```text
vazias
ERRO
```

podem ser processadas novamente.

Para atualizar tudo:

```powershell
python consultar.py --reprocessar-tudo
```

---

# 27. Logs

Os registros da automação ficam em:

```text
logs\
```

Exemplo:

```text
automacao_20261004.log
```

O log registra informações como:

* data;
* horário;
* linha;
* carga;
* resultado;
* status;
* observação;
* tentativas;
* erros.

---

# 28. Prints de erro

Quando ocorre uma falha, o programa pode salvar uma captura da tela em:

```text
prints\
```

Exemplo:

```text
erro_20261004_200530.png
```

Esses arquivos ajudam a descobrir o que aconteceu.

---

# 29. Tentativas automáticas

Quando uma consulta apresenta falha, o programa realiza novas tentativas conforme:

```text
config.json
```

campo:

```text
tentativas
```

Se mesmo depois das tentativas a consulta não funcionar, a carga é registrada como erro e o programa continua para a próxima.

---

# 30. Página sendo recarregada

O sistema possui uma rotina de recarga periódica da página.

Isso é utilizado para evitar que a sessão fique parada por muito tempo.

Se uma consulta for interrompida durante uma recarga, o programa tenta novamente.

---

# 31. Sessão expirada

Se aparecer uma mensagem indicando que a sessão expirou ou que não foi possível acessar o sistema:

Execute:

```powershell
python login.py
```

Faça o login novamente.

Depois execute a automação normalmente:

```powershell
python consultar.py
```

---

# 32. Problema: "Não consegui conectar"

Se aparecer algo semelhante a:

```text
Não consegui conectar
```

faça:

### 1. Feche o Chrome.

### 2. Se necessário, execute:

```powershell
taskkill /F /IM chrome.exe
```

### 3. Execute novamente:

```powershell
python consultar.py
```

Se o problema persistir, execute:

```powershell
python verificar_ambiente.py
```

---

# 33. Utilização diária no trabalho

Depois que o computador já estiver configurado, a rotina normal é simples.

## PASSO 1

Abra o PowerShell.

## PASSO 2

Entre na pasta:

```powershell
cd C:\AutomacaoComprovei\comprovei_automacao
```

## PASSO 3

Ative o ambiente:

```powershell
.\.venv\Scripts\Activate.ps1
```

## PASSO 4

Abra:

```text
cargas.xlsx
```

## PASSO 5

Preencha as cargas.

## PASSO 6

Salve e **feche o LibreOffice**.

## PASSO 7

Execute:

```powershell
python consultar.py
```

## PASSO 8

Aguarde a conclusão.

## PASSO 9

Abra novamente:

```text
cargas.xlsx
```

Confira:

* Resultado;
* Status;
* Observação.

---

# 34. Para atualizar cargas já processadas

Se quiser consultar novamente todas:

```powershell
python consultar.py --reprocessar-tudo
```

Isso é especialmente útil para cargas que estavam:

```text
INCOMPLETA
```

e podem ter recebido novos documentos posteriormente.

---

# 35. Modo do navegador

O modo padrão é:

```json
"modo_navegador": "cdp"
```

### CDP

O Chrome permanece aberto após o programa terminar.

Vantagens:

* mantém a sessão;
* facilita o acompanhamento visual;
* permite reutilizar o login;
* facilita diagnóstico.

---

Também existe:

```json
"modo_navegador": "launch"
```

Nesse modo, o Playwright gerencia o navegador e pode fechá-lo ao final.

O modo `cdp` é o recomendado para utilização no trabalho.

---

# 36. Boas práticas

### Antes de executar

* Verifique se o Chrome está funcionando.
* Confirme se está conectado ao sistema.
* Confira as cargas na planilha.
* Salve o `cargas.xlsx`.
* Feche o LibreOffice.

### Durante a execução

* Não feche o Chrome.
* Não altere a planilha.
* Não execute duas instâncias do programa simultaneamente.

### Depois da execução

* Abra `cargas.xlsx`.
* Confira as cargas `INCOMPLETA`.
* Verifique a coluna `Observação`.
* Se necessário, consulte novamente com:

```powershell
python consultar.py --reprocessar-tudo
```

---

# 37. Segurança

O programa não deve armazenar a senha do usuário no código.

O login é realizado manualmente no Chrome.

A sessão autenticada fica armazenada no perfil:

```text
perfil_chrome\
```

Não compartilhe essa pasta com outras pessoas.

Se o pendrive for utilizado em outro computador, o ideal é realizar um novo login nesse computador.

---

# 38. Transportando pelo pendrive

A pasta que deve ser levada para o serviço é:

```text
comprovei_automacao
```

Ela deve conter pelo menos:

```text
config.json
requirements.txt
consultar.py
login.py
nucleo.py
verificar_ambiente.py
inspecionar.py
cargas.xlsx
```

### Não é necessário levar:

```text
.venv\
```

se você pretende instalar o ambiente novamente no computador do trabalho.

Também não é necessário levar arquivos temporários de:

```text
logs\
prints\
traces\
inspecao\
```

caso sejam apenas diagnósticos antigos.

---

# 39. Instalação rápida em um computador novo

Resumo:

```powershell
winget install -e --id Python.Python.3.12
```

Feche e abra o PowerShell.

```powershell
cd C:\AutomacaoComprovei\comprovei_automacao
```

Crie o ambiente:

```powershell
py -m venv .venv
```

Ative:

```powershell
.\.venv\Scripts\Activate.ps1
```

Instale:

```powershell
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Teste:

```powershell
python -c "from playwright.sync_api import sync_playwright; print('Playwright OK')"
```

Depois:

```powershell
python verificar_ambiente.py
```

Faça o login:

```powershell
python login.py
```

E finalmente:

```powershell
python consultar.py --limite 3
```

Se o teste funcionar, execute:

```powershell
python consultar.py
```

---

# 40. Comandos principais — resumo

| Objetivo              | Comando                                                               |
| --------------------- | --------------------------------------------------------------------- |
| Ativar ambiente       | `.\.venv\Scripts\Activate.ps1`                                        |
| Verificar Python      | `py --version`                                                        |
| Verificar ambiente    | `python verificar_ambiente.py`                                        |
| Fazer login           | `python login.py`                                                     |
| Inspecionar sistema   | `python inspecionar.py`                                               |
| Testar algumas cargas | `python consultar.py --limite 3`                                      |
| Processar uma linha   | `python consultar.py --linha 5`                                       |
| Consultar uma carga   | `python consultar.py --carga NUMERO --de DD/MM/AAAA --ate DD/MM/AAAA` |
| Processar pendentes   | `python consultar.py`                                                 |
| Reprocessar tudo      | `python consultar.py --reprocessar-tudo`                              |
| Teste com diagnóstico | adicionar `--debug`                                                   |

---

# 41. Fluxo recomendado

```text
                 ┌─────────────────────┐
                 │     cargas.xlsx     │
                 └──────────┬──────────┘
                            │
                            ▼
                  Preencher as cargas
                            │
                            ▼
                     Salvar e fechar
                       o LibreOffice
                            │
                            ▼
                  python consultar.py
                            │
                            ▼
                  Acessa TNS/Comprovei
                            │
                            ▼
                    Rotas > Consulta
                            │
                            ▼
                    Consulta em lote
                            │
                            ▼
              Lê DOC. FINALIZADOS (X/Y)
                            │
                            ▼
                 ┌──────────┴──────────┐
                 │                     │
                 ▼                     ▼
              X = Y                 X < Y
                 │                     │
                 ▼                     ▼
             COMPLETA              INCOMPLETA
                 │                     │
                 └──────────┬──────────┘
                            ▼
                       salva XLSX
                            │
                            ▼
                    abrir no Calc
```

---

# 42. Resultado esperado

O objetivo da automação é transformar uma consulta manual e repetitiva em um processo simples:

```text
Preencher cargas
      ↓
Executar programa
      ↓
Consultar Comprovei
      ↓
Identificar DOC. FINALIZADOS
      ↓
Classificar automaticamente
      ↓
Salvar na planilha
```

Com isso, o usuário não precisa consultar carga por carga manualmente.

---

# 43. Observação importante

O funcionamento depende da interface do **TNS/Comprovei**.

Se o sistema sofrer alterações nos:

* campos;
* botões;
* textos;
* filtros;
* cabeçalhos;
* URLs;

pode ser necessário atualizar os seletores ou configurações do programa.

Os arquivos `inspecionar.py` e `config.json` existem justamente para facilitar essa manutenção.

---

## Fim

**Automação TNS Gestão de Entregas — Comprovei**

Tecnologias:

* Python
* Playwright
* Google Chrome
* LibreOffice Calc
* XLSX
* Chrome CDP



