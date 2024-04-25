#include "kernel/types.h"
#include "user/user.h"
#include "user/list.h"
#include "user/threads.h"
#include "user/threads_sched.h"

#define NULL 0

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

/* MP3 Part 1 - Non-Real-Time Scheduling */
/* Weighted-Round-Robin Scheduling */
struct threads_sched_result schedule_wrr(struct threads_sched_args args)
{
    struct thread *thread = NULL;
    struct thread *th = NULL;
    list_for_each_entry(th, args.run_queue, thread_list) {
        // Choose the first thread in queue
        thread = th;
        break;
    }
    // Rotate the queue
    args.run_queue = args.run_queue->next;

    struct threads_sched_result r;
    if (thread != NULL) {
        r.scheduled_thread_list_member = &thread->thread_list;
        int time = thread->weight * args.time_quantum;
        r.allocated_time = (time > thread->remaining_time) ? thread->remaining_time : time;
    } else {
        r.scheduled_thread_list_member = args.run_queue;
        r.allocated_time = 1;
    }

    return r;
}

/* Shortest-Job-First Scheduling */
struct threads_sched_result schedule_sjf(struct threads_sched_args args)
{
    struct thread *thread = NULL;
    struct thread *th = NULL;
    list_for_each_entry(th, args.run_queue, thread_list) {
        if (thread == NULL || th->remaining_time < thread->remaining_time
            || (th->remaining_time == thread->remaining_time && th->ID < thread->ID))
            thread = th;
    }

    int time = thread->remaining_time;
    struct release_queue_entry *entry = NULL;
    list_for_each_entry(entry, args.release_queue, thread_list) {
        if (entry->release_time - args.current_time >= time)
            continue;
        int est_remain = thread->remaining_time - (entry->release_time - args.current_time);
        if (entry->thrd->processing_time < est_remain ||
            (entry->thrd->processing_time == est_remain && entry->thrd->ID < thread->ID))
            time = entry->release_time - args.current_time;
    }

    struct threads_sched_result r;
    if (thread != NULL) {
        r.scheduled_thread_list_member = &thread->thread_list;
        r.allocated_time = time;
    } else {
        r.scheduled_thread_list_member = args.run_queue;
        r.allocated_time = 1;
    }
    return r;
}

int get_slack_time(struct thread *t, int current_time) {
    return t->current_deadline - current_time - t->remaining_time;
}

/* Returns positive integer iff `a` has higher priority than `b` */
int lstcmp(struct thread *a, struct thread *b, int current_time) {
    int slack_time_a = get_slack_time(a, current_time);
    int slack_time_b = get_slack_time(b, current_time);
    if (slack_time_a < slack_time_b)
        return 1; 
    else if (slack_time_a > slack_time_b)
        return -1;
    else
        return b->ID - a->ID;
}

/* MP3 Part 2 - Real-Time Scheduling*/
/* Least-Slack-Time Scheduling */
struct threads_sched_result schedule_lst(struct threads_sched_args args)
{
    struct threads_sched_result r;
    struct thread *thread = NULL;
    struct thread *th = NULL;
    list_for_each_entry(th, args.run_queue, thread_list) {
        if (thread == NULL || lstcmp(thread, th, args.current_time) < 0)
            thread = th;
    }

    // Queue is empty
    if (thread == NULL) {
        int next_release_time = __INT32_MAX__;
        struct release_queue_entry *entry = NULL;
        list_for_each_entry(entry, args.release_queue, thread_list) {
            if (entry->release_time < next_release_time)
                next_release_time = entry->release_time;
        }
        r.scheduled_thread_list_member = args.run_queue;
        r.allocated_time = next_release_time - args.current_time;
        return r;
    }

    int slack_time = get_slack_time(thread, args.current_time);
    // printf("Slack %d\n", slack_time);
    // Schedule it until deadline
    if (slack_time <= 0) {
        r.scheduled_thread_list_member = &thread->thread_list;
        r.allocated_time = thread->current_deadline - args.current_time;
        return r;
    }

    int time = thread->remaining_time;
    struct release_queue_entry *entry = NULL;
    list_for_each_entry(entry, args.release_queue, thread_list) {
        if (entry->release_time - args.current_time >= time)
            continue;
        int entry_slack_time = get_slack_time(entry->thrd, entry->release_time);
        if (entry_slack_time < slack_time || (entry_slack_time == slack_time && entry->thrd->ID < thread->ID))
            time = entry->release_time - args.current_time;
    }

    r.scheduled_thread_list_member = &thread->thread_list;
    r.allocated_time = time;
    return r;
}

/* Deadline-Monotonic Scheduling */
struct threads_sched_result schedule_dm(struct threads_sched_args args)
{
    struct threads_sched_result r;
    // TODO: implement the deadline-monotonic scheduling algorithm
    r.scheduled_thread_list_member = args.run_queue;
    r.allocated_time = 1;

    return r;
}
