FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        curl \
        ca-certificates \
        chktex \
        fonts-dejavu-core \
        gawk \
        git \
        ghostscript \
        gnupg \
        iputils-ping \
        latexmk \
        bubblewrap \
        libfile-homedir-perl \
        liblog-log4perl-perl \
        libyaml-tiny-perl \
        lmodern \
        make \
        pinentry-curses \
        poppler-utils \
        ripgrep \
        sudo \
        texlive-extra-utils \
        texlive-fonts-recommended \
        texlive-lang-portuguese \
        texlive-latex-extra \
        texlive-latex-recommended \
        texlive-pictures \
        texlive-publishers \
    && groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash vscode \
    && install -d -m 0700 -o vscode -g vscode /home/vscode/.gnupg \
    && echo "vscode ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
