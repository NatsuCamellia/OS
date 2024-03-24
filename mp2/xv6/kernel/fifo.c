#include "fifo.h"

#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "proc.h"

void q_init(queue_t *q){
	q->size = 0;
}

int q_push(queue_t *q, uint64 e){
	if (q_full(q) == 0) {
		q->bucket[q->size++] = e;
		return 0;
	}
	for (int i = q->size - 1; i >= 0; i--) {
		if (*(pte_t*)(q->bucket[i]) & PTE_P) /* Pinned */
			continue;
		uint64 tmp = q->bucket[i];
		q->bucket[i] = e;
		e = tmp;
	}
}

uint64 q_pop_idx(queue_t *q, int idx){
	if (idx < 0 || idx >= q->size)
		panic("q_pop_idx: idx");
	uint64 e = q->bucket[idx];
	for (int i = idx + 1; i < q->size; i++) {
		q->bucket[i - 1] = q->bucket[i];
	}
	q->size--;
	return e;
}

/* Return 1 if the queue is empty, 0 else */
int q_empty(queue_t *q){
	return q->size == 0;
}

/* Return 1 if the queue is full, 0 else */
int q_full(queue_t *q){
	return q->size == PG_BUF_SIZE;
}

int q_clear(queue_t *q){
	q->size = 0;
}

/* Find the index of e in the queue, return -1 if not found */
int q_find(queue_t *q, uint64 e){
	for (int i = 0; i < q->size; i++) {
		if (q->bucket[i] == e)
			return i;
	}
	return -1;
}
