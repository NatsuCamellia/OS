#include "lru.h"

#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "proc.h"

void lru_init(lru_t *lru){
	lru->size = 0;
}

int lru_push(lru_t *lru, uint64 e){
	int idx = lru_find(lru, e);
	if (idx != -1)
		lru_pop(lru, idx);
	if (!lru_full(lru)) {
		lru->bucket[lru->size++] = e;
		return 0;
	}
	/* Find first unpinned victim */
	for (int i = 0; i < lru->size - 1; i++) {
		if (!(*(pte_t*)(lru->bucket[i]) & PTE_P)) {
			/* Not pinned */
			lru_pop(lru, i);
			break;
		}
	}
	if (!lru_full(lru))
		lru->bucket[lru->size++] = e;
}

uint64 lru_pop(lru_t *lru, int idx){
	if (idx < 0 || idx >= lru->size)
		panic("lru_pop: idx\n");
	uint64 e = lru->bucket[idx];
	for (int i = idx + 1; i < lru->size; i++)
		lru->bucket[i - 1] = lru->bucket[i];
	lru->size--;
	return e;
}

int lru_empty(lru_t *lru){
	return lru->size == 0;
}

int lru_full(lru_t *lru){
	return lru->size == PG_BUF_SIZE;
}

int lru_clear(lru_t *lru){
	lru->size = 0;
}

int lru_find(lru_t *lru, uint64 e){
	for (int i = 0; i < lru->size; i++)
		if (lru->bucket[i] == e)
			return i;
	return -1;
}
