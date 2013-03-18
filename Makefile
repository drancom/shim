ifeq ($(SCIDB),) 
  X := $(shell which scidb)
  ifneq ($(X),)
    X := $(shell dirname ${X})
    SCIDB := $(shell dirname ${X})
  endif
endif

CFLAGS=-fopenmp
INC=-I. -DPROJECT_ROOT="\"$(SCIDB)\"" -I"$(SCIDB)/include" -DSCIDB_CLIENT
LIBS=-ldl -lpthread -L"$(SCIDB)/lib" -lscidbclient -lboost_system

shim:
	$(CXX) $(INC) -fpic -g -c client.cpp -o client.o
	$(CC) -Wall $(CFLAGS) $(INC) -o shim shim.c mongoose.c client.o $(LIBS)

install: shim
	@if test ! -d "$(SCIDB)"; then echo  "Can't find scidb. Maybe try explicitly setting SCIDB variable, for example::\n\nmake SCIDB=/opt/scidb/13.2 install"; exit 1; fi 
	@if test -x /etc/init.d/shimsvc start; then /etc/init.d/shimsvc stop;fi
	cp shim "$(SCIDB)/bin"
	mkdir -p /var/lib/shim
	cp -aR wwwroot /var/lib/shim/
	chmod -R 755 /var/lib/shim
	@if test -d /usr/local/share/man/man1;then cp man/shim.1 /usr/local/share/man/man1/;fi

uninstall: unservice
	@if test ! -d "$(SCIDB)"; then echo  "Can't find scidb. Maybe try explicitly setting SCIDB variable, for example:\n\nmake SCIDB=/opt/scidb/13.2 uninstall"; exit 1; fi 
	@if test -x /etc/init.d/shimsvc start; then /etc/init.d/shimsvc stop;fi
	rm -f "$(SCIDB)/bin/shim"
	rm -rf /var/lib/shim
	rm -f /usr/local/share/man/man1/shim.1

service: install
	cp init.d/shimsvc /etc/init.d
	chmod 0755 /etc/init.d/shimsvc
	@if test -n "$$(which update-rc.d)"; then update-rc.d shimsvc defaults;fi
	@if test -n "$$(which chkconfig)"; then chkconfig --add shimsvc && chkconfig shimsvc on;fi
	/etc/init.d/shimsvc start

unservice:
	@if test -f /etc/init.d/shimsvc; then /etc/init.d/shimsvc stop; fi
	@if test -n "$$(which update-rc.d)"; then sudo update-rc.d -f shimsvc remove;fi
	@if test -n "$$(which chkconfig)"; then chkconfig --del shimsvc;fi
	rm -rf /etc/init.d/shimsvc

deb-pkg: shim
	@if test -z "$$(which fpm)"; then echo "Error: Package building requires fpm."; exit 1;fi
	@if test ! -d "$(SCIDB)"; then echo  "Can't find scidb. Maybe try explicitly setting SCIDB variable, for example::\n\nmake SCIDB=/opt/scidb/13.2 install"; exit 1; fi 
	mkdir -p pkgroot/$(SCIDB)/bin
	cp shim "pkgroot/$(SCIDB)/bin"
	mkdir -p pkgroot/etc/init.d
	cp init.d/shimsvc pkgroot/etc/init.d
	mkdir -p pkgroot/var/lib/shim
	cp -aR wwwroot pkgroot/var/lib/shim/
	chmod -R 755 pkgroot/var/lib/shim
	mkdir -p pkgroot/usr/local/share/man/man1
	@if test -d /usr/local/share/man/man1;then cp man/shim.1 pkgroot/usr/local/share/man/man1/;fi
	fpm -s dir -t deb -n shim --vendor Paradigm4 --license AGPLv3 -m "<blewis@paradigm4.com>" --url "https://github.com/Paradigm4/shim" --description "Unofficial SciDB HTTP service" --provides "shim" -v $$(basename $(SCIDB)) --after-install init.d/after-install.sh --before-remove init.d/before-remove.sh -C pkgroot opt usr var etc/init.d

rpm-pkg: shim
	@if test -z "$$(which fpm)"; then echo "Error: Package building requires fpm."; exit 1;fi
	@if test ! -d "$(SCIDB)"; then echo  "Can't find scidb. Maybe try explicitly setting SCIDB variable, for example::\n\nmake SCIDB=/opt/scidb/13.2 install"; exit 1; fi 
	mkdir -p pkgroot/$(SCIDB)/bin
	cp shim "pkgroot/$(SCIDB)/bin"
	mkdir -p pkgroot/etc/init.d
	cp init.d/shimsvc pkgroot/etc/init.d
	mkdir -p pkgroot/var/lib/shim
	cp -aR wwwroot pkgroot/var/lib/shim/
	chmod -R 755 pkgroot/var/lib/shim
	mkdir -p pkgroot/usr/local/share/man/man1
	@if test -d /usr/local/share/man/man1;then cp man/shim.1 pkgroot/usr/local/share/man/man1/;fi
	fpm -s dir -t rpm -n shim --vendor Paradigm4 --license AGPLv3 -m "<blewis@paradigm4.com>" --url "https://github.com/Paradigm4/shim" --description "Unofficial SciDB HTTP service" --provides "shim" -v $$(basename $(SCIDB)) --after-install init.d/after-install.sh --before-remove init.d/before-remove.sh -C pkgroot opt usr var etc/init.d

clean:
	rm -fr *.o *.so shim pkgroot *.rpm *.deb
