#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: docker run ghcr.io/golaniy/md2tex_hebrew:latest [options] < markdown.md > output.pdf

Options:
  --output <path>    Output PDF path, or '-' for stdout (default: -)
  --title <text>     Override document title (default: derived from input)
  --author <text>    Override author (default: DOC_AUTHOR env)
  --jobname <name>   Override LaTeX jobname / filename (sanitized)
  --help             Show this message

Template overrides:
  Supply alternative templates via environment variables:
    MAIN_TEX_CONTENT    Full contents of main.tex
    CONFIG_TEX_CONTENT  Full contents of config.tex
EOF
}

default_main="${DEFAULT_MAIN_TEX:-/opt/tex-template/main.tex}"
default_config="${DEFAULT_CONFIG_TEX:-/opt/tex-template/config.tex}"
mdtex_script="${MDTEX_SCRIPT:-/opt/tex-template/mdtex.sh}"
output_path="-"
doc_title_override="${DOC_TITLE:-}"
doc_author_override="${DOC_AUTHOR:-}"
job_name_override="${DOC_JOBNAME:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      [[ $# -lt 2 ]] && { echo "Missing value for --output" >&2; exit 1; }
      output_path="$2"; shift 2 ;;
    --title)
      [[ $# -lt 2 ]] && { echo "Missing value for --title" >&2; exit 1; }
      doc_title_override="$2"; shift 2 ;;
    --author)
      [[ $# -lt 2 ]] && { echo "Missing value for --author" >&2; exit 1; }
      doc_author_override="$2"; shift 2 ;;
    --jobname)
      [[ $# -lt 2 ]] && { echo "Missing value for --jobname" >&2; exit 1; }
      job_name_override="$2"; shift 2 ;;
    --help|-h)
      usage
      exit 0 ;;
    --)
      shift ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1 ;;
    *)
      echo "Positional arguments are not supported. Provide Markdown via stdin." >&2
      exit 1 ;;
  esac
done

[[ -x "$mdtex_script" ]] || { echo "mdtex.sh not executable at $mdtex_script" >&2; exit 1; }

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

if [[ -n "${MAIN_TEX_CONTENT:-}" ]]; then
  printf '%s' "$MAIN_TEX_CONTENT" > "$workdir/main.tex"
else
  cp "$default_main" "$workdir/main.tex"
fi

if [[ -n "${CONFIG_TEX_CONTENT:-}" ]]; then
  printf '%s' "$CONFIG_TEX_CONTENT" > "$workdir/config.tex"
else
  cp "$default_config" "$workdir/config.tex"
fi

markdown_path="$workdir/input.md"
cat > "$markdown_path" || { echo "Failed to read Markdown from stdin." >&2; exit 1; }
base_name="document"

if [[ -n "$job_name_override" ]]; then
  base_name="$job_name_override"
fi

sanitize_jobname() {
  local s="$1"
  s="${s//[^[:alnum:]]/_}"
  echo "$s"
}

job_name="$(sanitize_jobname "$base_name")"
[[ -n "$job_name" ]] || job_name="document"

doc_title="${doc_title_override:-$base_name}"
doc_author="$doc_author_override"

pushd "$workdir" >/dev/null
"$mdtex_script" -v "$markdown_path" >&2
if [[ ! -f "${markdown_path%.md}.tex" ]]; then
  echo "Expected TeX output not produced." >&2
  exit 1
fi
mv "${markdown_path%.md}.tex" data.tex

escape_latex() {
  local s="$1"
  s="${s//\\/\\textbackslash{}}"
  s="${s//&/\\&}"
  s="${s//#/\\#}"
  s="${s//%/\\%}"
  s="${s//$/\\$}"
  s="${s//_/\\_}"
  s="${s//^/\\textasciicircum{}}"
  s="${s//~/\\textasciitilde{}}"
  s="${s//{/\\{}"
  s="${s//}/\\}}"
  echo "$s"
}

escaped_title="$(escape_latex "$doc_title")"
escaped_author="$(escape_latex "$doc_author")"
cat > docmeta.tex <<EOF
\renewcommand{\DocTitle}{${escaped_title}}
\renewcommand{\DocAuthor}{${escaped_author}}
EOF

latexmk -jobname="$job_name" -xelatex -interaction=nonstopmode -halt-on-error main.tex >&2
popd >/dev/null

pdf_source="$workdir/${job_name}.pdf"
if [[ ! -f "$pdf_source" ]]; then
  echo "PDF generation failed." >&2
  exit 1
fi

if [[ "$output_path" == "-" ]]; then
  cat "$pdf_source"
else
  mkdir -p "$(dirname "$output_path")"
  cp "$pdf_source" "$output_path"
  echo "PDF written to $output_path" >&2
fi
