export OSH="$HOME/.oh-my-bash"
OSH_THEME="edsonarios"
OSH_PLUGINS=(bash-preexec)
source "$OSH/oh-my-bash.sh"
export EDITOR='code --wait'

# The oh-my-bash theme rebuilds PS1 from scratch and drops the
# terminal-title escape sequence that /etc/bashrc normally embeds in
# it, so cosmic-term (and other terminals) never see a title update
# and just show "New Terminal". Send one ourselves: cwd while idle,
# the running command while one is executing.
_term_title() { printf '\e]0;%s\a' "$1"; }
_term_title_precmd() { _term_title "${PWD/#$HOME/\~}"; }
_term_title_preexec() { _term_title "$1"; }
preexec_functions+=(_term_title_preexec)
precmd_functions+=(_term_title_precmd)

# Backs up 2004scape (lostcity) account data (player saves + sqlite db) to ~/Downloads as a zip
lostcity-backup() {
    local engine=~/src/Server-289/engine
    local out=~/Downloads/lostcity-backup-$(date +%Y%m%d-%H%M%S).zip
    local tmp=$(mktemp -d)
    mkdir -p "$tmp/data"
    cp -r "$engine/data/players" "$tmp/data/"
    sqlite3 "$engine/db.sqlite" ".backup '$tmp/db.sqlite'"
    (cd "$tmp" && zip -rq9 "$out" .)
    rm -rf "$tmp"
    echo "$out"
}

# Restores 2004scape (lostcity) account data (player saves + sqlite db) from a lostcity-backup zip
lostcity-restore() {
    local zip="$1"
    if [[ -z "$zip" || ! -f "$zip" ]]; then
        echo "Usage: lostcity-restore <path-to-lostcity-backup.zip>" >&2
        return 1
    fi

    local engine=~/src/Server-289/engine
    if pgrep -f "$engine/node_modules/tsx/dist/preflight.cjs" >/dev/null; then
        echo "Server is still running. Stop it first, it holds the save files and db open." >&2
        return 1
    fi

    local tmp=$(mktemp -d)
    if ! unzip -q "$zip" -d "$tmp"; then
        echo "Failed to extract $zip" >&2
        rm -rf "$tmp"
        return 1
    fi
    if [[ ! -d "$tmp/data/players" || ! -f "$tmp/db.sqlite" ]]; then
        echo "$zip doesn't look like a lostcity-backup archive (missing data/players or db.sqlite)" >&2
        rm -rf "$tmp"
        return 1
    fi

    local safety=$(lostcity-backup)
    echo "Safety snapshot of current state saved to $safety before restoring."

    rm -rf "$engine/data/players"
    cp -r "$tmp/data/players" "$engine/data/"
    cp "$tmp/db.sqlite" "$engine/db.sqlite"
    rm -rf "$tmp"
    echo "Restored from $zip"
}
