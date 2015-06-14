VERSION=$(shell grep '\\def\\AM@fileversion{' pdfpages.dtx |\
	sed 's/\\def\\AM@fileversion{\(.*\)}/\1/')
DIST=pdfpages-$(VERSION)
DIST-DIR=$(DIST)


DIST-FILES=pdfpages.ins pdfpages.dtx README dummy.pdf dummy-l.pdf
CTAN-DOC-FILES=pdfpages.pdf

TDS-STY-FILES=pdfpages.sty pppdftex.def ppluatex.def ppvtex.def ppxetex.def ppdvipdfm.def ppdvips.def ppnull.def
TDS-DOC-FILES=pdfpages.pdf pdf-ex.tex pdf-hyp.tex pdf-toc.tex \
	 dummy.pdf dummy-l.pdf
TDS-SRC-FILES=pdfpages.dtx pdfpages.ins README

TDS-STY-DIR=tex/latex/pdfpages
TDS-DOC-DIR=doc/latex/pdfpages
TDS-SRC-DIR=source/latex/pdfpages


all: sty

installer=pdfpages.installer
ins:
	echo '\\input{docstrip}\\askforoverwritefalse\\generate{\\file{pdfpages.ins}{\\from{pdfpages.dtx}{installer}}}\\endbatchfile' > $(installer)
	latex $(installer)
	rm $(installer)

sty: ins
	latex pdfpages.ins


release: git-check release-force
release-force: distclean ins
	tex pdfpages.ins
	echo '\PassOptionsToClass{a4paper}{ltxdoc}' > ltxdoc.cfg
	-pdflatex -interaction=nonstopmode pdfpages.dtx
	pdflatex pdfpages.dtx
	pdflatex pdfpages.dtx
	pdflatex pdfpages.dtx
	rm ltxdoc.cfg

	rm -rf $(DIST-DIR)
	mkdir $(DIST-DIR)
	mkdir $(DIST-DIR)/pdfpages
	cp $(DIST-FILES) $(CTAN-DOC-FILES) $(DIST-DIR)/pdfpages
	mkdir -p $(DIST-DIR)/$(TDS-STY-DIR)
	cp $(TDS-STY-FILES) $(DIST-DIR)/$(TDS-STY-DIR)
	mkdir -p $(DIST-DIR)/$(TDS-DOC-DIR)
	cp $(TDS-DOC-FILES) $(DIST-DIR)/$(TDS-DOC-DIR)
	mkdir -p $(DIST-DIR)/$(TDS-SRC-DIR)
	cp $(TDS-SRC-FILES) $(DIST-DIR)/$(TDS-SRC-DIR)

	chmod 755 $(DIST-DIR)
	find $(DIST-DIR) -type d -exec chmod 755 {} \;
	find $(DIST-DIR) -type f -exec chmod 644 {} \;

	cd $(DIST-DIR); zip -r pdfpages.tds.zip tex doc source
	cd $(DIST-DIR); chmod 644 pdfpages.tds.zip
	cd $(DIST-DIR); rm -r tex doc source

	cd $(DIST-DIR); tar cjfh $(DIST).tar.bz2 *
	cd $(DIST-DIR); chmod 644 $(DIST).tar.bz2
	cd $(DIST-DIR); rm -rf pdfpages pdfpages.tds.zip


git-check:
ifneq "$(shell git status --porcelain pdfpages.dtx)" ""
	@echo "!!!"
	@echo "!!! Cannot make release:"
	@echo "!!! There are uncommitted changes in \`pdfpages.dtx'."
	@echo "!!! To force a release, run: make release-force"
	@echo "!!!"
	@exit 1
endif

FORCE:

foo:
	# @if [ -n $(git status --porcelain pdfpages.dtx) ];\
	# then \
	# 	echo "!!!"; \
	# 	echo "!!! Cannot make release:"; \
	# 	echo "!!! There are uncommitted changes in \`pdfpages.dtx'."; \
	# 	echo "!!! To force a release, run: make release-force"; \
	# 	echo "!!!"; \
	# 	exit 1; \
	# fi


clean:
	rm -f pdfpages.{sty,aux,log,toc,out,dvi,pdf}
	rm -f $(TDS-STY-FILES)
	rm -f pdf-ex.{tex,log,aux}
	rm -f pdf-hyp.{tex,log,aux}
	rm -f pdf-toc.{tex,log,aux}
	rm -rf $(TMP-DIR)

distclean: clean
	rm -f *.bz2 pdfpages.ins
