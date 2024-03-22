#include "fifo.h"

#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "proc.h"

void q_init(queue_t *q){
	panic("Not implemented yet\n");
}

int q_push(queue_t *q, uint64 e){
	panic("Not implemented yet\n");
}

uint64 q_pop_idx(queue_t *q, int idx){
	panic("Not implemented yet\n");
}

int q_empty(queue_t *q){
	panic("Not implemented yet\n");
}

int q_full(queue_t *q){
	panic("Not implemented yet\n");
}

int q_clear(queue_t *q){
	panic("Not implemented yet\n");
}

int q_find(queue_t *q, uint64 e){
	panic("Not implemented yet\n");
}
