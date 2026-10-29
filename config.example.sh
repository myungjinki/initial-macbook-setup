# 내 값 — 이 파일을 config.sh로 복사해서 고쳐요 (config.sh는 git에 안 올라감)
#   cp config.example.sh config.sh
# 비워 둔 값의 항목은 체크리스트에서 ➖ 꺼짐으로 보여요

# git config --global user.name / user.email
GIT_NAME=""
GIT_EMAIL=""

# gh로 클론할 저장소: "owner/저장소|클론할 위치" (gh 로그인 필요)
CLONE_REPOS=(
  # "octocat/hello-world|$HOME/Downloads/hello-world"
)

# 내장 디스플레이 'More Space' 해상도 (예: "1800x1169"). 비워 두면 자동 판별
DISPLAY_RES=""
