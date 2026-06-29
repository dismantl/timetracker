#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

php_bin=$(command -v php)
make_bin=$(command -v "${MAKE_BIN:-make}")

ln -s "$php_bin" "$tmpdir/php"

output=$(PATH="$tmpdir" "$make_bin" -n -C "$repo_root" composer 2>&1)

if ! printf '%s\n' "$output" | grep -q 'php.*-dallow_url_fopen=On'; then
	printf '%s\n' "composer target did not use the available php command" >&2
	printf '%s\n' "$output" >&2
	exit 1
fi
if printf '%s\n' "$output" | grep -q '|  -dallow_url_fopen=On'; then
	printf '%s\n' "composer target piped installer into an empty PHP command" >&2
	exit 1
fi

if printf '%s\n' "$output" | grep -q '^dallow_url_fopen=On'; then
	printf '%s\n' "composer target emitted a malformed PHP flag as a command" >&2
	exit 1
fi
