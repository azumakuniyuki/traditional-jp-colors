# $Id: Makefile,v 1.1 2010/02/11 10:49:59 ak Exp $
# Makefile for traditional-jp-colors
#  __  __       _         __ _ _      
# |  \/  | __ _| | _____ / _(_) | ___ 
# | |\/| |/ _` | |/ / _ \ |_| | |/ _ \
# | |  | | (_| |   <  __/  _| | |  __/
# |_|  |_|\__,_|_|\_\___|_| |_|_|\___| for Traditional JP Colors
# ---------------------------------------------------------------------------
#
VERSION = 1.0.16
SOURCE = http://www.colordic.org/w/
BASE = traditional-jp-colors
TEMPDIR = temp
BANNER = include/banner
FILES = $(BASE).tsv $(BASE).yaml $(BASE).dtx $(BASE).vim $(BASE).plist \
	$(BASE).plist.diff Colors.plist rgb.txt $(BASE)-rgb.txt $(BASE).json \
	$(BASE).less $(BASE).sed $(BASE).html

.PHONY: clean
all: $(FILES)
table: $(BASE).tsv
dtx: $(BASE).dtx
rgb: $(BASE)-rgb.txt rgb.txt
yaml: $(BASE).yaml
json: $(BASE).json
macvim: $(BASE).plist Colors.plist $(BASE).plist.diff
vim: $(BASE).vim
less: $(BASE).less
sed: $(BASE).sed
html: $(BASE).html

data:
	@test -s "data" || ( \
		rm -f index.html ;\
		wget '$(SOURCE)' ;\
		mv index.html data ;\
	)

$(BASE).tsv: data
	test -s data && perl MAKEMAP.PL > $@

$(BASE)-rgb.txt: $(BASE).tsv
	touch $@
	printf "%3d %3d %3d\t\t%s\n" `grep -v '^ColorName' $(BASE).tsv | awk '{ print $$6,$$7,$$8,$$3}' ` >> $@

rgb.txt:
	touch $@
	if [ -x "/usr/X11R6/bin/showrgb" ]; then \
		/usr/X11R6/bin/showrgb >> $@ ;\
	else \
		cat include/rgb.txt >> $@ ;\
	fi

$(BASE).dtx: $(BASE).tsv
	touch $@
	cat include/$(BASE).ins > $(BASE).ins
	cat include/head.dtx >> $@
	for L in `grep -v '^ColorName' $(BASE).tsv | tr '\t' '-'`; do \
		echo $$L | awk -F- '{ print "\\definecolor{"$$3"}{rgb}{"$$6","$$7","$$8"}\t%"$$1"("$$2")" }' >> $@ ;\
	done
	cat include/foot.dtx >> $@

$(BASE).yaml: $(BASE).tsv
	make temp
	cp /dev/null $(TEMPDIR)/name.tmp
	cp /dev/null $(TEMPDIR)/kana.tmp
	cp /dev/null $(TEMPDIR)/roman.tmp
	cp /dev/null $(TEMPDIR)/color.tmp
	for L in `grep -v '^ColorName' $(BASE).tsv | tr '\t' '-'`; do \
		echo $$L | awk -F- '{ print "|name|: |"$$1"|," }' >> $(TEMPDIR)/name.tmp ;\
		echo $$L | awk -F- '{ print "|kana|: |"$$2"|," }' >> $(TEMPDIR)/kana.tmp ;\
		echo $$L | awk -F- '{ print "|roman|: |"$$3"|," }' >> $(TEMPDIR)/roman.tmp ;\
		echo $$L | awk -F- '{ print "|color|: { |hex|: |"$$4"|, |dec|: "$$5", |r|: "$$6", |g|: "$$7", |b|: "$$8" } "}' \
			>> $(TEMPDIR)/color.tmp ;\
	done
	touch $@
	cat $(BANNER) | sed 's/^/#/g' >> $@
	paste -d' ' $(TEMPDIR)/name.tmp $(TEMPDIR)/kana.tmp $(TEMPDIR)/roman.tmp $(TEMPDIR)/color.tmp | \
		tr '|' '"' | sed -e 's|^|- { |g' -e 's|$$|}|g' >> $@

$(BASE).json: $(BASE).yaml
	make temp
	cp /dev/null $(TEMPDIR)/$@.tmp
	printf '[ ' >> $(TEMPDIR)/$@.tmp
	cat $(BASE).yaml | sed -e 's|^- ||g' -e 's|$$|,|g' >> $(TEMPDIR)/$@.tmp
	cat $(TEMPDIR)/$@.tmp | sed '$$s/},/} ]/' > $@

$(BASE).plist: $(BASE).tsv
	make temp
	touch $@
	cat include/Colors-head.plist >> $@
	touch $(TEMPDIR)/$@.tmp
	for L in `grep -v '^ColorName' $(BASE).tsv | tr '\t' '-'`; do \
		echo $$L | awk -F- '{ print "\t<key>"$$3"</key>" }' >> $(TEMPDIR)/$@.tmp ;\
		echo $$L | awk -F- '{ print "\t<integer>"$$5"</integer>" }' >> $(TEMPDIR)/$@.tmp ;\
	done
	cat $(TEMPDIR)/$@.tmp >> $@
	cat include/Colors-foot.plist >> $@

Colors.plist: $(BASE).plist
	make temp
	touch $@
	cat include/Colors-head.plist >> $@
	cat include/Colors-body.plist >> $@
	if [ -s "$(TEMPDIR)/$(BASE).plist.tmp" ]; then \
		cat $(TEMPDIR)/$(BASE).plist.tmp >> $@ ;\
	else \
		for L in `grep '^ColorName' $(BASE).tsv | tr '\t' '-'`; do \
			echo $$L | awk -F- '{ print "\t<key>"$$3"</key>" }' >> $@ ;\
			echo $$L | awk -F- '{ print "\t<integer>"$$5"</integer>" }' >> $@ ;\
		done ;\
	fi
	cat include/Colors-foot.plist >> $@

$(BASE).plist.diff: Colors.plist
	touch $@
	diff -u include/MacVim-Colors.plist Colors.plist | sed \
		-e 's|--- include/MacVim-Colors.plist|--- /Applications/MacVim.app/Contents/Resources/Colors.plist|' \
		-e 's|+++ |+++ /Applications/MacVim.app/Contents/Resources/|' >> $@ || true

$(BASE).vim: $(BASE).tsv
	make temp
	touch $@
	cp /dev/null $(TEMPDIR)/let.tmp
	cp /dev/null $(TEMPDIR)/comment.tmp
	for L in `grep -v '^ColorName' $(BASE).tsv | tr '\t' '-'`; do \
		echo $$L | awk -F- '{ print "let b:"$$3" = |"$$4"|" }' | tr '|' "'" >> $(TEMPDIR)/let.tmp ;\
		echo $$L | awk -F- '{ print "|"$$1"("$$2") "$$6","$$7","$$8 }' | tr '|' '"' >> $(TEMPDIR)/comment.tmp ;\
	done
	cat $(BANNER) | sed 's/^/"/g' >> $@
	paste $(TEMPDIR)/let.tmp $(TEMPDIR)/comment.tmp >> $@

$(BASE).less: $(BASE).tsv
	touch $@
	cat $(BANNER) | sed 's|^|//|g' >> $@
	echo '// LESS Variables, see http://lesscss.org/' >> $@
	for L in `grep -v '^ColorName' $(BASE).tsv | tr '\t' '-'`; do \
		echo $$L | awk -F- '{ print "@"$$3": "$$4";" }' >> $@ ;\
	done

$(BASE).sed: $(BASE).tsv
	touch $@
	awk '{ print "s/"$$3"/"$$4"/g"}' $(BASE).tsv >> $@

$(BASE).html: data
	cp ./data $@


temp:
	mkdir -p ./$(TEMPDIR)

clean:
	rm -rf $(TEMPDIR)
	rm -f $(FILES) ./*.ins ./*.tmp ./*.bak ./*~

distclean: clean
	rm -f data

