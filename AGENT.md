# AGENT.md — mac-setup.sh 작업 규칙

사용자는 GitHub에서 README의 curl 한 줄로 실행한다. 미리 준비한 파일 없이도 끝까지 돌아가야 한다.

## 설정·설치를 추가할 때마다

1. `TASKS`에 한 줄 추가한다(형식은 README 3장). `fn`이면 `check_이름`(확인만 함: sudo·변경·팝업·입력 없음)과 `do_이름`(여러 번 실행해도 안전)을 만든다. 입력을 받는 `fn`은 `ASKS_INPUT`에 넣고, 값만 물으면 `ask_이름`으로 맨 처음 묻는다.
2. `bash -n mac-setup.sh && shellcheck -x mac-setup.sh` (경고 0개)
3. 저장소 폴더에서 `bash mac-setup.sh`를 두 번 실행한다. 첫 번째는 `완료` 또는 `이미 됨`, 두 번째는 `이미 됨`이 나와야 한다. 새 맥 경로(`do_`)는 push 후 CI(`.github/workflows/ci.yml`)가 확인한다. 입력을 받거나 CI 맥에서 못 도는 항목은 CI의 `CI_SKIP`에 넣는다.
4. README 2장 목록을 `TASKS`와 같은 순서로 업데이트한다.
5. `/evaluate`로 채점하고 계획한 뒤 그대로 리팩토링한다. 그다음 2~3을 다시 하고, 점수(전 → 후)를 보고한다.

## 규칙

- `TASKS` 순서: ① Homebrew → ② Oh My Zsh → ③ SSH 키 → ④ 맥 설정 → ⑤ brew가 필요한 설정(`group:brew`) → ⑥ brew 설치. 새 설정은 ④(brew가 필요하면 ⑤) 끝에, 새 설치는 ⑥ 끝에 넣는다. 단, pkg형 `cask`(`brew info --cask 이름`에 `(Pkg)`)는 ⑥ 맨 앞에 넣는다.
- sudo는 `brew` 설치나 pkg형 `cask`가 남아 있을 때만 받는다.
- 개인 값(이름·이메일 등)은 스크립트에 쓰지 않고 `ask_이름`으로 맨 처음 묻는다. 설정 파일은 두지 않는다. 파일(키·토큰)이 없으면 새로 만드는 쪽을 먼저 고려한다.
- 스크립트 옆 파일은 `beside 이름`으로 확인하고 `$SCRIPT_DIR` 기준으로 쓴다(curl로 실행하면 `SCRIPT_DIR`가 비어 있다). 항목은 지우지 말고 `#`으로 끈다.
- `id_ed25519`(개인키)·`gh_token`은 커밋하지 않는다(`.gitignore`). 키와 토큰은 열거나 출력하지 않는다.
- 실행은 내가 맥에서 직접 한다(Remote Control). 입력(sudo 비밀번호, SSH 키 암호, 처음 묻는 값)이 필요하면 터미널 탭에서 실행하고, 사용자에게 이유를 한 줄로 밝혀 입력을 요청한다.
