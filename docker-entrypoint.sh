#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOT'
Usage: docker run ghcr.io/golaniy/md2tex_hebrew:latest --input input.md --output output.pdf [options]

Required:
  --input <path>     Markdown source file
  --output <path>    Destination PDF file

Optional:
  --title <text>     Override document title (defaults to derived filename)
  --author <text>    Override author (defaults to DOC_AUTHOR env)
  --main <path>      Alternate main.tex file
  --config <path>    Alternate config.tex file
  --help             Show this message
EOT
}

default_main="${DEFAULT_MAIN_TEX:-/opt/tex-template/main.tex}"
default_config="${DEFAULT_CONFIG_TEX:-/opt/tex-template/config.tex}"
mdtex_script="${MDTEX_SCRIPT:-/opt/tex-template/mdtex.sh}"

input_path=""
output_path=""
doc_title_override="${DOC_TITLE:-}"
doc_author_override="${DOC_AUTHOR:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      [[ $# -lt 2 ]] && { echo "Missing value for --input" >&2; exit 1; }
      input_path="$2"; shift 2 ;;
    --output)
      [[ $# -lt 2 ]] && { echo "Missing value for --output" >&2; exit 1; }
      output_path="$2"; shift 2 ;;
    --title)
      [[ $# -lt 2 ]] && { echo "Missing value for --title" >&2; exit 1; }
      doc_title_override="$2"; shift 2 ;;
    --author)
      [[ $# -lt 2 ]] && { echo "Missing value for --author" >&2; exit 1; }
      doc_author_override="$2"; shift 2 ;;
    --main)
      [[ $# -lt 2 ]] && { echo "Missing value for --main" >&2; exit 1; }
      default_main="$2"; shift 2 ;;
    --config)
      [[ $# -lt 2 ]] && { echo "Missing value for --config" >&2; exit 1; }
      default_config="$2"; shift 2 ;;
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
      echo "Unknown argument: $1" >&2
      usage
      exit 1 ;;
  esac
done

[[ -x "$mdtex_script" ]] || { echo "mdtex.sh not executable at $mdtex_script" >&2; exit 1; }

if [[ -z "$input_path" || -z "$output_path" ]]; then
  echo "--input and --output are required." >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$default_main" ]]; then
  echo "main.tex template not found: $default_main" >&2
  exit 1
fi

if [[ ! -f "$default_config" ]]; then
  echo "config.tex template not found: $default_config" >&2
  exit 1
fi

if [[ ! -f "$input_path" ]]; then
  echo "Input file not found: $input_path" >&2
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

cp "$default_main" "$workdir/main.tex"
cp "$default_config" "$workdir/config.tex"

markdown_path="$workdir/input.md"
cp "$input_path" "$markdown_path"
base_name="$(basename "${input_path}")"
base_name="${base_name%.*}"

sanitize_jobname() {
  echo "$1" | tr -c '[:alnum:]' '_' | sed -e 's/^_\+//' -e 's/_\+$//'
}

job_name="$(sanitize_jobname "$base_name")"
[[ -n "$job_name" ]] || job_name="document"

doc_title="${doc_title_override:-$base_name}"
doc_author="$doc_author_override"

pushd "$workdir" >/dev/null
"$mdtex_script" -v "$markdown_path" >&2
mv "${markdown_path%.md}.tex" data.tex

escape_latex() {
  local s="$1"
  s="${s//\\/\\textbackslash{}}"
  s="${s//&/\&}"
  s="${s//#/\#}"
  s="${s//%/\%}"
  s="${s//$/\$}"
  s="${s//_/\_}"
  s="${s//^/\textasciicircum{}}"
  s="${s//~/\textasciitilde{}}"
  s="${s//{/\{}"
  s="${s//}/\}}"
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

mkdir -p "$(dirname "$output_path")"
cp "$pdf_source" "$output_path"
echo "PDF written to $output_path" >&2
