# Wesnoth Chess – Formal Rule Specification

이 문서는 체스 규칙을 Wesnoth 엔진 위에서  
일관성 있게 적용하기 위한 정식 정의를 다룬다.

---

# 1. Board Definition

- 8×8 grid
- 좌표계: (x,y)
- 1 ≤ x ≤ 8
- 1 ≤ y ≤ 8
- White 방향은 y+: 아래→위
- Black 방향은 y−: 위→아래

---

# 2. 유효 이동 정의

유닛 u의 이동 집합 M(u)는 다음 조건을 만족한다:

1) 체스 이동 규칙에 부합  
2) 동일 팀 기물 위치 제외  
3) 보드 경계 내

---

# 3. 공격받는 칸

square_under_attack(x,y,side) :=  
∃ u ∈ Units(side) : (x,y) ∈ M(u)

---

# 4. 체크

is_in_check(side) :=  
let k = King(side)  
square_under_attack(k.x, k.y, enemy(side))

---

# 5. 체크메이트

is_checkmate(side) :=

1) is_in_check(side) = true  
2) ∀ m ∈ M(King(side)) → square_under_attack(m, enemy) = true  
3) ∀ a ∈ Allies(side), ∀ mv ∈ M(a):  
    simulate(mv) 이후 is_in_check(side) = true

---

# 6. 캐슬링 조건

Castle(side) 가능 iff:

1) King.has_moved = false  
2) Rook.has_moved = false  
3) King과 Rook 사이에 기물 없음  
4) King 경로 상의 모든 칸이 공격받지 않음  
5) King 현재 체크 상태 아님

---

# 7. 프로모션

u.id = Pawn ∧ u.y ∈ {1,8} → u becomes Queen(side)

