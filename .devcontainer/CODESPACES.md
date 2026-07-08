# GitHub Codespaces

Este repositório inclui um DevContainer preparado para editar e compilar um
único documento LaTeX a partir de `src/main.tex`, com saída em `output/`.

## Como usar

1. Clique em `Code` -> `Codespaces` -> `Create codespace on main`.
2. Aguarde a criação do ambiente.
3. Compile o documento no terminal:

```bash
make pdf
```

## O que o ambiente entrega

- TeX Live com os pacotes necessários para o template inicial
- `latexmk` para build incremental
- `chktex` para lint básico
- `latexindent` para formatação
- `gpg` instalado no container
- extensão VS Code LaTeX Workshop

## Comportamento padrão

- `postCreateCommand`: registra as versões de `latexmk`, `chktex` e `latexindent`
- `postStartCommand`: não inicia watchers persistentes; o startup termina limpo
- LaTeX Workshop: configurado para build em alterações de arquivos

## Logs

- ferramentas: `/tmp/devcontainer-tools.log`
- watcher: `/tmp/latex-watch-main.log`
- PID do watcher: `/tmp/devcontainer-latex-pids`

## Recursos

Os valores de referência do container ficam em `.devcontainer/.env.resources`:

- `MEM_LIMIT=2G`
- `CPU_LIMIT=1`

No Codespaces, o tipo de máquina escolhido no GitHub continua sendo a fonte
real dos limites de CPU e memória.

## Limitação de GPG

O encaminhamento do `gpg-agent` do host só existe no DevContainer local em
Linux. Em GitHub Codespaces não há acesso ao `gpg-agent` da sua máquina local,
então commits assinados dependem de uma configuração própria dentro do
Codespace.

## Mais informações

Veja [DEVCONTAINER.md](DEVCONTAINER.md).
