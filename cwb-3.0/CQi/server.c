/* 
 *  IMS Open Corpus Workbench (CWB)
 *  Copyright (C) 1993-2006 by IMS, University of Stuttgart
 *  Copyright (C) 2007-     by the respective contributers (see file AUTHORS)
 * 
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2, or (at your option) any later
 *  version.
 * 
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 *  Public License for more details (in the file "COPYING", or available via
 *  WWW at http://www.gnu.org/copyleft/gpl.html).
 */


#include "server.h"
#include "auth.h"
#include "cqi.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <signal.h>
#include <strings.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>

#include "../cl/cl.h"           /* this is the local cl.h header */
#include "../cl/macros.h"

#include "../cqp/options.h"
#include "../cqp/corpmanag.h"
#include "../cqp/parse_actions.h"
#include "../cqp/hash.h"

#define NETBUFSIZE 512
#define ATTHASHSIZE 16384
#define GENERAL_ERROR_SIZE 1024

#ifndef MSG_WAITALL
/* Linux doesn't define the MSG_WAITALL flag, but under normal conditions 
   it _does_ wait for the entire amount of data requested to arrive; so we
   just set MSG_WAITALL to 0 (nothing) in this case */
#define MSG_WAITALL 0
#endif


int sockfd, connfd;
FILE *conn_out;                 /* buffered output (don't forget to flush()) */
struct sockaddr_in my_addr, client_addr;
struct hostent *remote_host;
char *remote_address;
cqi_byte netbuf[NETBUFSIZE];    /* do we need it at all? */
int bytes;                      /* always used for data held in netbuf[] */


int cqi_errno = CQI_STATUS_OK;  /* CQi last error */
char cqi_error_string[GENERAL_ERROR_SIZE] = "No error.";

/*
 *
 *  Error messages
 *
 */

void 
cqi_send_error(char *function) {
  fprintf(stderr, "ERROR CQi data send failure in function\n");
  fprintf(stderr, "ERROR %s() <server.c>\n", function);
  exit(1);
}

void 
cqi_recv_error(char *function) {
  fprintf(stderr, "ERROR CQi data recv failure in function\n");
  fprintf(stderr, "ERROR %s() <server.c>\n", function);
  exit(1);
}

void
cqi_internal_error(char *function, char *cause) {
  fprintf(stderr, "ERROR Internal error in function\n");
  fprintf(stderr, "ERROR %s() <server.c>\n", function);
  fprintf(stderr, "ERROR ''%s''\n", cause);
  exit(1);
}


/*
 *
 *  General error reporting
 *
 */
void cqi_general_error(char *errstring) {
  if (strlen(errstring) >= GENERAL_ERROR_SIZE) 
    cqi_internal_error("cqi_general_error", "Error message too long.");
  strcpy(cqi_error_string, errstring);
  cqi_command(CQI_ERROR_GENERAL_ERROR);
}


/*
 *
 *  Init TCP/IP connection
 *
 */

int 
accept_connection(int port) {
  const int on = 1;
  socklen_t sin_size = sizeof(struct sockaddr_in);
  pid_t child_pid;

  if (SIG_ERR == signal(SIGCHLD, SIG_IGN)) {
    perror("ERROR Can't ignore SIGCHLD");
    exit(1);
  }

  if (port <= 0) {
    port = CQI_PORT;
  }

  if (server_debug) 
    fprintf(stderr, "CQi: Opening socket and binding to port %d\n", port);
  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0) {
    perror("ERROR Can't create socket");
    return -1;
  }
  if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, (const void *)&on, sizeof(int)) < 0)
    perror("WARNING Can't set address reuse option"); /* can be ignored... */

  my_addr.sin_family = AF_INET;
  my_addr.sin_port = htons(port);
  if (localhost) 
    my_addr.sin_addr.s_addr = inet_addr("127.0.0.1"); /* loopback device */
  else 
    my_addr.sin_addr.s_addr = htonl(INADDR_ANY);      /* all network devices on local machine */
  bzero(&(my_addr.sin_zero), 8);
  if (0 != bind(sockfd, (struct sockaddr *)&my_addr, sizeof(struct sockaddr))) {
    perror("ERROR Can't bind socket to port");
    return -1;
  }

  if (server_log)
    printf("Waiting for client on port #%d.\n", port);
  if (0 != listen(sockfd, 5)) {
    perror("ERROR listen() failed");
    return -1;
  }

  /* if called with '-q', fork() and quit before waiting for connections */
  if (server_quit) {
    pid_t pid = fork();
    if (pid != 0) {
      close(sockfd);            /* parent returns to caller */
      printf("[CQPserver running in background now]\n");
      exit(0);
    }
  }

  while (42) {
    /* when run as a private server, we'll only wait for up to 10 seconds */
    if (private_server) {
      struct timeval tv;
      fd_set read_fd;
      
      tv.tv_sec = 10;
      tv.tv_usec = 0;
      FD_ZERO(&read_fd);        /* select() on sockfd */
      FD_SET(sockfd, &read_fd);
      
      if ((select(sockfd+1, &read_fd, NULL, NULL, &tv) <= 0)
          || (!FD_ISSET(sockfd, &read_fd))) {
        printf("Port #%d timed out in private server mode. Aborting.\n", port);
        exit(1);
      }
    }

    connfd = accept(sockfd, (struct sockaddr *)&client_addr, &sin_size);
    if (connfd < 0) {
      perror("ERROR Can't establish connection");
      return -1;
    }
    
    if (server_debug) 
      fprintf(stderr, "CQi: Connection established. Looking up client's name.\n");
    remote_address = inet_ntoa(client_addr.sin_addr);
    remote_host = gethostbyaddr((void *)&(client_addr.sin_addr), 4, AF_INET);
    if (server_log) {
      printf("Connection established with %s ", remote_address);
      if (remote_host != NULL) 
        printf("(%s)", remote_host->h_name);
      printf("\n");
    }
    
    /* spawn a server to handle the request */
    child_pid = fork();
    if (child_pid < 0) {
      perror("ERROR can't fork() server");
      return -1;
    }
    
    if (child_pid == 0)
      break;                    /* the child exits the listen() loop */

    /* this is the listening 'parent', which exits immediately */
    printf("Spawned CQPserver, pid = %d.\n", (int)child_pid);
    close(connfd);              /* this is the child's connection */

    if (private_server) {
      printf("Accepting no more connections (private server).\n");
      close(sockfd);
      exit(0);                  /* SIGCHLD should be reaped by calling process */
    }
  }

  /* this is the child serving the new CQi connection */
  if (server_debug) 
    fprintf(stderr, "CQi: ** new CQPserver created, initiating CQi session\n");
  close(sockfd);

  /* check if remote host is in validation list */
  if (!check_host(client_addr.sin_addr)) {
    printf("WARNING %s not in list, connection refused!\n", remote_address);
    printf("Exit. (pid = %d)\n", (int)getpid());
    close(connfd);
    exit(1);
  }

  conn_out = fdopen(connfd, "w");
  if (conn_out == NULL) {
    perror("ERROR Can't switch CQi connection to buffered output");
    close(connfd);
    return -1;
  }
  if (server_debug) 
    fprintf(stderr, "CQi: creating attribute hash (size = %d)\n", ATTHASHSIZE);
  make_attribute_hash(ATTHASHSIZE);

  return connfd;
}



/* 
 *
 *  Server -> Client communication
 *
 */

/* communication primitives (no auto-flush; use cqi_flush()) */

int 
cqi_flush(void) {
  if (snoop) {
    fprintf(stderr, "CQi FLUSH\n");
  }
  if (EOF == fflush(conn_out)) {
    perror("ERROR cqi_flush()");
    return 0;
  }
  else {
    return 1;
  }
}

/* BYTE ... send byte */
int 
cqi_send_byte(int n) {
  if (snoop) {
    fprintf(stderr, "CQi SEND BYTE   %02X        [= %d]\n", n, n);
  }
  if (
      (EOF == putc(0xff & n, conn_out))
      )
    {
      perror("ERROR cqi_send_byte()");
      return 0;
    }
  else {
    return 1;
  }
}

/* WORD ... 2 byte, network order; can be used to send commands */
int 
cqi_send_word(int n) {
  if (snoop) {
    fprintf(stderr, "CQi SEND WORD   %04X      [= %d]\n", n, n);
  }
  if (
      (EOF == putc(0xff & (n >> 8), conn_out)) ||
      (EOF == putc(0xff & n, conn_out))
      )
    {
      perror("ERROR cqi_send_word()");
      return 0;
    }
  else {
    return 1;
  }
}

/* INT ... 4 byte, network order */
int 
cqi_send_int(int n) {
  if (snoop) {
    fprintf(stderr, "CQi SEND INT    %08X  [= %d]\n", n, n);
  }
  if (
      (EOF == putc(0xff & (n >> 24), conn_out)) ||
      (EOF == putc(0xff & (n >> 16), conn_out)) ||
      (EOF == putc(0xff & (n >> 8), conn_out)) ||
      (EOF == putc(0xff & n, conn_out))
      )
    {
      perror("ERROR cqi_send_int()");
      return 0;
    }
  else {
    return 1;
  }
}

/* STRING ... send CQi string (NOT null-terminated) */ 
int 
cqi_send_string(char *str) {
  int len;

  if (str == NULL) {
    if (! cqi_send_word(0)) {
      perror("ERROR cqi_send_string()");
      return 0;
    }
    else {
      return 1;
    }
  }

  len = strlen(str);
  if (! cqi_send_word(len)) {
     perror("ERROR cqi_send_string()");
     return 0;
  }
  if (snoop) {
    fprintf(stderr, "CQi SEND CHAR[] '%s'\n", str);
  }
  if (len != fprintf(conn_out, "%s", str)) {
    perror("ERROR cqi_send_string()");
    return 0;
  }    
  else {
    return 1;
  }
}

/* BYTE[] ... byte list */
int 
cqi_send_byte_list(cqi_byte *list, int l) {
  if (!cqi_send_int(l)) {
    perror("ERROR cqi_send_byte_list()");
    return 0;
  }
  while (--l >= 0) {
    if (!cqi_send_byte(*list++)) {
      perror("ERROR cqi_send_byte_list()");
      return 0;
    }
  }
  return 1;
}

/* INT[] ... integer list */
int 
cqi_send_int_list(int *list, int l) {
  if (!cqi_send_int(l)) {
    perror("ERROR cqi_send_int_list()");
    return 0;
  }
  while (--l >= 0) {
    if (!cqi_send_int(*list++)) {
      perror("ERROR cqi_send_int_list()");
      return 0;
    }
  }
  return 1;
}

/* STRING[] ... string list */
int 
cqi_send_string_list(char **list, int l) {
  if (!cqi_send_int(l)) {
    perror("ERROR cqi_send_string_list()");
    return 0;
  }
  while (--l >= 0) {
    if (!cqi_send_string(*list++)) {
      perror("ERROR cqi_send_string_list()");
      return 0;
    }
  }
  return 1;
}


/* send a CQi command */

/* general command without arguments */
void 
cqi_command(int command) {
  if (!cqi_send_word(command) || !cqi_flush()) {
    cqi_send_error("cqi_command");
  }
}

void 
cqi_data_byte(int n) {
  if (!cqi_send_word(CQI_DATA_BYTE) || !cqi_send_byte(n) || !cqi_flush()) {
    cqi_send_error("cqi_data_byte");
  }
}

void 
cqi_data_bool(int n) {
  if (!cqi_send_word(CQI_DATA_BOOL) || !cqi_send_byte(n) || !cqi_flush()) {
    cqi_send_error("cqi_data_bool");
  }
}

void 
cqi_data_int(int n) {
  if (!cqi_send_word(CQI_DATA_INT) || !cqi_send_int(n) || !cqi_flush()) {
    cqi_send_error("cqi_data_int");
  }
}

void 
cqi_data_string(char *str) {
  if (!cqi_send_word(CQI_DATA_STRING) || !cqi_send_string(str) || !cqi_flush()) {
    cqi_send_error("cqi_data_string");
  }
}

void 
cqi_data_byte_list(cqi_byte *list, int l) {
  if (!cqi_send_word(CQI_DATA_BYTE_LIST) || !cqi_send_byte_list(list, l) || !cqi_flush()) {
    cqi_send_error("cqi_data_byte_list");
  }
}

void 
cqi_data_bool_list(cqi_byte *list, int l) {
  if (!cqi_send_word(CQI_DATA_BOOL_LIST) || !cqi_send_byte_list(list, l) || !cqi_flush()) {
    cqi_send_error("cqi_data_bool_list");
  }
}

void 
cqi_data_int_list(int *list, int l) {
  if (!cqi_send_word(CQI_DATA_INT_LIST) || !cqi_send_int_list(list, l) || !cqi_flush()) {
    cqi_send_error("cqi_data_int_list");
  }
}

void 
cqi_data_string_list(char **list, int l) {
  if (!cqi_send_word(CQI_DATA_STRING_LIST) || !cqi_send_string_list(list, l) || !cqi_flush()) {
    cqi_send_error("cqi_data_string_list");
  }
}

void 
cqi_data_int_int(int n1, int n2) {
  if (
      !cqi_send_word(CQI_DATA_INT_INT) ||
      !cqi_send_int(n1) ||
      !cqi_send_int(n2) ||
      !cqi_flush()
      )
    {
      cqi_send_error("cqi_data_int_int");
    }
}

void 
cqi_data_int_int_int_int(int n1, int n2, int n3, int n4) {
  if (
      !cqi_send_word(CQI_DATA_INT_INT_INT_INT) ||
      !cqi_send_int(n1) ||
      !cqi_send_int(n2) ||
      !cqi_send_int(n3) ||
      !cqi_send_int(n4) ||
      !cqi_flush()
      )
    {
      cqi_send_error("cqi_data_int_int_int_int");
    }
}


/*
 *
 *  Client -> Server communication
 *
 */

int 
cqi_recv_bytes(cqi_byte *buf, int bytes) {
  if (bytes <= 0) {
    return 1;
  }
  else {
    if (snoop) {
      fprintf(stderr, "CQi RECV BYTE[%d]\n", bytes);
    }
    if (bytes != recv(connfd, buf, bytes, MSG_WAITALL)) {
      perror("ERROR cqi_recv_bytes()");
      return 0;
    }
    return 1;
  }
}

int 
cqi_recv_byte(void) {
  cqi_byte b;
  if (1 != recv(connfd, &b, 1, MSG_WAITALL)) {
    perror("ERROR cqi_recv_byte()");
    return EOF;
  }
  if (snoop) {
    fprintf(stderr, "CQi RECV BYTE 0x%02X\n", b);
  }
  return b;
}

int 
cqi_read_byte(void) {
  int b = cqi_recv_byte();
  if (b == EOF) {
    cqi_recv_error("cqi_read_byte");
  }
  return b;
}

int 
cqi_read_bool(void) {
  int b = cqi_recv_byte();
  if (b == EOF) {
    cqi_recv_error("cqi_read_bool");
  }
  return b;
}

int 
cqi_read_word(void) {
  int n = cqi_read_byte();
  n = (n << 8) | cqi_read_byte();
  if (snoop) {
    fprintf(stderr, "CQi READ WORD   %04X      [= %d]\n", n, n);
  }
  return n;
}

int 
cqi_read_int(void) {
  int n = cqi_read_byte();
  int minus_bits = ((int)-1) ^ 0xFFFFFFFF; /* extra minus bits if int is > 32 bit*/

  n = (n << 8) | cqi_read_byte();
  n = (n << 8) | cqi_read_byte();
  n = (n << 8) | cqi_read_byte();
  if (n & 0x80000000)           /* negative 32bit quantity */
    n |= minus_bits;            /* expand to full size of int type */
  if (snoop) {
    fprintf(stderr, "CQi READ INT    %08X  [= %d]\n", n, n);
  }
  return n;
}

char *
cqi_read_string(void) {
  int len;
  char *s;

  len = cqi_read_word();
  s = (char *) cl_malloc(len + 1);
  if (!cqi_recv_bytes((cqi_byte *)s, len))
    cqi_recv_error("cqi_read_string");
  s[len] = '\0';
  if (snoop)
    fprintf(stderr, "CQi READ CHAR[] '%s'\n", s);
  return s;
}  

int
cqi_read_command(void) {
  int command;

  if (server_debug)
    fprintf(stderr, "CQi: waiting for command\n");
  command = cqi_read_byte();
  while (command == CQI_PAD) 
    command = cqi_read_byte();
  command = (command << 8) | cqi_read_byte();
  return command;
}

int
cqi_read_byte_list(cqi_byte **list) {
  int i, len;

  len = cqi_read_int();
  if (len <= 0) {
    *list = NULL;
    return 0;
  } 
  else {
    *list = (cqi_byte *) cl_malloc(len);
    for (i=0; i<len; i++)
      (*list)[i] = cqi_read_byte();
    if (snoop)
      fprintf(stderr, "CQi READ BYTE[%d]\n", len);
    return len;
  }
}

int
cqi_read_bool_list(cqi_byte **list) {
  int i, len;

  len = cqi_read_int();
  if (len <= 0) {
    *list = NULL;
    return 0;
  } 
  else {
    *list = (cqi_byte *) cl_malloc(len);
    for (i=0; i<len; i++)
      (*list)[i] = cqi_read_byte();
    if (snoop)
      fprintf(stderr, "CQi READ BOOL[%d]\n", len);
    return len;
  }
}

int
cqi_read_int_list(int **list) {
  int i, len;

  len = cqi_read_int();
  if (len <= 0) {
    *list = NULL;
    return 0;
  }
  else {
    *list = (int *) cl_malloc(len * sizeof(int));
    for (i=0; i<len; i++)
      (*list)[i] = cqi_read_int();
    if (snoop)
      fprintf(stderr, "CQi READ INT[%d]\n", len);
    return len;
  }
}

int
cqi_read_string_list(char ***list) {
  int i, len;
  
  len = cqi_read_int();
  if (len <= 0) {
    *list = NULL;
    return 0;
  }
  else {
    *list = (char **) cl_malloc(len * sizeof(char *));
    for (i=0; i<len; i++)
      (*list)[i] = cqi_read_string();
    if (snoop)
      fprintf(stderr, "CQi READ STRING[%d]\n", len);
    return len;
  }
}








/*
 *
 *  Naming conventions & specifier split
 *
 */

char cqi_id_uc_first[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_";
char cqi_id_uc[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_-0123456789";
char cqi_id_lc_first[] = "abcdefghijklmnopqrstuvwxyz_";
char cqi_id_lc[] = "abcdefghijklmnopqrstuvwxyz_-0123456789";
char cqi_id_all[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_-0123456789";

int 
check_corpus_name(char *name) {
  if (
      (strchr(cqi_id_uc_first, *name) == NULL) ||
      (strspn(name+1, cqi_id_uc) != strlen(name+1))
      )
    {
      cqi_errno = CQI_ERROR_SYNTAX_ERROR;
      return 0;
    }
  else {
    cqi_errno = CQI_STATUS_OK;
    return 1;
  }
}
       
int 
check_attribute_name(char *name) {
  if (
      (strchr(cqi_id_lc_first, *name) == NULL) ||
      (strspn(name+1, cqi_id_lc) != strlen(name+1))
      )
    {
      cqi_errno = CQI_ERROR_SYNTAX_ERROR;
      return 0;
    }
  else {
    cqi_errno = CQI_STATUS_OK;
    return 1;
  }
}
       
int 
check_subcorpus_name(char *name) {
  if (
      (strchr(cqi_id_uc_first, *name) == NULL) ||
      (strspn(name+1, cqi_id_all) != strlen(name+1))
      )
    {
      cqi_errno = CQI_ERROR_SYNTAX_ERROR;
      return 0;
    }
  else {
    cqi_errno = CQI_STATUS_OK;
    return 1;
  }
}

/* To avoid messing with function arguments when splitting specifiers,
   I need the following strdupto() function, which creates a duplicate
   of <str> just as if there were a \0 at <end> */
char *strdupto(char *str, char *end) {
  int len = end - str;
  char *ret, *p;

  ret = (char *) cl_malloc(len+1);
  for (p = ret; len > 0; len--) 
    *p++ = *str++;
  *p = '\0';
  return ret;
}

/* new strings are allocated for the output arguments */
int 
split_attribute_spec(char *spec, char **corpus, char **attribute) {
  char *split = strchr(spec, '.');
 
  if (split == NULL) {
    cqi_errno = CQI_ERROR_SYNTAX_ERROR;
    return 0;
  }
  *corpus = strdupto(spec, split);
  *attribute = cl_strdup(split+1);
  if (!check_corpus_name(*corpus) || !check_attribute_name(*attribute)) {
    free(*corpus);
    free(*attribute);
    return 0;                   /* cqi_errno set by check_* function */
  }
  cqi_errno = CQI_STATUS_OK;
  return 1;
}

int 
split_subcorpus_spec(char *spec, char **corpus, char **subcorpus) {
  char *split = strchr(spec, ':');

  if (split == NULL) {
    *corpus = cl_strdup(spec);
    *subcorpus = NULL;
  }
  else {
    *corpus = strdupto(spec, split);
    *subcorpus = cl_strdup(split+1);
  }
  if (
      !check_corpus_name(*corpus) || 
      (*subcorpus != NULL && !check_subcorpus_name(*subcorpus))
      ) 
    {
      cl_free(*corpus);
      cl_free(*subcorpus);
      return 0;                 /* cqi_errno set by check_* function */
    }
  cqi_errno = CQI_STATUS_OK;
  return 1;
}

char *
combine_subcorpus_spec(char *corpus, char *subcorpus) {
  char *spec;

  if (subcorpus == NULL) {
    spec = cl_strdup(corpus);
  }
  else {
    spec = (char *) cl_malloc(strlen(corpus) + strlen(subcorpus) + 2);
    sprintf(spec, "%s:%s", corpus, subcorpus);
  }
  return spec;
}

/*
 *
 *  Hash Utilities (lookup of attributes)
 *
 */

typedef struct att_bucket {
  char *string; /* the key */
  Attribute *attribute;
  int type;                     /* ATT_NONE, ATT_POS, ATT_STRUC, ... */
} AttBucket;

struct att_hashtable {
  AttBucket *space;
  int    code;
  int    size;
};

typedef struct att_hashtable *AttHashTable;

AttHashTable AttHash = NULL;    /* this is the global attribute hash */

/* has to be called once to initialise the hash */
void 
make_attribute_hash(int size)
{
  int bytes;
  AttHash = (AttHashTable) cl_malloc(sizeof(struct att_hashtable));
  
  AttHash->size = find_prime(size);
  bytes = sizeof(AttBucket) * AttHash->size;

  AttHash->space = (AttBucket *)cl_malloc(bytes);

  memset(AttHash->space, 0, bytes);
  AttHash->code = 0;
}

void 
free_attribute_hash(void)
{
  if (AttHash != NULL) {
    if (AttHash->space != NULL) 
      free(AttHash->space);
    free(AttHash);
    AttHash = NULL;
  }
}

AttBucket *
att_hash_lookup(char *str)
{
  AttBucket *p, *end;
  int i = 0;
  int offset;

  if (AttHash == NULL) 
    cqi_internal_error("att_hash_lookup", "AttHash not initialised.");

  /* points to the end of the space */
  end = AttHash->space + AttHash->size;
  /* the hash value of the string */
  offset = hash_string(str) % AttHash->size;
  /* the primary pointer into the space */
  p = AttHash->space + offset;

  for(i = (int)AttHash->size/5; i>0; p++,i--) {
    if(p >= end) p = AttHash->space;
    if(p->string == NULL) {     /* init new bucket */
      p->string = cl_strdup(str);
      p->attribute = NULL;
      p->type = ATT_NONE;
      break;
    }
    else if(strcmp(p->string, str) == 0)
      break;
  }

  if (i == 0) 
    cqi_internal_error("att_hash_lookup", "Too many collisions.");

  return p;
}

Attribute *
cqi_lookup_attribute(char *name, int type) {
  AttBucket *p = att_hash_lookup(name);
  if (p->attribute == NULL) {
    /* try to open the attribute */
    char *corpus_name, *attribute_name;
    CorpusList *cl;
    Attribute *attribute;

    if (server_debug) {
      fprintf(stderr, "CQi: AttHash: attribute '%s' not found, trying to open ...\n", name);
    }

    if (!split_attribute_spec(name, &corpus_name, &attribute_name))
      return NULL;
    cl = findcorpus(corpus_name, SYSTEM, 0);
    if (cl == NULL || !access_corpus(cl)) {
      cqi_errno = CQI_CQP_ERROR_NO_SUCH_CORPUS;
      return NULL;
    }
    attribute = cl_new_attribute(cl->corpus, attribute_name, type);
    if (attribute == NULL) {
      cqi_errno = CQI_CL_ERROR_NO_SUCH_ATTRIBUTE;
      return NULL;
    }
    p->attribute = attribute;
    p->type = type;
    cqi_errno = CQI_STATUS_OK;
    return p->attribute;
  }
  else if (p->type != type) {
    if (server_debug) {
      fprintf(stderr, "CQi: AttHash: attribute '%s' found, wrong attribute type.\n", name);
    }
    cqi_errno = CQI_CL_ERROR_WRONG_ATTRIBUTE_TYPE;
    return NULL;
  }
  else {
    if (server_debug) {
      fprintf(stderr, "CQi: AttHash: attribute '%s' found in hash.\n", name);
    }
    cqi_errno = CQI_STATUS_OK;
    return p->attribute;
  }
}

int
cqi_drop_attribute(char *name) {
  AttBucket *p = att_hash_lookup(name);

  if ((p->attribute != NULL) && 
      (cl_delete_attribute(p->attribute))) {
    p->attribute = NULL;
    p->type = ATT_NONE;
    return 1;
  }
  else {
    return 0;
  }
}
      


/*
 *
 *  CQP internal function wrappers
 *
 */

CorpusList *
cqi_find_corpus(char *name) {
  CorpusList *cl;
  char *corpus, *subcorpus;

  if (check_corpus_name(name)) {
    cl = findcorpus(name, SYSTEM, 0);
  }
  else {
    if (split_subcorpus_spec(name, &corpus, &subcorpus)) {
      free(corpus);
      free(subcorpus);
      cl = findcorpus(name, SUB, 0);
    }
    else {
      cl = NULL;                        /* cqi_errno set by split_subcorpus_spec */
    }
  }

  if (cl == NULL || !access_corpus(cl)) {
    cqi_errno = CQI_CQP_ERROR_NO_SUCH_CORPUS;
    return NULL;
  }
  cqi_errno = CQI_STATUS_OK;
  return cl;
}
    
int 
cqi_activate_corpus(char *name) {
  CorpusList *cl;

  if (server_debug) 
    fprintf(stderr, "CQi: cqi_activate_corpus('%s');\n", name);
  cl = cqi_find_corpus(name);
  if (cl == NULL) 
    return 0;
  else {
    set_current_corpus(cl, 0);
    return 1;
  }
}
