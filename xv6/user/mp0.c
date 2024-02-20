#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

#define BUF_SIZE 512

typedef struct fileCount {
    int dir_num;
    int file_num;
} FileCount;

char*
fmtname(char *path)
{
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
    ;
  p++;

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}

int count_key_occurrence(char *path, char key) {
    int n = strlen(path);
    int occurrence = 0;
    for (int i = 0; i < n; i++) {
        if (path[i] == key) occurrence++;
    }
    return occurrence;
}

void traverse(char *path, FileCount *file_count, char key) {
    char buf[BUF_SIZE], *p;
    int fd;
    struct dirent de;
    struct stat st;

    if((fd = open(path, 0)) < 0){
        fprintf(2, "%s [error opening dir]\n", path);
        close(fd);
        return;
    }

    if(fstat(fd, &st) < 0){
        fprintf(2, "mp0: cannot stat %s\n", path);
        close(fd);
        return;
    }

    printf("%s %d\n", path, count_key_occurrence(path, key));

    switch(st.type) {
        case T_FILE:
            file_count->file_num++;
            break;

        case T_DIR:
            file_count->dir_num++;
            if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
                printf("mp0: path too long\n");
                break;
            }
            strcpy(buf, path);
            p = buf + strlen(buf);
            *p++ = '/';
            
            while(read(fd, &de, sizeof(de)) == sizeof(de)){
                if (strcmp(de.name, ".") == 0 || strcmp(de.name, "..") == 0) continue;
                if(de.inum == 0) continue;

                memmove(p, de.name, DIRSIZ);
                p[DIRSIZ] = 0;
                if(stat(buf, &st) < 0){
                    printf("mp0: cannot stat %s\n", buf);
                    continue;
                }
                traverse(buf, file_count, key);
            }
            break;
    }
    close(fd);
}

void mp0(char *path, char key) {
    int fd[2];
    pipe(fd);
    int pid = fork();
    if (pid == 0) {
        // Child
        close(fd[0]); // Read end

        FileCount *file_count = (FileCount*)malloc(sizeof(FileCount));
        file_count->dir_num = 0;
        file_count->file_num = 0;

        traverse(path, file_count, key);

        if (file_count->dir_num > 0) {
            file_count->dir_num--;
        }

        // Return to parent
        write(fd[1], file_count, sizeof(FileCount));

        close(fd[1]); // Write end
    } else {
        // Parent
        close(fd[1]); // Write end

        FileCount* file_count = (FileCount*)malloc(sizeof(FileCount));
        // Read from child
        read(fd[0], file_count, sizeof(FileCount));
        printf("\n%d directories, %d files\n", file_count->dir_num, file_count->file_num);
        wait(&pid);

        close(fd[0]);
    }
}

int main(int argc, char *argv[]) {
    mp0(argv[1], argv[2][0]);
    exit(0);
}