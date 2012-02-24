PREFIX?=	/usr/local
LDLIBS=		-lz
CFLAGS+=	-Wsystem-headers -Wno-format-y2k -W -Werror \
		-Wno-unused-parameter -Wstrict-prototypes \
		-Wmissing-prototypes -Wpointer-arith -Wreturn-type \
		-Wcast-qual -Wwrite-strings -Wswitch -Wshadow -Wcast-align \
		-Wunused-parameter -Wchar-subscripts -Winline \
		-Wnested-externs -Wunused
CFLAGS+=	-g -O -pipe
OBJ=		vmdktool.o expand_number.o

all:	vmdktool vmdktool.8.gz

vmdktool:	${OBJ}
	${CC} ${CFLAGS} -o $@ ${OBJ} ${LDLIBS}

vmdktool.8.gz: vmdktool.8
	groff -Tascii -mtty-char -man -t vmdktool.8 | gzip -9c >$@

${OBJ}:		expand_number.h

clean:
	rm -f vmdktool vmdktool.o expand_number.o vmdktool.8.gz
	rm -fr t/data

test:
	prove -vmw t/*.t

install:
	install -s vmdktool ${DESTDIR}${PREFIX}/bin/
	install vmdktool.8 ${DESTDIR}${PREFIX}/man/man8/
