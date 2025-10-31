#!/usr/bin/env bash
set -euo pipefail

export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

usage() {
  echo "Usage: $0 -v <file_path>"
  exit 1
}

file_path=""
while getopts ":v:" opt; do
  case "${opt}" in
    v) file_path="${OPTARG}" ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; usage ;;
    :) echo "Option -${OPTARG} requires an argument." >&2; usage ;;
  esac
done

if [[ -z "${file_path}" ]]; then
  usage
fi

if [[ ! -f "${file_path}" ]]; then
  echo "File not found: ${file_path}" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
add_spaces_script="${ADD_SPACES_SCRIPT:-${script_dir}/add_spaces.py}"
lua_filter="${LUA_FILTER_PATH:-${script_dir}/final_filter.lua}"
pandoc_bin="${PANDOC_BIN:-$(command -v pandoc)}"

if [[ ! -x "$(command -v python3)" ]]; then
  echo "python3 is required but was not found." >&2
  exit 1
fi

if [[ -z "${pandoc_bin}" ]]; then
  echo "pandoc is required but was not found." >&2
  exit 1
fi

if [[ ! -f "${add_spaces_script}" ]]; then
  echo "add_spaces.py not found at ${add_spaces_script}" >&2
  exit 1
fi

if [[ ! -f "${lua_filter}" ]]; then
  echo "final_filter.lua not found at ${lua_filter}" >&2
  exit 1
fi

output_base="${file_path%.md}"
output_tex="${output_base}.tex"

python3 "${add_spaces_script}" < "${file_path}" | \
  "${pandoc_bin}" \
    --lua-filter="${lua_filter}" \
    --from=markdown+lists_without_preceding_blankline+hard_line_breaks \
    --metadata=lang:he \
    --metadata=dir:rtl \
    -o "${output_tex}"

echo "Conversion complete: ${output_tex} created" >&2

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "${output_tex}"
  echo "Contents copied to clipboard." >&2
fi
