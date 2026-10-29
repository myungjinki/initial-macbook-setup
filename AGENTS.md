# AGENTS.md — mac-setup.sh 작업 규칙

사용자는 GitHub에서 README의 curl 한 줄로 실행한다. 미리 준비한 파일 없이도 끝까지 돌아가야 한다. 항목은 사람이 아니라 AI가 추가한다.

## `TASKS` 형식

| 형식 | 의미 |
|---|---|
| `"cask:이름\|보일 이름"` | 앱 설치 (`brew install --cask`) |
| `"formula:이름\|보일 이름"` | 터미널 도구 설치 (`brew install`) |
| `"fn:이름\|보일 이름"` | 직접 만든 설정. `check_이름`·`do_이름` 필요. `off_이름`(선택)이 성공하면 ➖ 꺼짐, `ask_이름`(선택)은 맨 처음 값을 물음 |
| `"group\|제목"` | 표에 보일 묶음 제목 |
| `"group:brew\|제목"` | 이 묶음 항목은 Homebrew 필요 (없으면 ⏭️) |

## 설정·설치를 추가할 때마다

1. `TASKS`에 한 줄 추가한다. `fn`이면 `check_이름`(확인만 함: sudo·변경·팝업·입력 없음)과 `do_이름`(여러 번 실행해도 안전)을 만든다. 입력을 받는 `fn`은 `ASKS_INPUT`에 넣고, 값만 물으면 `ask_이름`으로 맨 처음 묻는다.
2. `bash -n mac-setup.sh && shellcheck -x mac-setup.sh` (경고 0개). `$변수` 바로 뒤에 한글·기호를 붙이지 않는다(`${변수}`로 쓴다, CI가 검사).
3. 저장소 폴더에서 `bash mac-setup.sh --dry-run`으로 새 항목이 ⬜로 나오는지 본다. 실제 실행은 사용자 맥을 바꾸므로(Dock·음량·앱 설치 등) 사용자가 허락할 때만 두 번 하고, 첫 번째는 `완료` 또는 `이미 됨`, 두 번째는 `이미 됨`이 나와야 한다. 새 맥 경로(`do_`)는 push 후 CI(`.github/workflows/ci.yml`)가 두 번 실행해 확인한다. 입력을 받거나 CI 맥에서 못 도는 항목은 CI의 `CI_SKIP`에 넣는다.
4. README 1장 표를 `TASKS`와 같은 순서로, 항목마다 한 줄씩 업데이트한다. 묶음·항목 수가 바뀌면 실행 화면도 다시 만든다: `TERM=dumb bash mac-setup.sh > /tmp/out.txt && swift docs/screen.swift /tmp/out.txt docs/screen.png`
5. `/evaluate`로 채점하고 계획한 뒤 그대로 리팩토링한다. 그다음 2~3을 다시 하고, 점수(전 → 후)를 보고한다.

## 규칙

- `TASKS` 순서: ① Homebrew → ② Oh My Zsh → ③ SSH 키 → ④ 맥 설정 → ⑤ brew가 필요한 설정(`group:brew`) → ⑥ brew 설치. 새 설정은 ④(brew가 필요하면 ⑤) 끝에, 새 설치는 ⑥ 끝에 넣는다. 단, pkg형 `cask`(`brew info --cask 이름`에 `(Pkg)`)는 ⑥ 맨 앞에 넣는다.
- sudo는 `brew` 설치나 pkg형 `cask`가 남아 있을 때만 받는다.
- 개인 값(이름·이메일 등)은 스크립트에 쓰지 않고 `ask_이름`으로 맨 처음 묻는다. 설정 파일은 두지 않는다. 파일(키·토큰)이 없으면 새로 만드는 쪽을 먼저 고려한다.
- 스크립트 옆 파일은 `beside 이름`으로 확인하고 `$SCRIPT_DIR` 기준으로 쓴다(curl로 실행하면 `SCRIPT_DIR`가 비어 있다). 항목은 지우지 말고 `#`으로 끈다.
- `id_ed25519`(개인키)·`gh_token`은 커밋하지 않는다(`.gitignore`). 키와 토큰은 열거나 출력하지 않는다.
- 입력(sudo 비밀번호, SSH 키 암호, 처음 묻는 값)이 필요한 실행은 사용자가 직접 터미널에서 하도록, 이유를 한 줄로 밝히고 명령을 건넨다.
