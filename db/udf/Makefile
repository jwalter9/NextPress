LIBDIR=/usr/lib/mysql/plugin
all:
	gcc -Wall -fPIC -I/usr/include/mysql -I. -shared lib_mysqludf_nextpress.c -lesmtp -o ./lib_mysqludf_nextpress.so 

install:
	cp lib_mysqludf_nextpress.so $(LIBDIR)
