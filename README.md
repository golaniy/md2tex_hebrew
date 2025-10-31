# Hebrew LaTeX Build With Docker

This repo includes a Docker setup that compiles a Hebrew Markdown file (with math) to a PDF using XeLaTeX and TeX Live's Hebrew support, without requiring local font/package management.

## Convert Markdown to PDF

### Usage

```
docker run --rm -i ghcr.io/golaniy/md2tex_hebrew:latest [options] \
  --output - < input.md > output.pdf
```

### Options

- `--output <path>`: Write the PDF to a file. Use `-` (default) to stream to stdout.
- `--title <text>` / env `DOC_TITLE`: Override the document title (defaults to derived name).
- `--author <text>` / env `DOC_AUTHOR`: Set the author line (empty by default).
- `--jobname <name>` / env `DOC_JOBNAME`: Override the XeLaTeX jobname (affects aux filenames).

### Template overrides

Provide full template contents via environment variables prior to running the container:

- `MAIN_TEX_CONTENT`: Replaces the default `main.tex`.
- `CONFIG_TEX_CONTENT`: Replaces the default `config.tex`.

Example:

```
docker run --rm -i \
  -e MAIN_TEX_CONTENT="$(cat custom_main.tex)" \
  -e CONFIG_TEX_CONTENT="$(cat custom_config.tex)" \
  ghcr.io/golaniy/md2tex_hebrew:latest \
  --title "Lecture" --author "Yotam" --output - \
  < lecture.md > lecture.pdf
```

### Minimal streaming example

```
docker run --rm -i ghcr.io/golaniy/md2tex_hebrew:latest \
  --output - < lecture.md > lecture.pdf
```

The PDF title defaults to the Markdown filename; override with `--title`/`DOC_TITLE`. Author defaults to empty; set it via `--author`/`DOC_AUTHOR`.

## CI build

The GitHub Actions workflow builds the Docker image on every push, keeping `ghcr.io/golaniy/md2tex_hebrew:latest` up to date.
