#include <io.h>
#include <syscall.h>
#include <errno.h>

ssize_t write(int fd, const void *buf, size_t count)
{
  ssize_t rc = __syscall3(SYS_write, fd, (long)buf, count);
  if (rc < 0) {
    errn = -rc;
    rc = -1;
  }
  return rc;
}
