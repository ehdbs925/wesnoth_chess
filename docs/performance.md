# Wesnoth Chess – Performance Analysis

본 문서는 AI 탐색 성능, 평균 연산량, 시나리오 턴당 처리 시간 등을 분석한다.

---

# 1. Branching Factor 분석

각 기물의 평균 이동 수:

| Piece   | Avg Moves |
|---------|-----------|
| Pawn    | 2         |
| Knight  | 8         |
| Bishop  | 13        |
| Rook    | 14        |
| Queen   | 27        |
| King    | 8         |

전체 평균 branching factor b ≈ 12

---

# 2. 탐색 깊이에 따른 연산량

1-ply : O(b) = O(12)  
2-ply : O(b²) = O(144)  

3-ply(실험적): O(1728)

---

# 3. 실제 성능 측정

Wesnoth 내 Lua profiling 결과

| Mode   | 평균 시간 |
|--------|----------|
| 1-ply  | 0.025초   |
| 2-ply  | 0.15초    |

8×8 고정 맵이므로 연산량이 제한적이고  
턴 시간은 유저 경험을 해치지 않는 수준이다.

---

# 4. 최적화 요소

- 비반응적 이동 pruning  
- 체크 상태 우선 검색  
- 자잘한 이동 제거  
- 중심 제어 우선순위 강화  

---

# 5. 실제 플레이 테스트

라운드3(2-ply) 기준 20턴 게임에서  
AI 응답 속도는 평균 0.12초였으며  
턴 지연 현상은 관찰되지 않았다.

