#include "kernel/types.h"
#include "user/user.h"
#include "user/list.h"
#include "user/threads.h"
#include "user/threads_sched.h"

#define NULL 0

/* ========== Helper Functions ========== */

int min(int a, int b) {
    return a < b ? a : b;
}

int get_next_release_time(struct threads_sched_args args) {
    int next_release_time = __INT32_MAX__;
    struct release_queue_entry *entry = NULL;
    list_for_each_entry(entry, args.release_queue, thread_list) {
        if (entry->release_time < next_release_time)
            next_release_time = entry->release_time;
    }
    return next_release_time;
}

struct thread *get_best_ready_thread(struct threads_sched_args args, int (*cmp)(struct thread*, struct thread*, int)) {
    struct thread *thread = NULL;
    struct thread *th = NULL;
    list_for_each_entry(th, args.run_queue, thread_list) {
        if (thread == NULL || cmp(thread, th, args.current_time) < 0)
            thread = th;
    }
    return thread;
}

int get_allocated_time(struct thread *thread, struct threads_sched_args args, int (*cmp)(struct thread*, struct thread*, int)) {
    int time;
    if (thread->is_real_time)
        time = min(thread->remaining_time, thread->current_deadline - args.current_time);
    else
        time = thread->remaining_time;

    struct release_queue_entry *entry = NULL;
    list_for_each_entry(entry, args.release_queue, thread_list) {
        int time_elapsed = entry->release_time - args.current_time;
        if (time_elapsed >= time)
            continue;
        int tmp = thread->remaining_time;
        thread->remaining_time -= time_elapsed;
        if (cmp(thread, entry->thrd, entry->release_time) < 0)
            time = time_elapsed;
        thread->remaining_time = tmp;
    }
    return time;
}

/* default scheduling algorithm */
struct threads_sched_result schedule_default(struct threads_sched_args args)
{
    struct thread *thread_with_smallest_id = NULL;
    struct thread *th = NULL;
    list_for_each_entry(th, args.run_queue, thread_list) {
        if (thread_with_smallest_id == NULL || th->ID < thread_with_smallest_id->ID)
            thread_with_smallest_id = th;
    }

    struct threads_sched_result r;
    if (thread_with_smallest_id != NULL) {
        r.scheduled_thread_list_member = &thread_with_smallest_id->thread_list;
        r.allocated_time = thread_with_smallest_id->remaining_time;
    } else {
        r.scheduled_thread_list_member = args.run_queue;
        r.allocated_time = 1;
    }

    return r;
}

/* ========== Weighted-Round-Rabin ========== */

struct threads_sched_result schedule_wrr(struct threads_sched_args args)
{
    struct threads_sched_result r;
    struct thread *thread = NULL;
    struct thread *th = NULL;
    list_for_each_entry(th, args.run_queue, thread_list) {
        thread = th;
        break;
    }

    if (thread == NULL) {
        r.scheduled_thread_list_member = args.run_queue;
        r.allocated_time = get_next_release_time(args);
        return r;
    }

    args.run_queue = args.run_queue->next;
    r.scheduled_thread_list_member = &thread->thread_list;
    r.allocated_time = min(thread->weight * args.time_quantum, thread->remaining_time);
    return r;
}

/* ========== Shortest-Job-First ========== */

int sjfcmp(struct thread *a, struct thread *b, int dummy) {
    if (a->remaining_time < b->remaining_time)
        return 1; 
    else if (a->remaining_time > b->remaining_time)
        return -1;
    else
        return b->ID - a->ID;
}

struct threads_sched_result schedule_sjf(struct threads_sched_args args)
{
    struct threads_sched_result r;
    struct thread *thread = get_best_ready_thread(args, sjfcmp);

    if (thread == NULL) {
        r.scheduled_thread_list_member = args.run_queue;
        r.allocated_time = get_next_release_time(args);
        return r;
    }

    r.scheduled_thread_list_member = &thread->thread_list;
    r.allocated_time = get_allocated_time(thread, args, sjfcmp);
    return r;
}

/* ========== Least-Slack-Time ========== */

int get_slack_time(struct thread *t, int time) {
    return t->current_deadline - time - t->remaining_time;
}

int lstcmp(struct thread *a, struct thread *b, int time) {
    int slack_time_a = get_slack_time(a, time);
    int slack_time_b = get_slack_time(b, time);
    if (slack_time_a < slack_time_b)
        return 1; 
    else if (slack_time_a > slack_time_b)
        return -1;
    else
        return b->ID - a->ID;
}

struct threads_sched_result schedule_lst(struct threads_sched_args args)
{
    struct threads_sched_result r;
    struct thread *thread = get_best_ready_thread(args, lstcmp);

    if (thread == NULL) {
        r.scheduled_thread_list_member = args.run_queue;
        r.allocated_time = get_next_release_time(args) - args.current_time;
        return r;
    }

    if (get_slack_time(thread, args.current_time) <= 0) {
        r.scheduled_thread_list_member = &thread->thread_list;
        r.allocated_time = thread->current_deadline - args.current_time;
        return r;
    }

    r.scheduled_thread_list_member = &thread->thread_list;
    r.allocated_time = get_allocated_time(thread, args, lstcmp);
    return r;
}


/* ========== Deadline-Monotonic ========== */

int missedDeadline(struct thread *t, int time) {
    return t->current_deadline <= time;
}

int dmcmp(struct thread *a, struct thread *b, int current_time) {
    if (missedDeadline(a, current_time) && missedDeadline(b, current_time))
        return b->ID - a->ID;
    if (missedDeadline(a, current_time))
        return 1;
    if (missedDeadline(b, current_time)) 
        return -1;
    
    if (a->deadline < b->deadline)
        return 1;
    if (a->deadline > b->deadline)
        return -1;
    return b->ID - a->ID;
}

struct threads_sched_result schedule_dm(struct threads_sched_args args)
{
    struct threads_sched_result r;
    struct thread *thread = get_best_ready_thread(args, dmcmp);

    if (thread == NULL) {
        r.scheduled_thread_list_member = args.run_queue;
        r.allocated_time = get_next_release_time(args) - args.current_time;
        return r;
    }

    if (missedDeadline(thread, args.current_time)) {
        r.scheduled_thread_list_member = &thread->thread_list;
        r.allocated_time = 0;
        return r;
    }

    r.scheduled_thread_list_member = &thread->thread_list;
    r.allocated_time = get_allocated_time(thread, args, dmcmp);
    return r;
}
