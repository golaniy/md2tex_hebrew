# Hebrew Markdown to TeX via Docker

This repo includes a Docker setup that compiles a Hebrew Markdown file (with math) to a PDF using XeLaTeX and TeX Live's Hebrew support, without requiring local font/package management.

## Convert Markdown to PDF

### Usage

```
docker run --rm \
  -v "$(pwd)":/work \
  ghcr.io/golaniy/md2tex_hebrew:latest \
  --input /work/input.md \
  --output /work/output.pdf [options]
```

All file paths must be accessible inside the container; use `-v` to mount host files as shown above.

### Options

- `--input <path>`: Markdown input file inside the container (required).
- `--output <path>`: Destination PDF file inside the container (required).
- `--title <text>` / env `DOC_TITLE`: Override the document title (defaults to derived name).
- `--author <text>` / env `DOC_AUTHOR`: Set the author line (empty by default).
- `--main <path>`: Alternate `main.tex` (path inside the container).
- `--config <path>`: Alternate `config.tex` (path inside the container).

### Template overrides

Provide alternate templates on the command line:

- `--main <path>` points to a replacement `main.tex`.
- `--config <path>` points to a replacement `config.tex`.

Defaults are bundled in the image at `/opt/tex-template/main.tex` and `/opt/tex-template/config.tex`.

Example:

```
docker run --rm \
  -v "$(pwd)":/work \
  ghcr.io/golaniy/md2tex_hebrew:latest \
  --input /work/lecture.md --output /work/lecture.pdf \
  --main /work/custom_main.tex \
  --config /work/custom_config.tex \
  --title "Lecture" --author "Yotam"
```


### Minimal example

```
docker run --rm \
  -v "$(pwd)":/work \
  ghcr.io/golaniy/md2tex_hebrew:latest \
  --input /work/lecture.md --output /work/lecture.pdf
```


The PDF title defaults to the Markdown filename; override with `--title`/`DOC_TITLE`. Author defaults to empty; set it via `--author`/`DOC_AUTHOR`.

## CI build

The GitHub Actions workflow builds the Docker image on every push, keeping `ghcr.io/golaniy/md2tex_hebrew:latest` up to date.
