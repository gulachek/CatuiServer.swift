#include "unixsocket.h"

#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/un.h>
#include <unistd.h>

int unix_socket() { return socket(PF_LOCAL, SOCK_STREAM, 0); }

int unix_socketpair(int socket_vector[2]) {
  return socketpair(PF_LOCAL, SOCK_STREAM, 0, socket_vector);
}

int unix_bind(int sock, const char *path) {
  struct sockaddr_un addr;
  memset(&addr, 0, sizeof(struct sockaddr_un));
  addr.sun_family = AF_UNIX;
  addr.sun_len = strlen(path);
  strncpy(addr.sun_path, path, addr.sun_len);

  return bind(sock, (struct sockaddr *)&addr, sizeof(struct sockaddr_un));
}

int unix_listen(int sock, int backlog) { return listen(sock, backlog); }

int unix_accept(int sock) {
  struct sockaddr_un addr;
  socklen_t len = sizeof(struct sockaddr_un);
  return accept(sock, (struct sockaddr *)&addr, &len);
}

int unix_connect(int sock, const char *path) {
  struct sockaddr_un addr;
  memset(&addr, 0, sizeof(struct sockaddr_un));
  addr.sun_family = AF_UNIX;
  addr.sun_len = strlen(path);
  strncpy(addr.sun_path, path, addr.sun_len);

  return connect(sock, (struct sockaddr *)&addr, sizeof(struct sockaddr_un));
}

int unix_send_fd(int sock, int fd_to_send) {
  struct msghdr msg = {0};
  char buf[CMSG_SPACE(sizeof(int))];
  struct iovec io = {.iov_base = ".", .iov_len = 1};

  msg.msg_iov = &io;
  msg.msg_iovlen = 1;

  msg.msg_control = buf;
  msg.msg_controllen = sizeof(buf);

  struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_RIGHTS;
  cmsg->cmsg_len = CMSG_LEN(sizeof(int));
  *((int *)CMSG_DATA(cmsg)) = fd_to_send;
  msg.msg_controllen = cmsg->cmsg_len;

  return sendmsg(sock, &msg, 0);
}

/* fd if successful, -1 if not */
int unix_recv_fd(int sock) {
  struct msghdr msg = {0};

  char m_buf[256];
  struct iovec io = {.iov_base = m_buf, .iov_len = sizeof(m_buf)};
  msg.msg_iov = &io;
  msg.msg_iovlen = 1;

  char c_buf[256];
  msg.msg_control = c_buf;
  msg.msg_controllen = sizeof(c_buf);

  ssize_t nread = recvmsg(sock, &msg, 0);
  if (nread == -1) {
    perror("recvmsg");
    return -1;
  }

  struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);

  if (cmsg->cmsg_type != SCM_RIGHTS) {
    fprintf(stderr, "recvmsg had cmsg_type %d instead of SCM_RIGHTS\n",
            cmsg->cmsg_type);
    return -1;
  }

  if (cmsg->cmsg_level != SOL_SOCKET) {
    fprintf(stderr, "recvmsg had cmsg_level %d instead of SOL_SOCKET\n",
            cmsg->cmsg_level);
    return -1;
  }

  if (cmsg->cmsg_len != CMSG_LEN(sizeof(int))) {
    fprintf(stderr,
            "recvmsg had cmsg_len %u instead of CMSG_LEN(sizeof(int)) "
            "(%lu)\n",
            cmsg->cmsg_len, CMSG_LEN(sizeof(int)));
    return -1;
  }

  return *((int *)CMSG_DATA(cmsg));
}
