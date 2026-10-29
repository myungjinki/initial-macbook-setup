#!/bin/bash
# 🍎 맥 초기 세팅 스크립트
# 실행: bash -c "$(curl -fsSL https://raw.githubusercontent.com/myungjinki/initial-macbook-setup/main/mac-setup.sh)"
#   또는 받은 폴더에서: bash mac-setup.sh
set -uo pipefail
usage() {
  cat <<'EOF'
사용법: bash mac-setup.sh [옵션]
  (옵션 없음)     할 일을 확인하고 남은 것만 실행
  -n, --dry-run   아무것도 바꾸지 않고 할 일만 표로 보여 줌
  -h, --help      이 도움말
curl로 실행할 때 옵션: bash -c "$(curl -fsSL …/mac-setup.sh)" _ --dry-run
EOF
}
DRY_RUN=0
case "${1:-}" in
  "") ;;
  -n|--dry-run) DRY_RUN=1 ;;
  -h|--help) usage; exit 0 ;;
  *) echo "알 수 없는 옵션: $1" >&2; usage >&2; exit 1 ;;
esac
# 파일로 실행하면 스크립트 옆의 키·토큰을 읽음. curl로 실행하면 새로 만들거나 브라우저로 로그인
SCRIPT_DIR=""
[ -f "${BASH_SOURCE[0]:-}" ] && SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
beside() { [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$1" ]; }   # 스크립트 옆에 이 파일이 있는지

# ============================================================
#  📋 할 일 목록 — 여기에 한 줄씩 추가하면 끝!
#
#  형식: "종류:이름|화면에 보일 이름"
#    brew          → Homebrew 자체 (맨 처음에 두기)
#    cask:이름     → 앱 설치        (brew install --cask 이름)
#    formula:이름  → 터미널 도구    (brew install 이름)
#    group|제목    → 체크리스트의 묶음 제목
#    group:brew|제목 → 이 묶음의 fn은 Homebrew가 있어야 함 (없으면 건너뜀)
#    fn:이름       → 직접 만든 설정 (아래 '설정 함수' 참고)
#
#  앞에 # 을 붙이면 꺼짐, 지우면 켜짐
# ============================================================
TASKS=(
  "group|🍺 Homebrew"   # 맨 처음
  "brew|Homebrew"

  "group|🐚 Oh My Zsh"   # brew가 아닌 공식 스크립트로 설치
  "fn:oh_my_zsh|Oh My Zsh"

  "group|🔑 SSH 키·GitHub"   # 입력은 여기서 맨 먼저 받음 (ASKS_INPUT)
  "fn:ssh_key|SSH 키 (없으면 새로 만들기)"
  "fn:ssh_config|~/.ssh/config에 키체인 사용 설정"
  "fn:ssh_keychain|SSH 키 암호를 키체인에 저장 (처음 한 번 입력)"
  "fn:gh_login|GitHub 로그인 (브라우저)"
  "fn:ssh_key_github|SSH 키를 GitHub에 등록"

  "group|⚙️ 맥 설정"   # 새 설정은 이 묶음 끝에
  "fn:key_repeat|키 반복 속도 Fast · 반복 지연 Short"
  "fn:volume_min|음량 0"
  "fn:dock_clear|Dock 기본 앱 전부 빼기 (Finder·휴지통은 남음)"
  # "fn:finder_hidden|Finder 숨김 파일 보이기"

  "group:brew|⚙️ Homebrew가 있어야 하는 설정"   # brightness·git은 Xcode 도구 사용
  "fn:display_more_space|내장 디스플레이 해상도 'More Space'"
  "fn:brightness_max|내장 디스플레이 밝기 최대"
  "fn:git_user|git 사용자 이름·이메일"
  "fn:brew_path|새 터미널에서 brew 쓰기 (~/.zprofile)"
  "fn:git_pull_merge|git pull은 merge로 (pull.rebase false)"

  "group|📦 앱 설치"   # 새 설치는 이 묶음 끝에 (pkg형은 맨 앞)
  "cask:google-drive|Google Drive"   # pkg형: 설치 후 뜨는 창을 일찍 보도록
  "cask:rectangle|Rectangle (창 정리)"
  "cask:google-chrome|Chrome"
  "cask:claude|Claude 데스크톱"
  "cask:chatgpt|ChatGPT 데스크톱"
  "cask:discord|Discord"
  "formula:gh|GitHub CLI (gh)"
  # "formula:git|Git"
)

# 이 fn 항목들은 입력을 받아요 — 오래 걸리는 설치 전에 맨 먼저 실행
ASKS_INPUT="ssh_key ssh_keychain gh_login"

# git 이름·이메일은 맨 처음 물어봄 (ask_git_user)
GIT_NAME=""
GIT_EMAIL=""
# CI 전용: 입력이 필요하거나 CI 맥에서 못 도는 항목을 끔 (예: CI_SKIP="ssh_key gh_login")
skipped() { [[ " ${CI_SKIP:-} " == *" ${1#*:} "* ]]; }   # 예: skipped fn:volume_min

# ============================================================
#  ⚙️ 설정 함수 — fn:이름 을 쓰려면 두 개를 만들어요
#    check_이름 : 이미 돼 있는지 확인 (돼 있으면 건너뜀)
#    do_이름    : 실제로 설정하는 명령
#    off_이름   : (선택) 성공하면 이 항목은 꺼짐 — 값이나 파일이 없을 때
#    ask_이름   : (선택) 할 일이 남았으면 맨 처음 값을 물어봄 (do_보다 먼저, 같은 셸)
# ============================================================
# Xcode 도구(git·swift)가 있는지. 없을 때 git·swift를 부르면 설치 팝업이 뜸
has_xcode() { xcode-select -p >/dev/null 2>&1; }

# SSH 키: 스크립트 옆의 id_ed25519(.pub)를 ~/.ssh로 복사, 없으면 새로 만듦 (암호는 직접 정함)
check_ssh_key() { [ -f "$HOME/.ssh/id_ed25519" ] && [ -f "$HOME/.ssh/id_ed25519.pub" ]; }
do_ssh_key() {
  local f k="$HOME/.ssh/id_ed25519"
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh" || return 1
  if beside id_ed25519 && beside id_ed25519.pub; then
    for f in id_ed25519 id_ed25519.pub; do
      [ -f "$HOME/.ssh/$f" ] || cp "$SCRIPT_DIR/$f" "$HOME/.ssh/$f" || return 1
    done
  elif [ ! -f "$k" ]; then
    echo "🔑 새 SSH 키를 만들어요. 키 암호를 정해 주세요 (두 번 입력)"
    ssh-keygen -q -t ed25519 -C "${GIT_EMAIL:-$USER@$(scutil --get LocalHostName)}" -f "$k" || return 1
  fi
  chmod 600 "$k" && chmod 644 "$k.pub"
}

# SSH 키 암호를 키체인에서 꺼내 쓰도록 설정 (재부팅해도 다시 안 물음)
check_ssh_config() { grep -qi '^ *UseKeychain yes' "$HOME/.ssh/config" 2>/dev/null; }
do_ssh_config() {
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh" || return 1
  printf 'Host *\n  UseKeychain yes\n  AddKeysToAgent yes\n' >> "$HOME/.ssh/config" && chmod 600 "$HOME/.ssh/config"
}

# 암호를 키체인에 한 번 저장. 암호 없는 키면 할 일 없음
# 키체인 항목은 security로 안 보여서 에이전트에 올라왔는지로 확인
# (재부팅 직후엔 에이전트가 비어 '완료'로 나오지만, 키체인에서 꺼내므로 암호는 다시 안 물음)
check_ssh_keychain() {
  local k="$HOME/.ssh/id_ed25519" fp
  [ -f "$k" ] && [ -f "$k.pub" ] || return 1
  ssh-keygen -y -P "" -f "$k" >/dev/null 2>&1 && return 0
  fp=$(ssh-keygen -lf "$k.pub" | awk '{print $2}')
  ssh-add -l 2>/dev/null | grep -qF "$fp"
}
do_ssh_keychain() {
  check_ssh_key || do_ssh_key || return 1   # 맨 먼저 실행되니 키 복사가 아직일 수 있음
  ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"
}

# 키 반복: 설정 화면 기준 Fast = 2, Short = 15 (적용은 로그아웃 후)
check_key_repeat() {
  [ "$(defaults read -g KeyRepeat 2>/dev/null)" = 2 ] && [ "$(defaults read -g InitialKeyRepeat 2>/dev/null)" = 15 ]
}
do_key_repeat() {
  defaults write -g KeyRepeat -int 2 && defaults write -g InitialKeyRepeat -int 15 \
    && NOTES+=("⌨️  키 반복 설정은 로그아웃 후 다시 로그인하면 적용돼요")
}

# 음량 0
check_volume_min() { [ "$(osascript -e 'output volume of (get volume settings)')" = 0 ]; }
do_volume_min()    { osascript -e 'set volume output volume 0'; }

# Dock 기본 앱 전부 빼기 (실행 중인 앱은 그대로 보임)
check_dock_clear() { ! defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q tile-data; }
do_dock_clear()    { defaults write com.apple.dock persistent-apps -array && killall Dock; }

# Finder 숨김 파일 보이기 (꺼 둠)
check_finder_hidden() { [ "$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null)" = "1" ]; }
do_finder_hidden()    { defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder; }

# Oh My Zsh: brew 패키지가 없어 공식 스크립트로 설치
# 공식 스크립트는 git(Xcode 도구)이 필요해서, 없으면 GitHub 압축 파일로 설치
check_oh_my_zsh() { [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ] && [ -f "$HOME/.zshrc" ]; }
do_oh_my_zsh() {
  if has_xcode; then
    [ -d "$HOME/.oh-my-zsh" ] || { sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || return 1; }
  elif [ ! -d "$HOME/.oh-my-zsh" ]; then
    local tmp; tmp=$(mktemp -d) || return 1
    curl -fsSL https://github.com/ohmyzsh/ohmyzsh/archive/refs/heads/master.tar.gz | tar xz -C "$tmp" \
      && mv "$tmp/ohmyzsh-master" "$HOME/.oh-my-zsh" || return 1
  fi
  [ -f "$HOME/.zshrc" ] || cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
}

# 내장 디스플레이가 없으면(데스크톱 맥·덮개 닫힘) 해상도·밝기 항목은 꺼짐
# GPU의 'Bus: Built-In'은 데스크톱에도 있어서 연결 방식으로 확인
no_builtin_display() { ! system_profiler SPDisplaysDataType 2>/dev/null | grep -q 'Connection Type: Internal'; }
off_display_more_space() { no_builtin_display; }
off_brightness_max()     { no_builtin_display; }

# 내장 디스플레이 'More Space' — displayplacer로 자동 판별
# system_profiler는 외부 모니터가 있으면 값이 섞여서 쓰지 않음
builtin_block() {  # 내장 디스플레이 부분만 출력
  displayplacer list | awk '
    /^Persistent screen id:/ { if (b) exit; buf = "" }
    { buf = buf $0 "\n" }
    /^Type:/ && tolower($0) ~ /built.?in/ { b = 1 }
    END { if (b) printf "%s", buf }'
}
more_space_res() {  # More Space = 내장 디스플레이의 가장 큰 scaling:on 해상도
  local res
  res=$(builtin_block | awk '/^ *mode [0-9]+:/ && /scaling:on/ {
      match($0, /res:[0-9]+x[0-9]+/); r = substr($0, RSTART + 4, RLENGTH - 4)
      split(r, a, "x"); if (a[1] * a[2] > max) { max = a[1] * a[2]; best = r } }
    END { print best }')
  [ -n "$res" ] || { echo "More Space 해상도를 못 찾았어요" >&2; return 1; }
  echo "$res"
}
check_display_more_space() {
  command -v displayplacer >/dev/null || return 1
  local res; res=$(more_space_res) || return 1
  builtin_block | grep 'current mode' | grep -q "res:$res "
}
do_display_more_space() {
  command -v displayplacer >/dev/null || brew install displayplacer \
    || brew install jakehilborn/jakehilborn/displayplacer || return 1
  local id res mode
  id=$(builtin_block | awk '/^Persistent screen id:/{print $4; exit}')
  [ -n "$id" ] || { echo "내장 디스플레이를 못 찾았어요"; return 1; }
  res=$(more_space_res) || return 1
  # 같은 해상도 중 주사율이 가장 높은 모드 (ProMotion 120Hz)
  mode=$(builtin_block | awk -v r="res:$res " '
    /^ *mode [0-9]+:/ && index($0 " ", r) && /scaling:on/ {
      match($0, /hz:[0-9]+/); hz = substr($0, RSTART + 3, RLENGTH - 3) + 0
      m = $2; sub(":", "", m); if (hz > best) {best = hz; bm = m}
    }
    END {print bm}')
  [ -n "$mode" ] || { echo "$res 모드를 못 찾았어요"; return 1; }
  displayplacer "id:$id mode:$mode"
}

# 내장 디스플레이 밝기 (DisplayServices 비공개 API, swift는 Xcode 도구에 포함)
brightness() {  # brightness get | brightness set 1.0
  local f="${TMPDIR:-/tmp}/mac-setup-brightness.swift" src
  src=$(cat <<'SWIFT'
import Foundation
import CoreGraphics
let h = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
typealias GetFn = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32
typealias SetFn = @convention(c) (UInt32, Float) -> Int32
var ids = [CGDirectDisplayID](repeating: 0, count: 16); var n: UInt32 = 0
CGGetOnlineDisplayList(16, &ids, &n)
guard let d = ids.prefix(Int(n)).first(where: { CGDisplayIsBuiltin($0) != 0 }) else { print("내장 디스플레이 없음"); exit(1) }
let a = CommandLine.arguments
if a.count > 2, a[1] == "set", let v = Float(a[2]) {
  exit(unsafeBitCast(dlsym(h, "DisplayServicesSetBrightness"), to: SetFn.self)(d, v) == 0 ? 0 : 1)
}
var v: Float = 0
_ = unsafeBitCast(dlsym(h, "DisplayServicesGetBrightness"), to: GetFn.self)(d, &v)
print(v)
SWIFT
)
  [ "$(cat "$f" 2>/dev/null)" = "$src" ] || printf '%s\n' "$src" > "$f"   # 내용이 같으면 다시 안 씀
  swift "$f" "$@" 2>/dev/null
}
# Xcode 도구가 없으면 swift가 설치 팝업을 띄우므로 먼저 확인
check_brightness_max() { has_xcode || return 1; awk -v v="$(brightness get)" 'BEGIN { exit !(v >= 0.99) }'; }
do_brightness_max()    { brightness set 1.0; }

# git 사용자 (git은 Xcode 도구에 포함, 없으면 팝업이 뜨므로 먼저 확인)
# 아직 설정 안 됐으면 맨 처음 물어봄 (git은 나중에 Xcode 도구가 생긴 뒤 설정)
ask_git_user() {
  read -rp "📝 git 이름: " GIT_NAME </dev/tty
  read -rp "📝 git 이메일: " GIT_EMAIL </dev/tty
}
check_git_user() {
  has_xcode && [ -n "$(git config --global user.name)" ] && [ -n "$(git config --global user.email)" ]
}
do_git_user() {
  if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then echo "git 이름·이메일이 비어 있어요"; return 1; fi
  git config --global user.name "$GIT_NAME" && git config --global user.email "$GIT_EMAIL"
}

# gh: brew로 깔리기 전(맨 처음 로그인할 때)은 GitHub 릴리스 zip을 임시로 받아 씀
# 로그인 정보는 키체인에 저장돼서 나중에 brew로 깐 gh도 그대로 씀
GH_TMP="${TMPDIR:-/tmp}/mac-setup-gh"
gh_cmd() {
  if command -v gh >/dev/null; then gh "$@"
  elif [ -x "$GH_TMP" ]; then "$GH_TMP" "$@"
  else return 127; fi
}
get_gh() {
  { command -v gh >/dev/null || [ -x "$GH_TMP" ]; } && return 0
  local arch rel url sums zip tmp
  arch=$(uname -m); [ "$arch" = x86_64 ] && arch=amd64
  rel=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest) || return 1
  url=$(grep -o "https://[^\"]*macOS_$arch\.zip" <<< "$rel" | head -1)
  sums=$(grep -o 'https://[^"]*_checksums\.txt' <<< "$rel" | head -1)
  if [ -z "$url" ] || [ -z "$sums" ]; then echo "gh 다운로드 주소를 못 찾았어요"; return 1; fi
  tmp=$(mktemp -d) || return 1
  zip="${url##*/}"
  curl -fsSL "$url" -o "$tmp/$zip" && curl -fsSL "$sums" -o "$tmp/sums.txt" || return 1
  # 릴리스의 checksums.txt로 sha256 확인 (안 맞으면 실행 안 함)
  (cd "$tmp" && grep " $zip\$" sums.txt | shasum -a 256 -c -) >/dev/null || { echo "gh 체크섬이 안 맞아요"; return 1; }
  unzip -q "$tmp/$zip" -d "$tmp" && mv "$tmp"/gh_*/bin/gh "$GH_TMP"
}

# GitHub 로그인: 스크립트 옆의 gh_token 파일이 있으면 그걸로, 없으면 브라우저에서 코드 입력
check_gh_login() { gh_cmd auth status -h github.com >/dev/null 2>&1; }
do_gh_login() {
  local t="$SCRIPT_DIR/gh_token"
  get_gh || return 1
  if beside gh_token && [ -s "$t" ]; then
    chmod 600 "$t" && tr -d '[:space:]' < "$t" | gh_cmd auth login -h github.com --git-protocol ssh --with-token || return 1
  else
    echo "🌐 브라우저가 열리면 코드를 붙여 넣고(클립보드에 복사돼 있음) 승인해 주세요"
    open https://github.com/login/device
    gh_cmd auth login -h github.com --git-protocol ssh --web --clipboard --skip-ssh-key -s admin:public_key </dev/null || return 1
  fi
  gh_cmd auth status -h github.com
}

# SSH 키를 GitHub에 등록 (이미 있으면 건너뜀, 토큰에 admin:public_key 권한 필요)
check_ssh_key_github() {
  local k; k=$(awk '{print $2}' "$HOME/.ssh/id_ed25519.pub" 2>/dev/null) && [ -n "$k" ] || return 1
  gh_cmd ssh-key list 2>/dev/null | grep -qF "$k"
}
do_ssh_key_github() { gh_cmd ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(scutil --get ComputerName)"; }

# git pull 시 rebase 대신 merge (git은 Xcode 도구에 포함, 없으면 팝업이 뜨므로 먼저 확인)
check_git_pull_merge() { has_xcode && [ "$(git config --global pull.rebase)" = false ]; }
do_git_pull_merge()    { git config --global pull.rebase false; }

# 새 터미널에서도 brew가 잡히도록 ~/.zprofile에 PATH 등록
check_brew_path() { grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; }
do_brew_path()    { echo "eval \"\$($(command -v brew) shellenv)\"" >> "$HOME/.zprofile"; }

# ============================================================
#  아래는 엔진 부분 — 보통은 건드릴 필요 없어요
# ============================================================
LOG="$HOME/Library/Logs/mac-setup.log"   # 실행마다 이어 씀 (5000줄 넘으면 뒤 3000줄만 남김)
STATUS=()
IN_BREW_GROUP=()
FAILLOG=()
NOTES=()  # do_ 함수가 끝난 뒤 보여줄 안내

load_brew() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then eval "$("$b" shellenv)"; return 0; fi
  done
  return 1
}

# 이미 된 작업인지 확인 (비밀번호 필요 없음)
is_done() {
  local kind="${1%%:*}" name="${1#*:}"
  case "$kind" in
    brew)    load_brew ;;
    cask)    command -v brew >/dev/null && brew list --cask "$name" >/dev/null 2>&1 ;;
    formula) command -v brew >/dev/null && brew list --formula "$name" >/dev/null 2>&1 ;;
    fn)      "check_$name" >/dev/null 2>&1 ;;
    *)       return 1 ;;
  esac
}

# pkg 설치형 앱만 비밀번호가 필요 (일반 .app 복사는 필요 없음, brew가 없으면 일단 필요로 봄)
cask_needs_sudo() {
  command -v brew >/dev/null || return 0
  brew info --cask --json=v2 "$1" 2>/dev/null | grep -qE '"(pkg|installer)"'
}

# Homebrew가 필요한 작업인지 (cask/formula, 또는 group:brew 묶음 안의 항목) — 인자는 TASKS 번호
needs_brew() {
  case "${TASKS[$1]%%|*}" in cask:*|formula:*) return 0 ;; esac
  [ "${IN_BREW_GROUP[$1]:-0}" = 1 ]
}

# fn 작업의 선택 함수(off_이름·ask_이름)가 있으면 실행 — 예: run_hook off fn:ssh_key
run_hook() { [[ "$2" == fn:* ]] && declare -F "$1_${2#fn:}" >/dev/null && "$1_${2#fn:}"; }

# 입력을 받는 작업인지
asks_input() { [[ "$1" == fn:* && " $ASKS_INPUT " == *" ${1#fn:} "* ]]; }

# 실제 작업 실행
run_task() {
  local kind="${1%%:*}" name="${1#*:}"
  case "$kind" in
    brew)    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && load_brew ;;
    cask)    brew install --cask "$name" ;;
    formula) brew install "$name" ;;
    fn)      "do_$name" ;;
    *)       echo "알 수 없는 종류: $kind"; return 1 ;;
  esac
}

# 체크리스트 화면 그리기 — 표: 상태 │ 결과 │ 항목
# 기본 터미널(80×24)에 들어가도록 묶음은 한 줄로 접고, 진행 중·실패가 있는 묶음만 펼침 (draw full: 전부 펼침)
# bash는 한글·이모지의 화면 폭을 몰라서 UTF-8 바이트로 판단: 4바이트·한글 등 2칸, 글자 모양 선택자(FE0E·FE0F)·ZWJ 0칸, 나머지 1칸
fit() {  # fit 문자열 폭 → FIT(폭에 맞게 자르고 공백으로 채운 값), FIT_W(원래 폭)
  local LC_ALL=en_US.UTF-8 s="$1" max=$2 out="" w=0 full=0 i c cw b n len
  len=${#s}
  for ((i = 0; i < len; i++)); do
    c=${s:i:1}
    LC_ALL=C; b=${#c}; printf -v n '%d' "'$c"; LC_ALL=en_US.UTF-8
    [ "$n" -lt 0 ] && n=$((n + 256))
    if [ "$c" = $'\xef\xb8\x8f' ] || [ "$c" = $'\xef\xb8\x8e' ] || [ "$c" = $'\xe2\x80\x8d' ]; then cw=0
    elif [ "$b" -ge 4 ] || [ "${s:i+1:1}" = $'\xef\xb8\x8f' ] || { [ "$b" -eq 3 ] && [ "$n" -ge 227 ]; }; then cw=2
    else cw=1; fi
    full=$((full + cw))
    [ $((w + cw)) -le "$max" ] && [ "$out" = "${s:0:i}" ] && { out="$out$c"; w=$((w + cw)); }
  done
  FIT_W=$full
  printf -v FIT '%s%*s' "$out" $((max - w)) ""
}
cell() { case "${TASKS[$1]%%|*}" in group*) echo "${TASKS[$1]#*|}" ;; *) echo "  ${TASKS[$1]#*|}" ;; esac; }   # 항목 칸 글자 (항목은 들여 씀)
# 항목 칸 폭 = 가장 긴 글자, 칸 내용은 한 번만 계산해 둠
COL=4; CELL=()
for i in "${!TASKS[@]}"; do fit "$(cell "$i")" 999; [ "$FIT_W" -gt "$COL" ] && COL=$FIT_W; done
for i in "${!TASKS[@]}"; do fit "$(cell "$i")" "$COL"; CELL[i]=$FIT; done
fit "항목" "$COL"; HEAD_CELL=$FIT
LINE=$(printf '%*s' $((COL + 2)) "" | sed 's/ /─/g')
draw_task() {  # 항목 한 줄 (+ 실패 로그)
  local i=$1 icon note l
  case "${STATUS[$i]}" in
    pending) icon="⬜"; note="대기     " ;;
    running) icon="⏳"; note="진행 중  " ;;
    done)    icon="✅"; note="완료     " ;;
    skip)    icon="✅"; note="이미 됨  " ;;
    fail)    icon="❌"; note="실패     " ;;
    blocked) icon="⏭️"; note="brew 필요" ;;
    off)     icon="➖"; note="꺼짐     " ;;
  esac
  echo "│  $icon  │ ${note}│ ${CELL[i]} │"
  if [ "${STATUS[$i]}" = fail ] && [ -n "${FAILLOG[$i]:-}" ]; then
    while IFS= read -r l; do fit "    └ $l" "$COL"; echo "│      │          │ $FIT │"; done <<< "${FAILLOG[$i]}"
  fi
}
draw() {
  local full="${1:-}" i j icon open n_done n_all done_count=0 total=0
  for i in "${!TASKS[@]}"; do
    [ "${STATUS[$i]}" = group ] || total=$((total + 1))
    case "${STATUS[$i]}" in done|skip|off) done_count=$((done_count + 1)) ;; esac
  done
  [ -n "$full" ] || clear 2>/dev/null || true
  echo "🍎 맥 세팅 체크리스트  ($done_count/$total)"
  echo "┌──────┬──────────┬${LINE}┐"
  echo "│ 상태 │ 결과     │ $HEAD_CELL │"
  echo "├──────┼──────────┼${LINE}┤"
  for i in "${!TASKS[@]}"; do
    [ "${STATUS[$i]}" = group ] || continue
    # 묶음 요약: ❌ 실패 > ⏳ 진행 중 > ⬜·⏭️ 남음 > ✅ 끝
    icon="✅"; open="$full"; n_done=0; n_all=0
    for ((j = i + 1; j < ${#TASKS[@]}; j++)); do
      [ "${STATUS[$j]}" = group ] && break
      n_all=$((n_all + 1))
      case "${STATUS[$j]}" in
        done|skip|off) n_done=$((n_done + 1)) ;;
        fail)    icon="❌"; open=1 ;;
        running) [ "$icon" = "❌" ] || icon="⏳"; open=1 ;;
        pending) [ "$icon" = "✅" ] && icon="⬜" ;;
        blocked) [ "$icon" = "✅" ] && icon="⏭️" ;;
      esac
    done
    printf '│  %s  │ %-9s│ %s │\n' "$icon" "$n_done/$n_all" "${CELL[i]}"
    [ -n "$open" ] || continue
    for ((j = i + 1; j < ${#TASKS[@]}; j++)); do
      [ "${STATUS[$j]}" = group ] && break
      draw_task "$j"
    done
  done
  echo "└──────┴──────────┴${LINE}┘"
}

# 1) 뭐가 이미 돼 있는지 먼저 확인
need_work=0
brew_group=0
for i in "${!TASKS[@]}"; do
  case "${TASKS[$i]%%|*}" in
    group:brew) STATUS[i]=group; brew_group=1; continue ;;
    group*)     STATUS[i]=group; brew_group=0; continue ;;
  esac
  IN_BREW_GROUP[i]=$brew_group
  task="${TASKS[$i]%%|*}"
  if skipped "$task" || run_hook off "$task" >/dev/null 2>&1; then
    STATUS[i]=off
  elif is_done "${TASKS[$i]%%|*}"; then
    STATUS[i]=skip
  else
    STATUS[i]=pending
    need_work=1
  fi
done

# 2) 할 일이 없거나 --dry-run이면 아무것도 바꾸지 않고 끝
if [ "$DRY_RUN" -eq 1 ]; then
  draw full
  echo "🔍 --dry-run: 아무것도 바꾸지 않았어요. ⬜ 항목이 실행할 일이에요."
  exit 0
fi
draw
if [ "$need_work" -eq 0 ]; then
  echo "🎉 전부 이미 됨. 할 일 없음!"
  exit 0
fi
mkdir -p "$(dirname "$LOG")"
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 5000 ]; then
  tail -n 3000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi
echo "##### $(date '+%Y-%m-%d %H:%M:%S') 실행 #####" >> "$LOG"

# 3) 값을 물어볼 항목(ask_이름)이 남아 있으면 지금 물어봄
for i in "${!TASKS[@]}"; do
  [ "${STATUS[$i]}" = pending ] && run_hook ask "${TASKS[$i]%%|*}"
done

# 4) 비밀번호가 필요한 작업(Homebrew 설치, pkg형 앱 설치)이 남아 있을 때만 한 번
need_sudo=0
for i in "${!TASKS[@]}"; do
  [ "${STATUS[$i]}" = pending ] || continue
  task="${TASKS[$i]%%|*}"
  case "$task" in
    brew) need_sudo=1 ;;
    cask:*) cask_needs_sudo "${task#cask:}" && need_sudo=1 ;;
  esac
done
if [ "$need_sudo" -eq 1 ]; then
  echo "🔑 관리자 비밀번호를 한 번만 입력하면 나머지는 자동으로 진행돼요."
  sudo -v || { echo "비밀번호 확인 실패로 중단했어요."; exit 1; }
  while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
  KEEPALIVE_PID=$!
  trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT
fi

# 작업 하나 실행하고 상태 기록 (두 번째 인자가 tty면 화면에서 입력을 받음)
run_one() {
  local i=$1 task="${TASKS[$1]%%|*}" start rc=0
  if needs_brew "$i" && ! command -v brew >/dev/null; then
    STATUS[i]=blocked; return
  fi
  STATUS[i]=running
  draw
  echo "   자세한 진행 상황: tail -f $LOG"
  echo "===== $task =====" >>"$LOG"
  start=$(wc -l < "$LOG")
  if [ "${2:-}" = tty ]; then
    run_task "$task" </dev/tty > >(tee -a "$LOG") 2>&1 || rc=1   # 파이프가 아니라서 do_ 안에서 바꾼 값이 남음
  else
    run_task "$task" </dev/null >>"$LOG" 2>&1 || rc=1
  fi
  if [ "$rc" -eq 0 ]; then
    STATUS[i]="done"
  else
    STATUS[i]=fail
    FAILLOG[i]=$(tail -n +$((start + 1)) "$LOG" | tail -n 5)  # 이 항목의 로그만
  fi
}

# 5) 입력을 받는 작업(ASKS_INPUT)부터 — 오래 걸리는 설치 전에 다 물어봄
for i in "${!TASKS[@]}"; do
  [ "${STATUS[$i]}" = pending ] && asks_input "${TASKS[$i]%%|*}" && run_one "$i" tty
done

# 6) 나머지를 하나씩 실행하면서 체크
for i in "${!TASKS[@]}"; do
  [ "${STATUS[$i]}" = pending ] && run_one "$i"
done

# 7) 결과
draw
for n in "${NOTES[@]+"${NOTES[@]}"}"; do echo "$n"; done
failed=0
for s in "${STATUS[@]}"; do case "$s" in fail|blocked) failed=1 ;; esac; done
if [ "$failed" -eq 1 ]; then
  echo "⚠️  실패한 항목이 있어요. 로그 확인: tail -n 40 $LOG"
  exit 1
fi
echo "🎉 모두 완료! 새 터미널을 열면 brew를 바로 쓸 수 있어요."
