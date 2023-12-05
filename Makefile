# var
MODULE  = $(notdir $(CURDIR))
module  = $(shell echo $(MODULE) | tr A-Z a-z)
OS      = $(shell uname -o|tr / _)
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
CORES  ?= $(shell grep processor /proc/cpuinfo | wc -l)

# version
JQUERY_VER    = 3.7.1
JQUERY_UI_VER = 1.13.2

# dir
CWD = $(CURDIR)
BIN = $(CWD)/bin
DOC = $(CWD)/doc
SRC = $(CWD)/src
TMP = $(CWD)/tmp
GZ  = $(HOME)/gz

# tool
CURL = curl -L -o
DC   = dmd
BLD  = dub build --compiler=$(DC)
RUN  = dub run   --compiler=$(DC)

# src
D += $(wildcard src/*.d)
J += $(wildcard dub*.json)
S += $(wildcard static/*.js)
T += $(wildcard views/*)

# all
.PHONY: all run
all: bin/$(MODULE)
bin/$(MODULE): $(D) $(J) $(S) $(T)
	$(BLD)
run: $(D) $(J) $(S) $(T)
	$(RUN)

# format
format: tmp/format_d
tmp/format_d: $(D)
	$(RUN) dfmt -- -i $? && touch $@

# doc
doc: doc/yazyk_programmirovaniya_d.pdf doc/Programming_in_D.pdf \
     doc/BuildWebAppsinVibe.pdf doc/BuildTimekeepWithVibe.pdf

doc/yazyk_programmirovaniya_d.pdf:
	$(CURL) $@ https://www.k0d.cc/storage/books/D/yazyk_programmirovaniya_d.pdf
doc/Programming_in_D.pdf:
	$(CURL) $@ http://ddili.org/ders/d.en/Programming_in_D.pdf
doc/BuildWebAppsinVibe.pdf:
	$(CURL) $@ https://raw.githubusercontent.com/reyvaleza/vibed/main/BuildWebAppsinVibe.pdf
doc/BuildTimekeepWithVibe.pdf:
	$(CURL) $@ https://raw.githubusercontent.com/reyvaleza/vibed/main/BuildTimekeepWithVibe.pdf

# install
APT_SRC = /etc/apt/sources.list.d
ETC_APT = $(APT_SRC)/d-apt.list
.PHONY: install update gz
install: doc gz $(ETC_APT)
	sudo apt update && sudo apt --allow-unauthenticated install -yu d-apt-keyring
	$(MAKE) update
	dub fetch dfmt
update:
	sudo apt update
	sudo apt install -yu `cat apt.txt`
$(APT_SRC)/%: tmp/%
	sudo cp $< $@
tmp/d-apt.list:
	sudo $(CURL) $@ http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list

gz: static/cdn/jquery.js static/cdn/jquery-ui.js

static/cdn/jquery.js:
	$(CURL) $@ https://code.jquery.com/jquery-$(JQUERY_VER).min.js
static/cdn/jquery-ui.js: $(GZ)/jquery-ui-$(JQUERY_UI_VER).zip
	unzip $< -d static/cdn
	mv static/cdn/jquery-ui-$(JQUERY_UI_VER)/images/* static/cdn/images/
	mv static/cdn/jquery-ui-$(JQUERY_UI_VER)/jquery-ui.min.js $@
	touch $@ ; rm -r static/cdn/jquery-ui-$(JQUERY_UI_VER)

$(GZ)/jquery-ui-$(JQUERY_UI_VER).zip:
	$(CURL) $@ https://jqueryui.com/resources/download/jquery-ui-$(JQUERY_UI_VER).zip
$(GZ)/jquery-ui-themes-$(JQUERY_UI_VER).zip:
	$(CURL) $@ https://jqueryui.com/resources/download/jquery-ui-themes-$(JQUERY_UI_VER).zip

# merge
MERGE += Makefile README.md LICENSE $(D) $(J) $(S)
MERGE += .clang-format .editorconfig .gitattributes .gitignore
MERGE += apt.txt
MERGE += bin doc src tmp static views

.PHONY: dev
dev:
	git push -v
	git checkout $@
	git pull -v
	git checkout shadow -- $(MERGE)
#	$(MAKE) doxy ; git add -f docs

.PHONY: shadow
shadow:
	git push -v
	git checkout $@
	git pull -v

.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v --tags
	$(MAKE) shadow

ZIP = tmp/$(MODULE)_$(NOW)_$(REL)_$(BRANCH).zip
zip:
	git archive --format zip --output $(ZIP) HEAD
