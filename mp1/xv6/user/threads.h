#ifndef THREADS_H_
#define THREADS_H_
#define NULL_FUNC ((void (*)(int)) - 1)
// TODO: necessary includes, if any
#include "user/setjmp.h"
// TODO: necessary defines, if any

struct task {
    void (*fp)(void *arg);
    void *arg;
    struct task *next;  // Tasks are arranged in stack-like way
};

struct thread {
    void (*fp)(void *arg);
    void *arg;
    void *stack;
    void *stack_p;
    jmp_buf env;  // for thread function
    int buf_set;  // 1: indicate jmp_buf (env) has been set, 0: indicate jmp_buf
                  // (env) not set
    int ID;
    struct thread *previous;
    struct thread *next;
    // Modifying the above is prohibited.
    struct task *tasks;
    struct task *current_task;
};

struct task *task_create(struct thread *thread, void (*f)(void *), void *arg);

/**
 * This function creates a new thread and allocates the space in stack to the
 * thread. The function returns the initialized structure.
 */
struct thread *thread_create(void (*f)(void *), void *arg);

/**
 * This function adds an initialized struct thread to the runqueue.
 */
void thread_add_runqueue(struct thread *t);

/**
 * This function suspends the current thread by saving its context to the jmp
 * buf in struct thread using setjmp.
 */
void thread_yield(void);

/**
 * This function executes a thread which decided by schedule().
 */
void dispatch(void);

/**
 * This function will decide which thread to run next.
 */
void schedule(void);

/**
 * This function removes the calling thread from the runqueue, frees its stack
 * and the struct thread, updates current thread with the next to-be-executed
 * thread in the runqueue and calls dispatch().
 */
void thread_exit(void);

/**
 * This function will be called by the main function after some thread is added
 * to the runqueue. It should return only if all threads have exited.
 */
void thread_start_threading(void);

// part 2
/**
 * This function assigns a task to the thread t. The second argument, f, is a
 * pointer to the task function, while the third argument, arg, represents the
 * argument of f.
 */
void thread_assign_task(struct thread *t, void (*f)(void *), void *arg);

/**
 * Start current thread. Then the thread will execute tasks in
 * last-come-first-serve order
 */
void thread_run();

/**
 * Run the task on top of the stack of the current thread.
 */
void top_task_run();
#endif  // THREADS_H_
