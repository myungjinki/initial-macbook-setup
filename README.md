# 🍎 Initial MacBook Setup

포맷한 맥에서 **터미널**을 열고 이 한 줄을 붙여 넣으면 끝이에요. 미리 준비할 건 없어요. 👍

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/myungjinki/initial-macbook-setup/main/mac-setup.sh)"
```

- 요구 사항: macOS 27 · Apple Silicon에서 테스트했어요(CI는 GitHub의 macos-latest). Intel 맥도 지원하지만 직접 확인하지는 않았어요.
- 먼저 무엇을 할지만 보려면 끝에 `_ --dry-run`을 붙여요. 아무것도 바꾸지 않아요.

  ```bash
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/myungjinki/initial-macbook-setup/main/mac-setup.sh)" _ --dry-run
  ```
- 입력은 맨 처음에만 해요. 그다음은 자동으로 진행돼요.
  - `git 이름`·`git 이메일`
  - 비밀번호를 물으면 **관리자 비밀번호**
  - 새 SSH 키의 **키 암호 정하기** (두 번), `Enter passphrase`가 나오면 그 **키 암호** 한 번 더 (키체인에 저장돼서 다시 안 물음)
  - 브라우저가 열리면 **GitHub 로그인**: 클립보드에 복사된 코드를 붙여 넣고 승인
- 처음 실행할 때 Homebrew가 Xcode Command Line Tools도 같이 설치해서 10분 넘게 걸릴 수 있어요.
- 끝나면 새 터미널 창을 열어요. 그래야 `brew` 명령이 잡혀요.
- 몇 번을 다시 실행해도 안전해요. 실행 전에 내용을 보고 싶으면 [mac-setup.sh](mac-setup.sh)를 열어 보세요.

실행 화면 (다 끝난 맥에서 다시 실행했을 때). 진행 중이거나 실패한 묶음만 펼쳐져요.

```
🍎 맥 세팅 체크리스트  (23/23)
┌──────┬──────────┬────────────────────────────────────────
│ 상태 │ 결과     │ 항목
├──────┼──────────┼────────────────────────────────────────
│  ✅  │ 1/1      │ 🍺 Homebrew
│  ✅  │ 1/1      │ 🐚 Oh My Zsh
│  ✅  │ 5/5      │ 🔑 SSH 키·GitHub
│  ✅  │ 3/3      │ ⚙️  맥 설정
│  ✅  │ 6/6      │ ⚙️  Homebrew가 있어야 하는 설정
│  ✅  │ 7/7      │ 📦 앱 설치
└──────┴──────────┴────────────────────────────────────────
🎉 전부 이미 됨. 할 일 없음!
```

## 1. 받은 폴더에서 실행하기 (선택)

curl 한 줄이면 충분해요. 입력을 미리 넣어 두고 싶을 때만 이 저장소를 받아서 `mac-setup.sh` 옆에 아래 파일을 두고 `bash mac-setup.sh`로 실행해요. 이 파일들은 `.gitignore`에 있어서 커밋되지 않아요.

| 옆에 둘 파일 | 만드는 법 | 없으면 |
|---|---|---|
| `config.sh` | `cp config.example.sh config.sh` 후 값 적기 (3장) | 이름·이메일은 맨 처음 물어보고, 저장소 클론은 ➖ 꺼져요. 끌 항목·더할 앱도 여기 적어요 |
| `id_ed25519`, `id_ed25519.pub` | `cp ~/.ssh/id_ed25519* .` (지금 쓰는 SSH 키) | 새 키를 만들고 GitHub에 등록해요 |
| `gh_token` | 아래 명령 | 브라우저에서 GitHub 로그인을 한 번 해요 |

`gh_token`은 **GitHub → Settings → Developer settings → Personal access tokens**에서 `repo`, `read:org`, `admin:public_key` 권한으로 만들고(만료 기간을 두는 게 안전해요), 복사한 뒤 받은 폴더에서 저장해요. 만료되면 GitHub 로그인 항목이 ❌로 나와요.

```bash
pbpaste > gh_token && chmod 600 gh_token
```

## 2. 스크립트가 해 주는 것

진행 상황을 `상태 │ 결과 │ 항목` 표로 보여줘요(⬜ 대기 → ⏳ 진행 중 → ✅ 완료/이미 됨, ❌ 실패, ➖ 꺼짐, ⏭️ brew 필요). 기본 터미널 창(80×24)에 들어가도록 묶음은 한 줄로 접혀요. 이미 된 항목은 "이미 됨"으로 건너뛰어서 **몇 번을 다시 실행해도 안전해요.**

1. Homebrew 설치
2. Oh My Zsh 설치 (brew 패키지가 없어 공식 스크립트로 설치, `~/.zshrc`가 없으면 기본 템플릿 생성)
3. SSH 키·GitHub
   - SSH 키(`~/.ssh/id_ed25519`)가 없으면 새로 만들기 (1장처럼 옆에 키가 있으면 복사, 권한 600/644)
   - `~/.ssh/config`에 `UseKeychain yes`·`AddKeysToAgent yes` 추가
   - SSH 키 암호를 키체인에 저장 (맨 처음에 한 번 입력, 재부팅해도 다시 안 물음)
   - GitHub 로그인: 브라우저로 (1장처럼 옆에 `gh_token`이 있으면 그걸로, git은 SSH 방식, Homebrew 전이라 gh를 임시로 받아 씀)
   - SSH 키를 GitHub에 등록 (이미 있으면 건너뜀)
4. 맥 설정
   - 키보드 키 반복 속도 Fast, 반복 지연 Short (로그아웃 후 적용)
   - 음량 0
   - Dock 기본 앱 전부 빼기 (Finder·휴지통은 남음)
5. Homebrew가 있어야 하는 설정
   - 내장 디스플레이 해상도를 "More Space"로 변경 (해상도 자동 판별)
   - 내장 디스플레이 밝기 최대
   - git 사용자 이름·이메일 (`git config --global`)
   - `CLONE_REPOS`의 저장소 클론 (github.com 호스트 키도 자동 등록, 비어 있으면 ➖)
   - 새 터미널에서 `brew`가 잡히도록 `~/.zprofile`에 PATH 등록
   - `git pull`할 때 rebase 대신 merge (`pull.rebase false`)
6. 앱 설치: Google Drive, Rectangle(단축키로 창 정리), Chrome, Claude 데스크톱, ChatGPT 데스크톱, Discord, GitHub CLI(gh)

- 비밀번호는 Homebrew 설치나 pkg형 앱 설치가 남아 있을 때만 물어요.
- 실패한 항목은 바로 아래에 로그 마지막 5줄이 보여요. 전체 로그는 `~/Library/Logs/mac-setup.log`에 실행마다 이어서 쌓여요.
- Homebrew가 없으면 brew가 필요한 항목(5·6번)은 ⏭️로 건너뛰어요.

## 3. 내 값 (`config.sh`)

| 값 | 의미 |
|---|---|
| `GIT_NAME`, `GIT_EMAIL` | `git config --global user.name`·`user.email`. 비워 두면 맨 처음 물어봐요 |
| `CLONE_REPOS` | `"owner/저장소\|클론할 위치"`를 한 줄씩 (gh 로그인 필요). 비워 두면 ➖ 꺼져요 |
| `DISPLAY_RES` | 'More Space' 해상도 (예: `"1800x1169"`). 비워 두면 자동 판별 |
| `SKIP_TASKS` | 끌 항목 이름 (예: `(volume_min dock_clear discord)`). fork하지 않고 취향에 안 맞는 항목을 ➖로 꺼요 |
| `EXTRA_CASKS` | 더 설치할 앱의 brew cask 이름 (예: `(slack visual-studio-code)`). 앱 설치 묶음 끝에 붙어요 |

## 4. 항목 추가하기

끄거나 앱만 더하려면 3장의 `SKIP_TASKS`·`EXTRA_CASKS`로 충분해요. 새 설정을 만들려면 이 저장소를 fork해서 `mac-setup.sh` 위쪽의 `TASKS` 목록에 한 줄씩 추가하고, 맨 위 명령의 `myungjinki`를 내 GitHub 아이디로 바꿔서 실행해요(1장처럼 받은 폴더에서 실행해도 돼요).

| 형식 | 의미 |
|---|---|
| `"cask:이름\|보일 이름"` | 앱 설치 (`brew install --cask`) |
| `"formula:이름\|보일 이름"` | 터미널 도구 설치 (`brew install`) |
| `"fn:이름\|보일 이름"` | 직접 만든 설정. `check_이름`(이미 됐는지 확인)과 `do_이름`(실제 설정) 함수가 필요해요. `off_이름`(선택)이 성공하면 ➖ 꺼짐, `ask_이름`(선택)은 맨 처음 값을 물어봐요 |
| `"group\|제목"` | 표에 보일 묶음 제목 |
| `"group:brew\|제목"` | 이 묶음의 항목은 Homebrew가 있어야 해요 (없으면 ⏭️) |

- brew가 필요한 `fn` 설정은 `group:brew` 묶음(5번) 끝에 넣어요.
- pkg형 앱(`brew info --cask 이름`에 `(Pkg)`)은 6번 맨 앞에 넣어요. 설치 후 뜨는 창을 일찍 볼 수 있어요.
- `fn` 설정이 입력을 받으면 이름을 `ASKS_INPUT`에도 적어요. 오래 걸리는 설치 전에 맨 먼저 실행돼요.
- 줄 앞에 `#`을 붙이면 그 항목은 꺼져요.
- push하면 CI가 `shellcheck`와 macOS에서 두 번 실행하기(두 번째는 전부 "이미 됨")를 확인해요. 입력을 받는 항목은 `.github/workflows/ci.yml`의 `SKIP_TASKS`에 넣어요.

## 라이선스

[MIT](LICENSE)
