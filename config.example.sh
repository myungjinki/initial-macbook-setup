# shellcheck shell=bash disable=SC2034  # mac-setup.sh가 읽는 변수
# 내 값 — 이 파일을 config.sh로 복사해서 고쳐요 (config.sh는 git에 안 올라감)
#   cp config.example.sh config.sh
# 비워 두면: 이름·이메일은 맨 처음 물어보고, 저장소 클론은 ➖ 꺼짐

# git config --global user.name / user.email
GIT_NAME=""
GIT_EMAIL=""

# gh로 클론할 저장소: "owner/저장소|클론할 위치" (gh 로그인 필요)
CLONE_REPOS=(
  # "octocat/hello-world|$HOME/Developer/hello-world"
)

# 내장 디스플레이 'More Space' 해상도 (예: "1800x1169"). 비워 두면 자동 판별
DISPLAY_RES=""

# 끌 항목: mac-setup.sh TASKS의 이름 (fn:·cask:·formula: 뒤 부분). 끈 항목은 ➖
SKIP_TASKS=(
  # volume_min dock_clear discord
)

# 더 설치할 앱: brew cask 이름 (앱 설치 묶음 끝에 붙음)
EXTRA_CASKS=(
  # slack visual-studio-code
)
