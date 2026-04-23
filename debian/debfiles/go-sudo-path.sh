# Sourced by createdeb.sh / createdeb-armhf.sh — do not run directly.
#
# `sudo ./createdeb.sh` runs as root with a short PATH → often picks /usr/bin/go (too old).
# `sh -c 'echo $PATH'` does not load ~/.profile / gvm, so we probe real binaries on disk and
# on-disk login shell `command -v go` as fallbacks.

_wirepod_go_version_ok() {
	local gv min want
	gv="$("$1" env GOVERSION 2>/dev/null | sed 's/^go//')"
	min="1.23"
	[ -n "$gv" ] || return 1
	want="$(printf '%s\n' "$min" "$gv" | sort -V | head -n1)"
	[ "$want" = "$min" ]
}

_wirepod_try_prepend_go_bin() {
	local g bindir
	g="$1"
	[ -x "$g" ] || return 1
	_wirepod_go_version_ok "$g" || return 1
	bindir="$(dirname "$g")"
	export PATH="$bindir:$PATH"
	return 0
}

# Prefer newest go1.x under base/ (e.g. .../gos/go1.23.12, .../sdk/go1.23.12)
_wirepod_pick_from_version_dirs() {
	local base="$1" d g
	[ -d "$base" ] || return 1
	shopt -s nullglob
	local dirs=( "$base"/go* )
	shopt -u nullglob
	[ "${#dirs[@]}" -gt 0 ] || return 1
	while IFS= read -r d; do
		[ -d "$d" ] || continue
		g="$d/bin/go"
		if _wirepod_try_prepend_go_bin "$g"; then
			return 0
		fi
	done <<< "$(printf '%s\n' "${dirs[@]}" | LC_ALL=C sort -Vr)"
	return 1
}

_wirepod_find_modern_go() {
	local uhome login_go

	if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
		uhome="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
		if [ -n "$uhome" ]; then
			# gvm: ~/.gvm/gos/go1.23.12/bin/go
			_wirepod_pick_from_version_dirs "$uhome/.gvm/gos" && return 0
			# official tarball: ~/sdk/go1.23.12/bin/go
			_wirepod_pick_from_version_dirs "$uhome/sdk" && return 0
			# user go install default
			_wirepod_try_prepend_go_bin "$uhome/go/bin/go" && return 0
			# mise shims (if shim points to real go)
			[ -x "$uhome/.local/share/mise/shims/go" ] && _wirepod_try_prepend_go_bin "$uhome/.local/share/mise/shims/go" && return 0
		fi
		# Login shell: loads ~/.bash_profile / gvm for typical setups
		if command -v sudo >/dev/null 2>&1; then
			login_go="$(sudo -u "$SUDO_USER" -H bash -lc 'command -v go' 2>/dev/null)"
			if [ -n "$login_go" ] && [ -x "$login_go" ]; then
				_wirepod_try_prepend_go_bin "$login_go" && return 0
			fi
		fi
	fi

	# System-wide install (works for root or user)
	_wirepod_try_prepend_go_bin "/usr/local/go/bin/go" && return 0

	# snap
	_wirepod_try_prepend_go_bin "/snap/go/current/bin/go" && return 0

	return 1
}

_wirepod_require_go_123() {
	local gv min want
	gv="$(go env GOVERSION 2>/dev/null | sed 's/^go//')"
	min="1.23"
	want="$(printf '%s\n' "$min" "$gv" | sort -V | head -n1)"
	if [ -z "$gv" ] || [ "$want" != "$min" ]; then
		echo "ERROR: module needs Go >= 1.23 (go.mod: go 1.23.0 + toolchain)." >&2
		echo "       Current: $(command -v go 2>/dev/null) ($(go version 2>&1 || echo 'go missing'))" >&2
		if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
			echo "       Install Go 1.23+ for user $SUDO_USER (e.g. gvm, https://go.dev/dl/ → /usr/local/go), then run: sudo ./createdeb.sh <version>" >&2
		else
			echo "       Install Go 1.23+ and ensure it is first on PATH." >&2
		fi
		exit 1
	fi
}

_wirepod_find_modern_go || true
echo "Go for build: $(command -v go) ($(go version 2>&1))"
_wirepod_require_go_123
