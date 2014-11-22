PACKAGE_NAME=DMovie
PACKAGE_VERSION=0.0.1
prefix=/usr

all:

install:
	install -d -m 0755 "$(DESTDIR)/$(prefix)/bin"
	install -m 0755 DMovie "$(DESTDIR)/$(prefix)/bin"

	install -d -m 0755 "$(DESTDIR)/$(prefix)/share/$(PACKAGE_NAME)"
	cp -r src/* "$(DESTDIR)/$(prefix)/share/$(PACKAGE_NAME)"
	cp -r locale "$(DESTDIR)/$(prefix)/share/$(PACKAGE_NAME)"
	cp -r image "$(DESTDIR)/$(prefix)/share/$(PACKAGE_NAME)"
	cp -r widgets "$(DESTDIR)/$(prefix)/share/$(PACKAGE_NAME)"

uninstall:
	rm -f "$(DESTDIR)/$(prefix)/bin/DMovie"
	rm -Rf "$(DESTDIR)/$(prefix)/share/$(PACKAGE_NAME)"

.PHONY: all install uninstall
