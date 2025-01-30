GIT-TAG := $(shell git tag --points-at)
GIT-DEV-TAG := git
GIT-TAG := $(if $(GIT-TAG),$(GIT-TAG),$(GIT-DEV-TAG))
TEXMFHOME := $(shell kpsewhich -var-value TEXMFHOME)

DIST := pdfpages-$(GIT-TAG)
BUILD = ./build
DIST-DIR = $(BUILD)/$(DIST)
TDS-ZIP-FILE = $(BUILD)/pdfpages.tds.zip

DIST-FILES = \
	pdfpages.ins \
	pdfpages.dtx \
	README \
	dummy.pdf \
	dummy-l.pdf
CTAN-DOC-FILES = \
	pdfpages.pdf
TDS-STY-FILES = \
	pdfpages.sty \
	pppdftex.def \
	ppluatex.def \
	ppvtex.def \
	ppxetex.def \
	ppdvipdfmx.def \
	ppdvips.def \
	ppnull.def
TDS-DOC-FILES = \
	pdfpages.pdf \
	pdf-ex.tex \
	pdf-hyp.tex \
	pdf-toc.tex \
	dummy.pdf \
	dummy-l.pdf
TDS-SRC-FILES = \
	pdfpages.dtx \
	pdfpages.ins \
	README

TDS-STY-DIR = tex/latex/pdfpages
TDS-DOC-DIR = doc/latex/pdfpages
TDS-SRC-DIR = source/latex/pdfpages

.PHONY: all
all: sty
.PHONY: ins
ins: pdfpages.ins
.PHONY: sty
sty: $(TDS-STY-FILES)
.PHONY: tds
tds: $(TDS-ZIP-FILE)

pdfpages.ins: pdfpages.dtx
	echo '\\input{docstrip}\\askforoverwritefalse\\generate{\\file{pdfpages.ins}{\\from{pdfpages.dtx}{installer}}}\\endbatchfile' > pdfpages.installer
	latex pdfpages.installer
	rm pdfpages.installer

$(TDS-STY-FILES): pdfpages.ins
	latex pdfpages.ins
	./scripts/insert-git-info pdfpages.sty

$(TDS-ZIP-FILE): $(TDS-STY-FILES) $(TDS-DOC-FILES) $(TDS-SRC-FILES) $(DIST-FILES)
# Build package files
	rm -rf $(BUILD)
	mkdir $(BUILD)
	echo '\PassOptionsToClass{a4paper}{ltxdoc}' > $(BUILD)/ltxdoc.cfg
	cp $(DIST-FILES) $(BUILD)
	./scripts/insert-git-info $(BUILD)/pdfpages.dtx
	cd $(BUILD); luatex pdfpages.ins
	cd $(BUILD); lualatex pdfpages.dtx
	cd $(BUILD); lualatex pdfpages.dtx

# Create TDS structure
	mkdir -p $(DIST-DIR)/$(TDS-STY-DIR)
	cp $(addprefix $(BUILD)/,$(TDS-STY-FILES)) $(DIST-DIR)/$(TDS-STY-DIR)
	mkdir -p $(DIST-DIR)/$(TDS-DOC-DIR)
	cp $(addprefix $(BUILD)/,$(TDS-DOC-FILES)) $(DIST-DIR)/$(TDS-DOC-DIR)
	mkdir -p $(DIST-DIR)/$(TDS-SRC-DIR)
	cp $(addprefix $(BUILD)/, $(TDS-SRC-FILES)) $(DIST-DIR)/$(TDS-SRC-DIR)
	chmod 755 $(DIST-DIR)
	find $(DIST-DIR) -type d -exec chmod 755 {} \;
	find $(DIST-DIR) -type f -exec chmod 644 {} \;

# Create TDS-zip file
	cd $(DIST-DIR); zip -r pdfpages.tds.zip tex doc source
	cp $(DIST-DIR)/pdfpages.tds.zip $(BUILD)
	chmod 644 $(TDS-ZIP-FILE)
	rm -rf $(DIST-DIR)

.PHONY: install
install: $(TDS-ZIP-FILE)
	unzip -od $(TEXMFHOME) $(TDS-ZIP-FILE)

.PHONY: uninstall
uninstall:
	rm -r $(addprefix $(TEXMFHOME)/,$(TDS-STY-DIR) $(TDS-DOC-DIR) $(TDS-SRC-DIR))

.PHONY: release
release: error-if-uncommitted-changes release-force

.PHONY: release-force
release-force: tds
	mkdir -p $(BUILD)/pdfpages
	cp $(addprefix $(BUILD)/,$(DIST-FILES) $(CTAN-DOC-FILES)) $(BUILD)/pdfpages
	cd $(BUILD); zip -r $(DIST).zip pdfpages pdfpages.tds.zip
	mv $(BUILD)/$(DIST).zip .
	@echo "!!!"
ifeq "$(GIT-TAG)" "$(GIT-DEV-TAG)"
	@echo "!!! This is a development release."
endif
	@echo "!!! Release file: $(DIST).zip"
	@echo "!!!"

.PHONY: error-if-uncommitted-changes
error-if-uncommitted-changes:
ifneq "$(shell git status --porcelain $(DIST-FILES))" ""
	@echo "!!!"
	@echo "!!! Cannot make release:"
	@echo "!!! There are uncommitted changes."
	@echo "!!! To force a release, run: make release-force"
	@echo "!!!"
	@exit 1
endif

subdirs := test
.PHONY: $(subdirs)
$(subdirs):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: clean
clean: $(subdirs)
	rm -f $(addprefix pdfpages, .aux .log .toc .out .hd)
	rm -f $(addprefix pdf-ex, .tex .log .aux)
	rm -f $(addprefix pdf-hyp, .tex .log .aux)
	rm -f $(addprefix pdf-toc, .tex .log .aux)

.PHONY: distclean
distclean: clean $(subdirs)
	rm -f $(TDS-STY-FILES) pdfpages.ins pdfpages.pdf
	rm -rf build/
	rm -f pdfpages-*.zip
