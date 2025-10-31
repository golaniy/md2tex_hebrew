# Hebrew LaTeX Build With Docker

This repo includes a Docker setup that compiles the project with full TeX Live Hebrew support, avoiding the need to manage fonts and packages on the host machine.

## Build the image

```bash
docker build -t tex-hebrew .
```

## Convert Markdown to PDF

The entrypoint converts Markdown to LaTeX with `mdtex.sh`, compiles via `latexmk`, and cleans intermediate files. You can supply Markdown either by path (useful when mounting) or via standard input.

### Using a mounted file

```bash
docker run --rm \
  -v "$(pwd)":/data \
  tex-hebrew --output /data/lecture.pdf /data/lecture.md
```

### Streaming without mounts

```bash
docker run --rm -i tex-hebrew --stdin --output - < lecture.md > lecture.pdf
```

The PDF title defaults to the Markdown name; override it with `--title` (or `DOC_TITLE`). Populate the author line with `--author` or `DOC_AUTHOR`. To use different templates, pass `--main` and `--config` with paths inside the container (defaults live at `/opt/tex-template/main.tex` and `/opt/tex-template/config.tex`).
