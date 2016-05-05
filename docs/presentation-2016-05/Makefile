RST2S5 = rst2s5.py

TARGETS = panda.html building.html server.html


%.html: %.rst
	$(RST2S5) $< $@

default: $(TARGETS)

%.html: $(wildcard styles/*) docutils.conf

clean:
	rm -f *.html

.PHONY: default clean
