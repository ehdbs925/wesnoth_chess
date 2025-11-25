# Wesnoth Chess – Architecture Overview

본 문서는 Wesnoth 기반 체스 엔진 Add-on의 전체 구조를 기술한다.  
프로젝트는 엔진(core), 시나리오(scenario), 데이터(data), 유닛(units), 맵(maps), 테스트(tests)로 구성된다.

---

# 1. 전체 시스템 구조

addons/wesnoth-chess/
├─ core/ # 체스 엔진 모듈
│ ├─ logic.lua
│ ├─ board.lua
│ ├─ rules.lua
│ ├─ ai.lua
│ ├─ eval.lua
│ ├─ search.lua
│ ├─ utils.lua
│ └─ state.lua
├─ scenario/
│ ├─ campaign.cfg
│ ├─ round1.cfg
│ ├─ round2.cfg
│ ├─ round3.cfg
│ └─ ending.cfg
├─ units/
├─ maps/
├─ data/
├─ tests/
└─ docs/

---

# 2. 엔진 모듈 구조

## 2.1 logic.lua  
메인 루프. 시나리오에서 턴마다 호출되며:
- 보드 동기화
- 체크/체크메이트 평가
- AI 실행
- 상태(State) 업데이트

## 2.2 board.lua  
게임 보드의 내부 자료구조를 유지.  
8×8 배열로 유닛 정보를 저장하며, AI/Rules가 이를 기반으로 분석한다.

## 2.3 rules.lua  
체스 규칙 구현:
- 체크 체크메이트
- 캐슬링 조건
- 프로모션 조건
- 공격 가능 여부 판단

## 2.4 ai.lua  
AI 메인. search.lua를 호출하여 최적 수 선택.

## 2.5 search.lua  
1~2 ply Minimax-lite 탐색:
- 모든 이동 생성
- simulate_move()로 결과 평가
- eval.lua 점수 최대화

## 2.6 eval.lua  
유닛 가치 기반의 평가 함수:
- Pawn/Minor/Major piece 평가
- 체크/킹 안전도 점수 포함 가능

## 2.7 state.lua  
라운드 진행 상태, 승리 플래그 등을 저장.

---

# 3. 데이터 흐름(Flow)

(1) scenario → logic.on_turn(side)  
(2) logic → board.update()  
(3) logic → rules.is_checkmate()  
(4) logic → ai.play_turn()  
(5) ai → search.best_move()  
(6) search → eval.evaluate()  
(7) AI 이동 → 보드 상태 변경 → 반복

---

# 4. 확장 가능성

- Minimax depth 3~4
- Monte Carlo Tree Search
- 프로모션 UI 메뉴 추가
- 체크 시 알림 메시지

