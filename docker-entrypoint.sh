#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: docker run tex-hebrew [options] [markdown-file]

Options:
  --main <path>      Path to main TeX template (default: $DEFAULT_MAIN_TEX)
  --config <path>    Path to config TeX file (default: $DEFAULT_CONFIG_TEX)
  --output <path>    Output PDF path, or '-' for stdout (default: derived)
  --title <text>     Override document title (default: derived from input)
  --author <text>    Override author (default: DOC_AUTHOR env)
  --jobname <name>   Override LaTeX jobname (sanitized for output filename)
  --stdin            Read Markdown from stdin instead of a file
  --help             Show this message
EOF
}

main_template="${MAIN_TEX_PATH:-${DEFAULT_MAIN_TEX:-/opt/tex-template/main.tex}}"
config_template="${CONFIG_TEX_PATH:-${DEFAULT_CONFIG_TEX:-/opt/tex-template/config.tex}}"
mdtex_script="${MDTEX_SCRIPT:-/opt/tex-template/mdtex.sh}"
output_path=""
input_mode="path"
input_arg=""
doc_title_override="${DOC_TITLE:-}"
doc_author_override="${DOC_AUTHOR:-}"
job_name_override="${DOC_JOBNAME:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --main)
      [[ $# -lt 2 ]] && { echo "Missing value for --main" >&2; exit 1; }
      main_template="$2"; shift 2 ;;
    --config)
      [[ $# -lt 2 ]] && { echo "Missing value for --config" >&2; exit 1; }
      config_template="$2"; shift 2 ;;
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
    --stdin)
      if [[ "$input_mode" == "path" && -z "$input_arg" ]]; then
        input_mode="stdin"
        shift
      else
        echo "--stdin cannot be combined with file arguments" >&2
        exit 1
      fi ;;
    --help|-h)
      usage
      exit 0 ;;
    --)
      shift
      if [[ "$input_mode" == "stdin" ]]; then
        echo "--stdin cannot be combined with file arguments" >&2
        exit 1
      fi
      if [[ $# -gt 0 ]]; then
        input_arg="$1"
        shift
        if [[ $# -gt 0 ]]; then
          echo "Multiple input files provided." >&2
          exit 1
        fi
      fi
      break ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1 ;;
    *)
      if [[ "$input_mode" == "stdin" ]]; then
        echo "--stdin cannot be combined with file arguments" >&2
        exit 1
      fi
      if [[ -n "$input_arg" ]]; then
        echo "Multiple input files provided." >&2
        exit 1
      fi
      input_arg="$1"
      shift ;;
  esac
done

if [[ "$input_mode" == "path" && -z "$input_arg" ]]; then
  usage >&2
  exit 1
fi

[[ -f "$main_template" ]] || { echo "Main template not found: $main_template" >&2; exit 1; }
[[ -f "$config_template" ]] || { echo "Config template not found: $config_template" >&2; exit 1; }
[[ -x "$mdtex_script" ]] || { echo "mdtex.sh not executable at $mdtex_script" >&2; exit 1; }

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

cp "$main_template" "$workdir/main.tex"
cp "$config_template" "$workdir/config.tex"

markdown_path="$workdir/input.md"
base_name="document"
abs_input=""

if [[ "$input_mode" == "stdin" ]]; then
  cat > "$markdown_path"
else
  abs_input="$(realpath "$input_arg")"
  if [[ ! -f "$abs_input" ]]; then
    echo "Markdown file not found: $input_arg" >&2
    exit 1
  fi
  cp "$abs_input" "$markdown_path"
  base_name="$(basename "${abs_input}")"
  base_name="${base_name%.*}"
fi

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

if [[ -z "$output_path" ]]; then
  if [[ "$input_mode" == "path" ]]; then
    output_path="$(dirname "${abs_input}")/${job_name}.pdf"
  else
    output_path="-"
  fi
fi

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
