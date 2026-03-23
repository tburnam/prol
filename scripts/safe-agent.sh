#!/bin/bash
# safe-agent — run an AI coding agent in a macOS sandbox that restricts file access
# Usage: ./safe-agent --cmd <agent> [-w /path/to/workspace] [--model <model>] [--dry-run] [agent flags...]
#
# Typically invoked via thin wrappers (safe-claude, safe-codex) rather than directly.
#
# Environment variables:
#   SANDBOX_ALLOW_READ — colon-separated list of extra read-only paths to allow

set -euo pipefail

SANDBOX_FILE="/tmp/safe-agent-sandbox.sb"
trap 'rm -f "$SANDBOX_FILE"' EXIT

WORKSPACE=""
SANDBOX_CMD=""
MODEL=""
DRY_RUN=false

# Parse flags (-w/--workspace, --cmd, --model, --dry-run), pass everything else through
while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        --cmd)
            SANDBOX_CMD="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# ── Error handling ──────────────────────────────────────────────────

if [[ -z "$SANDBOX_CMD" ]]; then
    echo "error: --cmd is required (e.g. --cmd claude, --cmd codex)" >&2
    exit 1
fi

if ! command -v sandbox-exec &>/dev/null; then
    echo "error: sandbox-exec not found — this script requires macOS" >&2
    exit 1
fi

CMD_PATH=$(command -v "$SANDBOX_CMD" 2>/dev/null || true)
if [[ -z "$CMD_PATH" ]]; then
    echo "error: command '$SANDBOX_CMD' not found in PATH" >&2
    exit 1
fi

# ── Resolve workspace: explicit flag > git repo root > cwd ─────────

if [[ -n "$WORKSPACE" ]]; then
    if [[ ! -d "$WORKSPACE" ]]; then
        echo "error: workspace directory does not exist: $WORKSPACE" >&2
        exit 1
    fi
    WORKSPACE=$(cd "$WORKSPACE" && pwd)
elif git rev-parse --show-toplevel &>/dev/null; then
    WORKSPACE=$(git rev-parse --show-toplevel)
else
    WORKSPACE=$(pwd)
fi

# ── Extra read-only paths from SANDBOX_ALLOW_READ ──────────────────

EXTRA_SANDBOX_READS=""
if [[ -n "${SANDBOX_ALLOW_READ:-}" ]]; then
    IFS=':' read -ra ALLOW_PATHS <<< "$SANDBOX_ALLOW_READ"
    for p in "${ALLOW_PATHS[@]}"; do
        if [[ -d "$p" ]]; then
            resolved=$(cd "$p" && pwd)
            EXTRA_SANDBOX_READS+=$'\n'"    (subpath \"$resolved\")"
        else
            echo "warning: SANDBOX_ALLOW_READ path does not exist, skipping: $p" >&2
        fi
    done
fi

# Build the extra reads block — only emit if there are actual paths
EXTRA_READS_BLOCK=""
if [[ -n "$EXTRA_SANDBOX_READS" ]]; then
    EXTRA_READS_BLOCK="(allow file-read*${EXTRA_SANDBOX_READS})"
fi

# ── Build agent-specific flags ─────────────────────────────────────

AGENT_FLAGS=()
if [[ -n "$MODEL" && "$SANDBOX_CMD" == "claude" ]]; then
    AGENT_FLAGS+=(--model "$MODEL")
fi

# ── Generate sandbox profile ───────────────────────────────────────

cat > "$SANDBOX_FILE" << EOF
(version 1)

(deny default)

;; ═══════════════════════════════════════════════════════════════════
;; 1. System runtime reads (10-system-runtime.sb)
;; ═══════════════════════════════════════════════════════════════════

;; Root directory literal — required for path traversal/resolution
(allow file-read* (literal "/"))

;; Home-directory path components — needed by Node.js realpathSync
;; for tools installed under \$HOME (e.g. nvm-managed binaries like codex).
;; Also covers intermediate dirs like ~/.local, ~/.local/share needed by
;; realpath(3) for uv/uvx Python path resolution.
;; These are literal (not subpath), so only stat/readdir on the directory
;; itself is allowed, not recursive access.
(allow file-read*
    (literal "/Users")
    (literal "$HOME")
    (literal "$HOME/.local")
    (literal "$HOME/.local/bin")
    (literal "$HOME/.local/lib")
    (literal "$HOME/.local/share"))

;; System binaries & libraries (covers /usr/local for Intel Macs)
(allow file-read*
    (subpath "/usr")
    (subpath "/bin")
    (subpath "/sbin")
    (subpath "/opt"))

;; macOS frameworks & system libraries
(allow file-read*
    (subpath "/System/Library")
    (subpath "/System/Cryptexes")
    (subpath "/Library/Apple")
    (subpath "/Library/Frameworks")
    (subpath "/Library/Fonts"))

;; Network / TLS / timezone
(allow file-read*
    (subpath "/private/etc/ssl")
    (literal "/private/etc/hosts")
    (literal "/private/etc/resolv.conf")
    (subpath "/private/var/db/timezone"))

;; Keychain databases (credentials for Claude, git, etc.)
(allow file-read*
    (subpath "$HOME/Library/Keychains")
    (subpath "/Library/Keychains"))

;; /etc /tmp /var symlinks + misc system config reads
(allow file-read*
    (literal "/etc")
    (literal "/tmp")
    (literal "/var")
    (literal "/private/etc/localtime")
    (literal "/private/etc/passwd")
    (literal "/private/etc/shells"))

;; /dev devices — entropy, TTYs, null, zero, random
(allow file-read*
    (subpath "/dev"))

;; sysctl reads (uname, hw info, etc.)
(allow sysctl-read)

;; file-ioctl for TTY control
(allow file-ioctl)

;; ═══════════════════════════════════════════════════════════════════
;; 2. Process / signal / mach / shm (scoped)
;; ═══════════════════════════════════════════════════════════════════

;; Process execution & forking (needed for child processes, MCP servers, etc.)
(allow process-exec)
(allow process-fork)

;; Process info — only for processes in the same sandbox
(allow process-info* (target same-sandbox))

;; Signal — only within same sandbox
(allow signal (target same-sandbox))

;; Mach task port — only same sandbox
(allow mach-priv-task-port (target same-sandbox))

;; Mach service lookups — scoped to essential services
(allow mach-lookup
    ;; Logging
    (global-name "com.apple.logd")
    (global-name "com.apple.logd.events")

    ;; DNS resolution
    (global-name "com.apple.dnssd.service")
    (global-name "com.apple.mDNSResponder")

    ;; Security / TLS / Keychain
    (global-name "com.apple.SecurityServer")
    (global-name "com.apple.securityd")
    (global-name "com.apple.trustd")
    (global-name "com.apple.trustd.agent")
    (global-name "com.apple.secinitd")

    ;; FSEvents (file watching)
    (global-name "com.apple.FSEvents")
    (global-name "com.apple.fseventsd")

    ;; CoreFoundation / system services
    (global-name "com.apple.cfprefsd.daemon")
    (global-name "com.apple.cfprefsd.agent")
    (global-name "com.apple.distributed_notifications@1v3")
    (global-name "com.apple.coreservices.launchservicesd")

    ;; System info
    (global-name "com.apple.system.opendirectoryd.api")
    (global-name "com.apple.runningboard")

    ;; Network
    (global-name "com.apple.nsurlsessiond")
    (global-name "com.apple.nesessionmanager.content-filter")

    ;; System network config (proxy/DNS detection for Rust reqwest/system-configuration)
    (global-name "com.apple.SystemConfiguration.configd")

    ;; Launch Services (for open, xdg-open equivalents)
    (global-name "com.apple.lsd.mapdb")
    (global-name "com.apple.lsd.modifydb")

    ;; Pasteboard (some CLIs need this)
    (global-name "com.apple.pasteboard.1")
)

;; IPC shared memory — only notification center
(allow ipc-posix-shm-read-data
    (ipc-posix-name "apple.shm.notification_center"))

;; System sockets (PF_SYSTEM)
(allow system-socket)

;; ═══════════════════════════════════════════════════════════════════
;; 3. Temp read/write + device writes
;; ═══════════════════════════════════════════════════════════════════

(allow file-read* file-write*
    (subpath "/private/tmp")
    (subpath "/private/var/folders")
    (subpath "/var/folders"))

(allow file-write*
    (regex #"^/dev/ttys[0-9]+$")
    (literal "/dev/null")
    (literal "/dev/tty")
    (literal "/dev/ptmx")
    (literal "/dev/dtracehelper"))

;; ═══════════════════════════════════════════════════════════════════
;; 4. Network (allow all — Agent Safehouse threat model:
;;    filesystem containment, not network filtering)
;; ═══════════════════════════════════════════════════════════════════

(allow network*)

;; ═══════════════════════════════════════════════════════════════════
;; 5. Apple Command Line Tools reads
;; ═══════════════════════════════════════════════════════════════════

(allow file-read*
    (subpath "/Library/Developer/CommandLineTools")
    (subpath "/Applications/Xcode.app")
    (subpath "/Applications/Xcode-beta.app"))

;; ═══════════════════════════════════════════════════════════════════
;; 6. Toolchain cache/config RW (30-toolchains)
;; ═══════════════════════════════════════════════════════════════════

;; Node.js ecosystem
(allow file-read* file-write*
    (subpath "$HOME/.nvm")
    (subpath "$HOME/.npm")
    (subpath "$HOME/.yarn")
    (subpath "$HOME/.pnpm-store")
    (subpath "$HOME/.local/share/pnpm")
    (subpath "$HOME/.local/share/npm")
    (subpath "$HOME/Library/pnpm")
    (subpath "$HOME/.cache/node")
    (subpath "$HOME/.local/share/corepack"))

;; Deno
(allow file-read* file-write*
    (subpath "$HOME/.deno"))

;; Bun
(allow file-read* file-write*
    (subpath "$HOME/.bun")
    (subpath "$HOME/.cache/bun"))

;; Python ecosystem
(allow file-read* file-write*
    (subpath "$HOME/.pyenv")
    (subpath "$HOME/.cache/pip")
    (subpath "$HOME/.cache/uv")
    (subpath "$HOME/.local/share/uv")
    (subpath "$HOME/.local/lib")
    (subpath "$HOME/miniconda3")
    (subpath "$HOME/anaconda3")
    (subpath "$HOME/.conda"))
(allow file-read* file-write*
    (literal "$HOME/.local/bin/uv")
    (literal "$HOME/.local/bin/uvx"))
(allow file-read*
    (literal "$HOME/.local/bin/python")
    (literal "$HOME/.local/bin/python3"))

;; Go
(allow file-read* file-write*
    (subpath "$HOME/go")
    (subpath "$HOME/.cache/go-build"))

;; Rust
(allow file-read* file-write*
    (subpath "$HOME/.cargo")
    (subpath "$HOME/.rustup"))

;; ═══════════════════════════════════════════════════════════════════
;; 7. Locally installed tools + config (read + execute)
;; ═══════════════════════════════════════════════════════════════════

(allow file-read*
    (subpath "$HOME/.local/bin")
    (subpath "$HOME/.config"))

;; ═══════════════════════════════════════════════════════════════════
;; 8. Git + SCM CLI grants (50-integrations-core)
;; ═══════════════════════════════════════════════════════════════════

;; Git config — read-only
(allow file-read*
    (literal "$HOME/.gitconfig")
    (regex #"^$HOME/\\.gitconfig\\.")
    (literal "$HOME/.gitignore")
    (literal "$HOME/.gitignore_global")
    (subpath "$HOME/.config/git"))

;; SSH — read-only, config + known_hosts only (NOT private keys)
(allow file-read*
    (literal "$HOME/.ssh")
    (literal "$HOME/.ssh/config")
    (literal "$HOME/.ssh/known_hosts")
    (literal "$HOME/.ssh/known_hosts2"))

;; GitHub CLI — read+write
(allow file-read* file-write*
    (subpath "$HOME/.config/gh")
    (subpath "$HOME/.cache/gh"))

;; ═══════════════════════════════════════════════════════════════════
;; 9. Container runtime deny (50-integrations-core)
;; ═══════════════════════════════════════════════════════════════════

(deny file-read* file-write*
    (literal "/var/run/docker.sock")
    (literal "$HOME/.docker/run/docker.sock")
    (literal "$HOME/.colima/default/docker.sock")
    (literal "$HOME/.orbstack/run/docker.sock")
    (literal "/var/run/podman/podman.sock")
    (regex #".*/podman\\.sock\$"))

;; ═══════════════════════════════════════════════════════════════════
;; 10. Agent profile grants (60-agents)
;; ═══════════════════════════════════════════════════════════════════

;; Claude Code
(allow file-read* file-write*
    (subpath "$HOME/.claude")
    (regex #"^$HOME/\\.claude\\.json")
    (subpath "$HOME/.local/share/claude")
    (subpath "$HOME/.config/claude")
    (subpath "$HOME/.cache/claude")
    (subpath "$HOME/Library/Caches/claude-cli-nodejs"))
(allow file-read*
    (literal "$HOME/.local/bin/claude"))

;; Codex
(allow file-read* file-write*
    (subpath "$HOME/.codex")
    (subpath "$HOME/.cache/codex"))

;; Cursor
(allow file-read* file-write*
    (subpath "$HOME/.cursor")
    (subpath "$HOME/Library/Application Support/Cursor")
    (subpath "$HOME/Library/Caches/Cursor"))

;; Gemini
(allow file-read* file-write*
    (subpath "$HOME/.gemini")
    (subpath "$HOME/.cache/gemini"))

;; ═══════════════════════════════════════════════════════════════════
;; 11. Workspace RW
;; ═══════════════════════════════════════════════════════════════════

(allow file-read* file-write*
    (subpath "$WORKSPACE"))

;; Parent of workspace — needed by mkdir -p / realpath with absolute paths
(allow file-read*
    (literal "$(dirname "$WORKSPACE")"))

;; ═══════════════════════════════════════════════════════════════════
;; 12. Extra read-only paths (SANDBOX_ALLOW_READ)
;; ═══════════════════════════════════════════════════════════════════

$EXTRA_READS_BLOCK

;; ═══════════════════════════════════════════════════════════════════
;; 13. ~/.cache writable (general caches)
;; ═══════════════════════════════════════════════════════════════════

(allow file-read* file-write*
    (subpath "$HOME/.cache"))

EOF

# ── Dry-run mode: print profile and exit ───────────────────────────

if [[ "$DRY_RUN" == true ]]; then
    echo "=== Sandbox profile ($SANDBOX_FILE) ===" >&2
    cat "$SANDBOX_FILE"
    echo "" >&2
    echo "=== Would execute: sandbox-exec -f $SANDBOX_FILE $SANDBOX_CMD ${AGENT_FLAGS[*]+"${AGENT_FLAGS[*]}"} $* ===" >&2
    exit 0
fi

# ── Execute in sandbox ─────────────────────────────────────────────

sandbox-exec -f "$SANDBOX_FILE" "$SANDBOX_CMD" "${AGENT_FLAGS[@]+"${AGENT_FLAGS[@]}"}" "$@"
