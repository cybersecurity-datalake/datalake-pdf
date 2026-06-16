# Uso do DevContainer para LaTeX

O DevContainer deste repositório foi simplificado para um fluxo de documento
único: `src/main.tex` gera `output/main.pdf`, e os arquivos temporários da
build também ficam em `output/`.

## Início rápido

1. Abra o repositório no VS Code.
2. Execute `Dev Containers: Rebuild and Reopen in Container`.
3. No terminal do container, rode:

```bash
latexmk -pdf -interaction=nonstopmode -file-line-error -halt-on-error -outdir=output src/main.tex
```

## Ferramentas instaladas

- `gpg`, `gpg-agent` e `pinentry-curses` para assinatura de commits
- `latexmk`
- `chktex`
- `latexindent`
- `gawk` e `ping` para compatibilidade e diagnóstico no container
- TeX Live com pacotes usados pelo documento inicial
- extensão `james-yu.latex-workshop`

## Observação sobre Codex CLI

O container instala `gawk` porque o instalador atual do Codex CLI usa uma
checagem de checksum que falha com o `mawk` padrão do Debian slim. Com `gawk`
presente, `curl -fsSL https://chatgpt.com/codex/install.sh | sh` funciona no
usuário `vscode`.

## Automação do ambiente

- `initializeCommand`: executa `.devcontainer/initialize-host-env.sh` no host e
  gera os arquivos usados pelo Docker Compose antes do container subir
- `postCreateCommand`: executa `.devcontainer/post-create-validate.sh` e valida
  ferramentas principais, DNS, HTTPS, setup de GPG no container e a checagem
  de checksum usada pelo instalador do Codex CLI
- `postAttachCommand`: atualiza o TTY do `gpg-agent` a cada nova conexão do VS
  Code ao container
- `postStartCommand`: executa `.devcontainer/start-watchers.sh`
- `start-watchers.sh`: inicia `latexmk -pvc` para `src/main.tex`

## Assinatura GPG no DevContainer

Em Linux local, o DevContainer agora usa o `gpg-agent` do host em vez de montar
`~/.gnupg` diretamente como home do container.

O fluxo é:

1. `initialize-host-env.sh` detecta `~/.gnupg` e o socket retornado por
   `gpgconf --list-dir agent-extra-socket`.
2. O Compose monta `~/.gnupg` em `/home/vscode/.host-gnupg` como somente
   leitura.
3. O mesmo Compose encaminha o socket do host para
   `/home/vscode/.gnupg/S.gpg-agent` dentro do container.
4. `post-create-validate.sh` copia o keyring público e a trustdb para
   `/home/vscode/.gnupg`, que permanece gravável no container.

Isso evita o problema clássico de montar o diretório inteiro do GPG do host
como `$HOME/.gnupg` do container, o que quebra permissões, locks e sockets.

Se o host não tiver `~/.gnupg` ou o socket extra do `gpg-agent`, o container
continua subindo, mas commits assinados dentro dele não funcionarão até o agente
estar disponível no host.

## Identidade Git no container

No DevContainer local, `initialize-host-env.sh` também lê `git config --global`
do host e encaminha `user.name` e `user.email` para o container via variáveis de
ambiente do Compose.

Durante o `postCreateCommand`, esses valores são aplicados com `git config
--global` no usuário `vscode`. Se a identidade Git não estiver configurada no
host, o container sobe normalmente e apenas registra que o Git interno ficou sem
usuário configurado.

## Logs

- `/tmp/devcontainer-post-create.log`
- `/tmp/devcontainer-watchers.log`
- `/tmp/latex-watch-main.log`
- `/tmp/devcontainer-latex-pids`

## Limites de recursos

Os limites ficam em `.devcontainer/.env.resources`:

- `MEM_LIMIT=2G`
- `CPU_LIMIT=1`

Eles são lidos pelo `initialize-host-env.sh`, que gera `.devcontainer/.env`
para o Docker Compose local. Em Codespaces, o tipo de máquina escolhido
continua prevalecendo.
