#include "lru.h"

#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "proc.h"

void lru_init(lru_t *lru){
	panic("not implemented yet\n");
}

int lru_push(lru_t *lru, uint64 e){
	panic("not implemented yet\n");
}

uint64 lru_pop(lru_t *lru, int idx){
	panic("not implemented yet\n");
}

int lru_empty(lru_t *lru){
	panic("not implemented yet\n");
}

int lru_full(lru_t *lru){
	panic("not implemented yet\n");
}

int lru_clear(lru_t *lru){
	panic("not implemented yet\n");
}

int lru_find(lru_t *lru, uint64 e){
	panic("not implemented yet\n");
}
