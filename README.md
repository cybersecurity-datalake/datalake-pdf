# Datalake PDF

[![TeX CI](https://github.com/cybersecurity-datalake/datalake-pdf/actions/workflows/tex-ci.yml/badge.svg)](https://github.com/cybersecurity-datalake/datalake-pdf/actions/workflows/tex-ci.yml)
[![Open in Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?repository=cybersecurity-datalake/datalake-pdf&ref=main&devcontainer_path=.devcontainer)

Repositório do documento LaTeX do projeto Datalake de Cibersegurança. A estrutura foi preparada para um fluxo simples de um único PDF gerado a partir de `src/main.tex`, com todos os artefatos de build centralizados em `output/`.

## Arquitetura atual

Hoje o repositório está organizado para um documento principal único:

- `src/main.tex`: ponto de entrada da compilação.
- `output/`: PDF final e arquivos temporários gerados pelo LaTeX.
- `.devcontainer/`: ambiente reprodutível para desenvolvimento local e Codespaces.
- `.github/workflows/tex-ci.yml`: pipeline de validação que faz lint e build do PDF.
- `src/`: diretório do documento e de seus insumos, como capítulos, figuras, bibliografia e estilos.

O fluxo esperado é:

1. Escrever ou incluir conteúdo LaTeX a partir de `src/main.tex`.
2. Compilar localmente com `make pdf`.
3. Validar automaticamente no GitHub Actions a cada `push` e `pull_request`.

## Desenvolvimento local

### Pré-requisitos

- Docker Desktop ou Docker Engine
- VS Code
- Extensão Dev Containers

### Abrindo no DevContainer

1. Abra o repositório no VS Code.
2. Execute `Dev Containers: Rebuild and Reopen in Container`.
3. Depois da criação do ambiente, use o terminal do container para compilar:

```bash
make pdf
```

Para limpar artefatos antigos e forçar uma build reproduzível:

```bash
make clean
```

O DevContainer instala `latexmk`, `chktex`, TeX Live e a extensão LaTeX Workshop.
Em Linux local, ele também encaminha o `gpg-agent` do host para manter a
assinatura de commits dentro do container.

O ciclo de vida do DevContainer não inicia mais um watcher de `latexmk` em
background. Isso evita processos acumulados a cada restart do container e deixa
o build contínuo como uma ação explícita (`make watch`) ou do próprio
LaTeX Workshop.

## Uso com Codespaces

Abra um Codespace com o botão acima. O mesmo ambiente definido em `.devcontainer/` será usado para editar e compilar o documento sem dependências locais.

## CI

O workflow `tex-ci.yml` executa:

- verificação de existência do `src/main.tex`
- lint com `chktex`
- build limpo com `make clean && make pdf`
- publicação do `output/main.pdf` como artefato do job

## Estrutura sugerida para crescimento

Quando os arquivos LaTeX reais forem adicionados, a evolução natural desta estrutura é:

- `src/main.tex` incluindo arquivos como `src/chapters/*.tex`
- figuras em `src/images/`
- bibliografia em `src/references.bib`
- macros e estilos extras em `src/styles/`

Isso preserva um único artefato final, mas evita concentrar todo o conteúdo em um arquivo só.

## Referências do ambiente

- [DevContainer](.devcontainer/DEVCONTAINER.md)
- [Codespaces](.devcontainer/CODESPACES.md)

## Licença

Veja [LICENSE](LICENSE).
