FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    fontconfig \
    python3 \
    latexmk \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-xetex \
    texlive-plain-generic \
    texlive-pictures \
    texlive-science \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-lang-other \
    culmus \
    fonts-cardo \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-lang-arabic \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /work
WORKDIR /work

RUN fc-cache -f

COPY mdtex.sh add_spaces.py final_filter.lua main.tex config.tex /opt/tex-template/
RUN chmod +x /opt/tex-template/mdtex.sh
ENV DEFAULT_MAIN_TEX=/opt/tex-template/main.tex
ENV DEFAULT_CONFIG_TEX=/opt/tex-template/config.tex
ENV MDTEX_SCRIPT=/opt/tex-template/mdtex.sh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
