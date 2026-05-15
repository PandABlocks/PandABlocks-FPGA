UTILS = \
	arfile.py \
	opkg-build \
	opkg-buildpackage \
	opkg-compare-indexes \
	opkg-diff \
	opkg-extract-file \
	opkg-feed \
	opkg-list-fields \
	opkg-make-index \
	opkg-show-deps \
	opkg-unbuild \
	opkg.py \
	update-alternatives

MANPAGES = opkg-build.1

DESTDIR =
PREFIX ?= /usr/local
bindir ?= $(PREFIX)/bin
mandir ?= $(PREFIX)/man

.SUFFIXES: .1

%.1: %
	pod2man -r "" -c "opkg-utils Documentation" $< $@

all: $(UTILS) $(MANPAGES)

install-utils: $(UTILS)
	install -d $(DESTDIR)$(bindir)
	install -m 755 $(UTILS) $(DESTDIR)$(bindir)

install-docs: $(MANPAGES)
	install -d $(DESTDIR)$(mandir)
	for m in $(MANPAGES); \
	do \
		install -d $(DESTDIR)$(mandir)/man$${m##*.}; \
		install -m 644 "$$m" $(DESTDIR)$(mandir)/man$${m##*.}; \
	done

install: install-utils install-docs

.PHONY: install install-utils install-docs all
