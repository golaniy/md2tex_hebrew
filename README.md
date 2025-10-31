# Hebrew LaTeX Build With Docker

This repo includes a Docker setup that compiles the project with full TeX Live Hebrew support, avoiding the need to manage fonts and packages on the host machine.

## Build the image

```bash
docker build -t tex-hebrew .
```

## Convert Markdown to PDF

The entrypoint converts Markdown to LaTeX with `mdtex.sh`, compiles via `latexmk`, and cleans intermediate files. Provide Markdown on standard input and capture the resulting PDF from standard output (or use --output to write to a file).

### Streaming without mounts

```bash
docker run --rm -i ghcr.io/golaniy/md2tex_hebrew:latest \
  --output - < lecture.md > lecture.pdf
```

The PDF title defaults to the Markdown name; override it with `--title` (or `DOC_TITLE`). Populate the author line with `--author` or `DOC_AUTHOR`. For custom templates, provide full file contents via the `MAIN_TEX_CONTENT` and/or `CONFIG_TEX_CONTENT` environment variables before running the container. For example, `-e MAIN_TEX_CONTENT="$(cat main.tex)"` overrides the primary template.

## CI build

The Bitbucket pipeline builds the Docker image on every push, ensuring the published image at `ghcr.io/golaniy/md2tex_hebrew:latest` stays up to date.
