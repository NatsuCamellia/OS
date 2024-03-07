#include "user/threads.h"

#include "kernel/types.h"
#include "user/setjmp.h"
#include "user/user.h"
#define NULL 0

static struct thread *current_thread = NULL;
static int id = 1;
static jmp_buf env_st;
// static jmp_buf env_tmp;

struct task *task_create(struct thread *thread, void (*f)(void *), void *arg) {
    struct task *t = (struct task *)malloc(sizeof(struct task));
    t->fp = f;
    t->arg = arg;
    return t;
}

struct thread *thread_create(void (*f)(void *), void *arg) {
    struct thread *t = (struct thread *)malloc(sizeof(struct thread));
    unsigned long new_stack_p;
    unsigned long new_stack;
    new_stack = (unsigned long)malloc(sizeof(unsigned long) * 0x100);
    new_stack_p = new_stack + 0x100 * 8 - 0x2 * 8;
    t->fp = f;
    t->arg = arg;
    t->ID = id;
    t->buf_set = 0;
    t->stack = (void *)new_stack;
    t->stack_p = (void *)new_stack_p;
    thread_assign_task(t, f, arg);
    id++;
    return t;
}
void thread_add_runqueue(struct thread *t) {
    if (current_thread == NULL) {
        // TODO
        current_thread = t;
        current_thread->next = current_thread;
        current_thread->previous = current_thread;
    } else {
        // TODO
        struct thread *head_thread = current_thread;
        struct thread *tail_thread = current_thread->previous;
        t->next = head_thread;
        t->previous = tail_thread;
        head_thread->previous = t;
        tail_thread->next = t;
    }
}
void thread_yield(void) {
    // TODO
    struct task *task = current_thread->current_task;
    // Save context
    if (setjmp(current_thread->env) == 0) {
        schedule();
        longjmp(env_st, 1);
    }

    // Check for new coming task
    while (task != current_thread->tasks) {
        top_task_run();
        current_thread->current_task = task;
    }
}
void dispatch(void) {
    // TODO
    // Init
    if (!current_thread->buf_set) {
        current_thread->env->sp = (unsigned long)(current_thread->stack_p);
        current_thread->env->ra = (unsigned long)(&thread_run);
        current_thread->buf_set = 1;
    }
    longjmp(current_thread->env, 1);
}
void schedule(void) {
    // TODO
    current_thread = current_thread->next;
}
void thread_exit(void) {
    if (current_thread->next != current_thread) {
        // TODO
        struct thread *next_thread = current_thread->next;
        struct thread *prev_thread = current_thread->previous;
        prev_thread->next = next_thread;
        next_thread->previous = prev_thread;

        free(current_thread->stack);
        free(current_thread);

        current_thread = next_thread;
    } else {
        // TODO
        // Hint: No more thread to execute
        free(current_thread->stack);
        free(current_thread);
        current_thread = NULL;
    }
    longjmp(env_st, 1);
}
void thread_start_threading(void) {
    // TODO
    setjmp(env_st);
    if (current_thread) {
        dispatch();
    }
}

// part 2
void thread_assign_task(struct thread *t, void (*f)(void *), void *arg) {
    // TODO
    struct task *task = task_create(t, f, arg);
    task->next = t->tasks;
    t->tasks = task;
}

void thread_run() {
    while (current_thread->tasks) {
        top_task_run();
    }
    thread_exit();
}

void top_task_run() {
    // Run the top task
    struct task *top_task = current_thread->tasks;
    current_thread->current_task = top_task;
    top_task->fp(top_task->arg);
    // After running, remove the task.
    // Current task must be the top one.
    if (top_task != current_thread->tasks) {
        printf("Assertion Failed\n");
        exit(-1);
    }
    current_thread->tasks = top_task->next;
    free(top_task);
}