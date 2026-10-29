# 🍎 포맷 후 맥 세팅

포맷·초기 설정·와이파이·iCloud 로그인까지 했다면, 남은 건 스크립트 실행 하나예요. 👍

## 1. 실행하기

1. **시스템 설정 → Apple 계정 → iCloud → iCloud Drive**에서 **"데스크탑 및 문서 폴더"**를 켜요.
2. Finder에 `문서/initial-setup-macbook`이 보일 때까지 기다려요. 이 폴더에 `id_ed25519`, `id_ed25519.pub`, `gh_token`이 있어야 해요.
3. 터미널에서 실행해요.

```bash
bash ~/Documents/initial-setup-macbook/mac-setup.sh
```

- "터미널이 문서 폴더에 접근하려고 합니다"라는 창이 뜨면 **허용**을 눌러요.
- 입력은 맨 처음에만 해요. 이후는 자동으로 진행돼요.
  - 비밀번호를 물으면 **관리자 비밀번호**
  - `Enter passphrase`가 나오면 **SSH 키 암호** (키체인에 저장돼서 다시 안 물음)
- 처음 실행할 때 Homebrew가 Xcode Command Line Tools도 같이 설치해서 10분 넘게 걸릴 수 있어요.
- 끝나면 새 터미널 창을 열어요. 그래야 `brew` 명령이 잡혀요.

## 2. 스크립트가 해 주는 것

체크리스트(⬜ → ⏳ → ✅/❌)로 진행 상황을 보여줘요. 이미 된 항목은 "이미 됨"으로 건너뛰어서 **몇 번을 다시 실행해도 안전해요.**

1. Homebrew 설치
2. Oh My Zsh 설치 (brew 패키지가 없어 공식 스크립트로 설치, `~/.zshrc`가 없으면 기본 템플릿 생성)
3. SSH 키
   - 이 폴더의 SSH 키(`id_ed25519`, `id_ed25519.pub`)를 `~/.ssh`로 복사 (권한 600/644)
   - `~/.ssh/config`에 `UseKeychain yes`·`AddKeysToAgent yes` 추가
   - SSH 키 암호를 키체인에 저장 (맨 처음에 한 번 입력, 재부팅해도 다시 안 물음)
4. 맥 설정
   - 키보드 키 반복 속도 Fast, 반복 지연 Short (로그아웃 후 적용)
   - 음량 0
   - Dock 기본 앱 전부 빼기 (Finder·휴지통은 남음)
5. Homebrew가 있어야 하는 설정
   - 내장 디스플레이 해상도를 "More Space"로 변경 (해상도 자동 판별)
   - 내장 디스플레이 밝기 최대
   - git 사용자 이름·이메일 (`git config --global`, 값은 스크립트 위쪽 `GIT_NAME`·`GIT_EMAIL`)
   - GitHub CLI(gh) 설치 후 이 폴더의 `gh_token`으로 로그인 (git은 SSH 방식, 파일 권한 600으로 변경)
   - `repo` 저장소를 `~/Downloads/repo`에 클론 (github.com 호스트 키도 자동 등록, 저장소·위치는 스크립트 위쪽 `VAULT_REPO`·`VAULT_DIR`)
   - 새 터미널에서 `brew`가 잡히도록 `~/.zprofile`에 PATH 등록
   - `git pull`할 때 rebase 대신 merge (`pull.rebase false`)
6. 앱 설치: Google Drive, Rectangle(단축키로 창 정리), Chrome, Claude 데스크톱, ChatGPT 데스크톱, Discord

- 비밀번호는 Homebrew 설치나 pkg형 앱 설치가 남아 있을 때만 물어요.
- 실패한 항목은 바로 아래에 로그 마지막 5줄이 보여요. 전체 로그는 `~/mac-setup.log`에 있어요.
- Homebrew가 없으면 brew가 필요한 항목(5·6번)은 ⏭️로 건너뛰어요.

## 3. 항목 추가하기

원본 `~/Downloads/initial-setup-macbook/mac-setup.sh` 위쪽의 `TASKS` 목록에 한 줄씩 추가하고, `cp ~/Downloads/initial-setup-macbook/{mac-setup.sh,README.md} ~/Documents/initial-setup-macbook/`로 복사해요. Documents의 복사본을 고치면 다음 복사 때 덮어써져요.

| 형식 | 의미 |
|---|---|
| `"cask:이름\|보일 이름"` | 앱 설치 (`brew install --cask`) |
| `"formula:이름\|보일 이름"` | 터미널 도구 설치 (`brew install`) |
| `"fn:이름\|보일 이름"` | 직접 만든 설정. `check_이름`(이미 됐는지 확인)과 `do_이름`(실제 설정) 함수가 필요해요 |
| `"group\|제목"` | 체크리스트에 보일 묶음 제목 |
| `"group:brew\|제목"` | 이 묶음의 항목은 Homebrew가 있어야 해요 (없으면 ⏭️) |

- brew가 필요한 `fn` 설정은 `group:brew` 묶음(5번) 끝에 넣어요.
- pkg형 앱(`brew info --cask 이름`에 `(Pkg)`)은 6번 맨 앞에 넣어요. 설치 후 뜨는 창을 일찍 볼 수 있어요.
- `fn` 설정이 입력을 받으면 이름을 `ASKS_INPUT`에도 적어요. 오래 걸리는 설치 전에 맨 먼저 실행돼요.
- 줄 앞에 `#`을 붙이면 그 항목은 꺼져요.

## 4. GitHub 토큰 만들기

`gh_token`이 없거나 만료되면 gh 로그인 항목이 ❌로 나와요. **GitHub → Settings → Developer settings → Personal access tokens**에서 `repo`, `read:org`, `admin:public_key` 권한으로 토큰을 만들고 이 폴더에 저장해요(만료 기간을 두는 게 안전해요).

```bash
pbpaste > ~/Documents/initial-setup-macbook/gh_token && chmod 600 ~/Documents/initial-setup-macbook/gh_token
```
