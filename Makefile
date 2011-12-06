package := oosanalysis
version := 0.2.1
zipfile := $(package)_$(version).tar.gz

SHELL = /bin/bash
RD := /home/gcalhoun/Desktop/R-devel/build/bin/R
RR := /home/gcalhoun/Desktop/R-devel/R-2-14-branch/bin/R
latexmk  := /usr/local/texlive/2011/bin/x86_64-linux/latexmk
LATEXMKFLAGS := -pdf -silent
noweave := /usr/bin/noweave
notangle:= /usr/bin/notangle

Rfiles := $(patsubst $(package)/man/%.Rd,$(package)/R/%.R,$(filter-out $(package)/man/nobs-methods.Rd,$(wildcard $(package)/man/*.Rd)))

.PHONY: all build pdf

all: check install pdf 
pdf: $(package)/inst/doc/implementation.pdf
build: $(zipfile) pdf
$(zipfile): check 
	cd $(package)/inst/doc && $(latexmk) -c implementation.tex
	$(RR) CMD build $(package)

install: check
	sudo $(RD) CMD INSTALL $(package)
	sudo $(RR) CMD INSTALL $(package)
	touch $@

$(package)/DESCRIPTION: DESCRIPTION
	echo 'Version: $(version)' | cat $< - > $@

$(Rfiles) $(package)/NAMESPACE: $(package)/noweb/implementation.rnw
	mkdir -p $(package)/R
	$(notangle) -R$(@F) $< | cpif $@
%.pdf: %.tex
	cd $(dir $<) && $(latexmk) $(LATEXMKFLAGS) $(<F)
$(package)/inst/doc/implementation.tex: $(package)/noweb/implementation.rnw
	mkdir -p $(package)/inst/doc
	$(noweave) -latex -index -delay $< | sed /^#/d | cpif $@

# I like this next rule.  The 'check' file depends on every file that's
# under version control or unknown in the $(package) subdirectory.
check: $(Rfiles) $(package)/NAMESPACE $(package)/DESCRIPTION $(addprefix $(package)/,$(shell bzr ls $(package)/ -R --unknown -V --kind=file))
	$(RR) CMD check $(package)
	touch $@