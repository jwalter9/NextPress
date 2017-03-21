/* 
    lib_mysqludf_nextpress - the UDF library for NextPress
    Copyright (C) 2015 Lowadobe Web Services, LLC 
    web: http://nextpress.org/
    email: lowadobe@gmail.com
*/

#ifdef STANDARD
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

typedef unsigned long long ulonglong;
typedef long long longlong;

#else
#include <my_global.h>
#include <my_sys.h>
#endif

#include <mysql.h>
#include <m_ctype.h>
#include <m_string.h>
#include <stdlib.h>
#include <ctype.h>

#include <libesmtp.h>

#ifdef HAVE_DLOPEN

#define LIBVERSION "lib_mysqludf_nextpress version 0.1"

#define SETENV(name,value)        setenv(name,value,1);        


/*===================== image processing ====================*/


my_bool convert_img_init(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *message
){
    if(args->arg_count != 3
        || args->arg_type[0] != STRING_RESULT
        || args->arg_type[1] != STRING_RESULT
        || args->arg_type[2] != STRING_RESULT){
        strcpy(message,    
        "Expected source file, dest file, resize directive"
        );        
        return 1;
    };
    FILE *f;
    f = fopen( args->args[0], "rb" );
    if( f == NULL ){
        sprintf(message, "%s not readable", args->args[0]);
        return 1;
    };
    fclose( f );
    return 0;
}

void convert_img_deinit(
    UDF_INIT *initid
){
}

my_ulonglong convert_img(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *is_null
,    char *error
){
    my_ulonglong retVal;
    char *src = calloc(args->lengths[0] + 1, sizeof(char));
    if(!src) return 127;
    char *dst = calloc(args->lengths[1] + 1, sizeof(char));
    if(!dst) return 127;
    char *res = calloc(args->lengths[2] + 1, sizeof(char));
    if(!res) return 127;
    strncpy(src, args->args[0], args->lengths[0]);
    strncpy(dst, args->args[1], args->lengths[1]);
    strncpy(res, args->args[2], args->lengths[2]);
    char *cmd = malloc(34+args->lengths[0]+args->lengths[2]+args->lengths[1]*2);
    sprintf(cmd,"/usr/bin/convert %s %s %s && chmod 644 %s",src,res,dst,dst);
    retVal = system(cmd);
    free(src);
    free(dst);
    free(res);
    free(cmd);
    return retVal;
}

/*============================ emailer ============================*/


my_bool emailer_init(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *message
){
    if(args->arg_count == 4
    && args->arg_type[0]==STRING_RESULT
    && args->arg_type[1]==STRING_RESULT
    && args->arg_type[2]==STRING_RESULT
    && args->arg_type[3]==STRING_RESULT){
        return 0;
    } else {
        strcpy(message,"Expect 4 params: to, content, server, from");        
        return 1;
    };
}

void emailer_deinit(
    UDF_INIT *initid
){
}

my_ulonglong emailer(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *is_null
,    char *error
){
    long err = 0;
    char *rcp = calloc(args->lengths[0] + 1, sizeof(char));
    if(!rcp) return 127;
    char *msg = calloc(args->lengths[1] + 1, sizeof(char));
    if(!msg) return 127;
    char *srv = calloc(args->lengths[2] + 1, sizeof(char));
    if(!srv) return 127;
    char *frm = calloc(args->lengths[3] + 1, sizeof(char));
    if(!frm) return 127;
    strncpy(rcp, args->args[0], args->lengths[0]);
    strncpy(msg, args->args[1], args->lengths[1]);
    strncpy(srv, args->args[2], args->lengths[2]);
    strncpy(frm, args->args[3], args->lengths[3]);
    smtp_session_t session;
    smtp_message_t message;
    session = smtp_create_session();
    message = smtp_add_message(session);
    smtp_add_recipient(message, rcp);
    struct sigaction sa;
    sa.sa_handler = SIG_IGN;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGPIPE, &sa, NULL); 
    smtp_set_server(session, srv);
    smtp_set_reverse_path(message, frm);
    smtp_set_message_str(message, msg);
    if (!smtp_start_session(session)) err = smtp_errno();
    smtp_destroy_session(session);
    free(rcp);
    free(msg);
    free(srv);
    free(frm);
    return err;
}


my_bool is_email_init(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *message
){
    if(args->arg_count == 1
    && args->arg_type[0]==STRING_RESULT){
        return 0;
    } else {
        strcpy(message,"Expected 1 parameter: email address to check");        
        return 1;
    };
}

void is_email_deinit(
    UDF_INIT *initid
){
}

my_ulonglong is_email(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *is_null
,    char *error
){
    char *pos = args->args[0];
    char *end;
    size_t len;
    if(pos[0] == '\0' || pos[0] == '.' || pos[0] == '@') return 1;
    end = strchr(pos, '@');
    if(end == NULL) return 2;
    end++;
    if(end[0] == '\0' || end[0] == '.') return 3;
    pos = strstr(end, "..");
    if(pos != NULL) return 4;
    pos = strchr(end, '.');
    if(pos == NULL) return 5;
    len = strcspn(end, " @\t\n\r");
    if(len != strlen(end)) return 6;
    if(end[0] == '.') return 7;
    pos = end + strlen(end) - 1;
    if(pos[0] == '.') return 8;
    return 0;
}


/*============================ file_write ============================*/



my_bool file_write_init(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *message
){
    if(args->arg_count == 2
    && args->arg_type[0]==STRING_RESULT
    && args->arg_type[1]==STRING_RESULT){
        return 0;
    } else {
        strcpy(
            message,"Expected 2 parameters: filepath, content"
        );        
        return 1;
    }
}
void file_write_deinit(
    UDF_INIT *initid
){
}
my_ulonglong file_write(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *is_null
,    char *error
){
    char *cmd = malloc(11+args->lengths[0]);
    if(!cmd) return 127;
    FILE *f = fopen(args->args[0], "w");
    if(!f){
        strcpy(error,"Cannot open file for write");
        return 1;
    };
    long unsigned int writ = 
        fwrite(args->args[1], sizeof(char), args->lengths[1], f);
    int c = fclose(f);
    if(writ < args->lengths[1]){
        sprintf(error, "Wrote %lu of %lu bytes", writ, args->lengths[1]);
        return 2;
    };
    sprintf(cmd, "chmod 644 %s", args->args[0]);
    c = system(cmd);
    return c;
}


/*============================ file_copy ============================*/



my_bool file_copy_init(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *message
){
    if(args->arg_count == 2
    && args->arg_type[0]==STRING_RESULT
    && args->arg_type[1]==STRING_RESULT){
        return 0;
    } else {
        strcpy(
            message,"Expected 2 parameters: source file, destination"
        );        
        return 1;
    }
}
void file_copy_deinit(
    UDF_INIT *initid
){
}
my_ulonglong file_copy(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *is_null
,    char *error
){
    my_ulonglong retVal;
    char *src = calloc(args->lengths[0] + 1, sizeof(char));
    if(!src) return 127;
    char *dst = calloc(args->lengths[1] + 1, sizeof(char));
    if(!dst) return 127;
    char *cmd = malloc(20+args->lengths[0]+args->lengths[1]*2);
    if(!cmd) return 127;
    strncpy(src, args->args[0], args->lengths[0]);
    strncpy(dst, args->args[1], args->lengths[1]);
    sprintf(cmd, "cp %s %s && chmod 644 %s", src, dst, dst);
    retVal = system(cmd);
    free(src);
    free(dst);
    free(cmd);
    return retVal;
}


/*============================ file_delete ============================*/



my_bool file_delete_init(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *message
){
    if(args->arg_count == 1
    && args->arg_type[0]==STRING_RESULT){
        return 0;
    } else {
        strcpy(
            message,"Expected 1 parameter: file to delete"
        );        
        return 1;
    }
}
void file_delete_deinit(
    UDF_INIT *initid
){
}

my_ulonglong file_delete(
    UDF_INIT *initid
,    UDF_ARGS *args
,    char *is_null
,    char *error
){
    my_ulonglong retVal;
    char *del = calloc(args->lengths[0] + 1, sizeof(char));
    if(!del) return 127;
    char *cmd = malloc(4 + args->lengths[0]);
    if(!cmd) return 127;
    strncpy(del, args->args[0], args->lengths[0]);
    sprintf(cmd, "rm %s", del);
    retVal = system(cmd);
    free(del);
    free(cmd);
    return retVal;
}



/*============================ reload_apache ============================*/


my_bool reload_apache_init(
    UDF_INIT *initid
    ,    UDF_ARGS *args
    ,    char *message
){
    if(args->arg_count == 0){
        return 0;
    } else {
        strcpy(message, "Expected no parameters");        
        return 1;
    };
}
    
void reload_apache_deinit(
    UDF_INIT *initid
){
}
        
my_ulonglong reload_apache(
    UDF_INIT *initid
    ,    UDF_ARGS *args
    ,    char *is_null
    ,    char *error
){
    return system("sudo /etc/nextpress/reload_apache.sh");
}


#endif /* HAVE_DLOPEN */

