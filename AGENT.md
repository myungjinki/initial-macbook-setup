# AGENT.md — mac-setup.sh 작업 규칙

원본: `~/Downloads/initial-setup-macbook`(git, GitHub 저장소). 배포본: `~/Documents/initial-setup-macbook`(iCloud, `mac-setup.sh`·`README.md`·`config.sh`·키·토큰).
고치는 건 원본만 하고, 실행은 배포본으로 한다.

## 설정·설치를 추가할 때마다

1. `TASKS`에 한 줄 추가한다(형식은 README 4장). `fn`이면 `check_이름`(확인만 함: sudo·변경·팝업·입력 없음)과 `do_이름`(여러 번 실행해도 안전)을 만든다. 입력을 받는 `fn`은 `ASKS_INPUT`에 넣는다.
2. `bash -n mac-setup.sh`
3. `cp ~/Downloads/initial-setup-macbook/{mac-setup.sh,README.md,config.example.sh} ~/Documents/initial-setup-macbook/`로 복사하고 `bash ~/Documents/initial-setup-macbook/mac-setup.sh`를 두 번 실행한다. 첫 번째는 `완료` 또는 `이미 됨`, 두 번째는 `이미 됨`이 나와야 한다.
4. README 2장 목록을 `TASKS`와 같은 순서로 업데이트한다.
5. `/evaluate`로 채점하고 계획한 뒤 그대로 리팩토링한다. 그다음 2~3을 다시 하고, 점수(전 → 후)를 보고한다.

## 규칙

- `TASKS` 순서: ① Homebrew → ② Oh My Zsh → ③ SSH 키 → ④ 맥 설정 → ⑤ brew가 필요한 설정(`group:brew`) → ⑥ brew 설치. 새 설정은 ④(brew가 필요하면 ⑤) 끝에, 새 설치는 ⑥ 끝에 넣는다. 단, pkg형 `cask`(`brew info --cask 이름`에 `(Pkg)`)는 ⑥ 맨 앞에 넣는다.
- sudo는 `brew` 설치나 pkg형 `cask`가 남아 있을 때만 받는다.
- 개인 값(이름·이메일·저장소 등)은 스크립트에 쓰지 않고 `config.sh` 변수로 받는다. 새 변수는 `mac-setup.sh` 기본값(빈 값)·`config.example.sh`·README 3장에 함께 넣고, 비어 있으면 `off_이름`으로 끈다.
- 경로는 `$SCRIPT_DIR` 기준으로 쓴다. 항목은 지우지 말고 `#`으로 끈다.
- `id_ed25519`(개인키)·`gh_token`·`config.sh`는 배포본에만 둔다(원본에 두지 않는다). 키와 토큰은 열거나 출력하지 않는다.
- 실행은 내가 맥에서 직접 한다(Remote Control). 입력(sudo 비밀번호, SSH 키 암호)이 필요하면 터미널 탭에서 실행하고, 사용자에게 이유를 한 줄로 밝혀 입력을 요청한다.
