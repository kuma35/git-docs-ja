# $(BRANCH) specify make argument
# directries:
# |= Documentation (source directory)
# | |- technical
# | |- RelNotes
# | |- config
# | |- howto
# | |- includes
# | |- mergetools
# |
# |- Documentation-sedout ( sed working directory)
# |
# |= Documentation-po (current directory) *.txt.po, *.txt.po4a-cfg
# | |- technical
# | |- RelNotes
# | |- config
# | |- howto
# | |- includes
# | |- mergetools
# | |- pot
# | | |- technical
# | | |- RelNotes
# | | |- config
# | | |- howto
# | | |- includes
# | | |- mergetools
# |
# |- Dcumentation-ja ( translated directory)
# | |- technical
# | |- RelNotes
# | |- config
# | |- howto
# | |- includes
# | |- mergetools
# |
# |- docs ( for github pages )
# | |- docs-ja-1 (old ver)
# | |- docs-ja-2 (old ver)
# | |- docs-ja-3 (old ver)
# | |- docs-ja-4 (current ver at 2024/12)

ifndef BRANCH
    $(error "specify BRANCH at command-line.")
endif

SRC_DIR = ../Documentation
SEDOUT_DIR = ../Documentation-sedout
SEDOUT_EXT = .adoc
ASCIIDOC_EXT = .adoc
# PO_DIR = . ( current directory )
PO_EXT = .po
POT_DIR = pot

# PO4A_CFG_DIR = ( current directory )
PO4A_CFG_EXT = .po4cfg

# vpath %$(PO4A_CFG_EXT) $(PO4A_CFG_DIR)

DST_DIR = ../Documentation-ja

TECHNICAL_DIR = technical
RELNOTES_DIR = RelNotes
CONFIG_DIR = config
HOWTO_DIR = howto
INCLUDES_DIR = includes
MERGETOOLS_DIR = mergetools

SRC_SUB_DIRS = $(TECHNICAL_DIR) $(RELNOTES_DIR) $(CONFIG_DIR) $(HOWTO_DIR) $(INCLUDES_DIR) $(MERGETOOLS_DIR)
# vpath %$(PO_EXT) $(SRC_SUB_DIRS)

SRC_INSTALL_TEXT = ../INSTALL
PO_INSTALL_TEXT = INSTALL.po
PO4A_CFG_INSTALL_TEXT = INSTALL.po4cfg
DST_INSTALL_TEXT = $(DST_DIR)/INSTALL.txt


# $(warning PO_INSTALL_TEXT = $(PO_INSTALL_TEXT))

# cmds_txt and mergetools_txt from Documentation/Makefile there are templates. not need translation.
cmds_txt = cmds-ancillaryinterrogators.adoc \
	cmds-ancillarymanipulators.adoc \
	cmds-mainporcelain.adoc \
	cmds-plumbinginterrogators.adoc \
	cmds-plumbingmanipulators.adoc \
	cmds-synchingrepositories.adoc \
	cmds-synchelpers.adoc \
	cmds-guide.adoc \
	cmds-developerinterfaces.adoc \
	cmds-userinterfaces.adoc \
	cmds-purehelpers.adoc \
	cmds-foreignscminterface.adoc

# $(warning cmds_txt= $(wildcard $(SRC_DIR)/cmds-*$(ASCIIDOC_EXT)))
# $(error "cmds_txt")

mergetools_txt = mergetools-diff.adoc mergetools-merge.adoc

EXCLUDE_TXT = $(cmds_txt) $(mergetools_txt)

SRC_PACKAGE = $(filter-out $(EXCLUDE_TXT),$(notdir $(wildcard $(SRC_DIR)/*$(ASCIIDOC_EXT))))
SRC_PACKAGE += $(foreach sub_dir, $(SRC_SUB_DIRS), $(addprefix $(sub_dir)/,$(notdir $(wildcard $(SRC_DIR)/$(sub_dir)/*$(ASCIIDOC_EXT)))))

# $(error "SRC_PACKAGE = $(SRC_PACKAGE)")

SRC_FILES = $(addprefix $(SRC_DIR)/,$(SRC_PACKAGE))

# $(error "SRC_FILES = $(SRC_FILES)")

SEDOUT_FILES = $(addprefix $(SEDOUT_DIR)/,$(SRC_PACKAGE:$(ASCIIDOC_EXT)=$(SEDOUT_EXT)))

# $(warning SEDOUT_FILES = $(SEDOUT_FILES))

PO_FILES = $(SRC_PACKAGE:$(ASCIIDOC_EXT)=$(PO_EXT))

# $(error "PO_FILES = $(PO_FILES)")

PO4A_CFG_FILES = $(SRC_PACKAGE:$(ASCIIDOC_EXT)=$(PO4A_CFG_EXT))

# $(error "PO4A_CFG_FILES = $(PO4A_CFG_FILES)")

DST_FILES = $(addprefix $(DST_DIR)/,$(SRC_PACKAGE))

# $(warning DST_FILES = $(DST_FILES))
# $(error "debug stop")

help:
	@echo "instead, please run from compile.sh"

.DEFAULT_GOAL := help

# [ -e $@ ] || ... ターゲットが存在しない時だけ実行。
# 原文ファイルが追加された時に対応
# 構造が変わる時は mk-po4a-cfg.sh を作り変えなければならない
# ので、その時は全 po4cfg ファイルを削除してから make 
$(PO4A_CFG_FILES): %$(PO4A_CFG_EXT) : $(SEDOUT_DIR)/%$(ASCIIDOC_EXT)
	./mk-po4a-cfg.sh $< > $@;

$(PO4A_CFG_INSTALL_TEXT): $(SRC_INSTALL_TEXT)
	./mk-po4a-cfg-install-text.sh $< > $@

# $(error "debug stop")


$(SEDOUT_FILES): $(SEDOUT_DIR)/%$(SEDOUT_EXT) : $(SRC_DIR)/%$(ASCIIDOC_EXT)
	sed -f ./protect-opt-dash.sed $< | gawk -f ./pre-gettext.awk > $@

# --no-translations --no-update は変更無しの時タイムスタンプ更新しないので
# touch --no-create して強制更新する
$(PO_FILES): %$(PO_EXT) : $(SEDOUT_DIR)/%$(SEDOUT_EXT) | %$(PO4A_CFG_EXT)
	po4a --no-translations --keep 0 --master-charset UTF-8 $(@:$(PO_EXT)=$(PO4A_CFG_EXT))
	touch --no-create $@

$(PO_INSTALL_TEXT): $(SRC_INSTALL_TEXT)
	po4a --no-translations --keep 0 --master-charset UTF-8 $(@:$(PO_EXT)=$(PO4A_CFG_EXT))
	touch --no-create $@

$(DST_FILES): $(DST_DIR)/%$(ASCIIDOC_EXT) : %$(PO_EXT) | %$(PO4A_CFG_EXT)
	po4a --no-update --keep 0 --master-charset UTF-8 $(<:$(PO_EXT)=$(PO4A_CFG_EXT))
	touch --no-create $@

$(DST_INSTALL_TEXT): $(PO_INSTALL_TEXT)
	po4a --no-update --keep 0 --master-charset UTF-8 $(<:$(PO_EXT)=$(PO4A_CFG_EXT))
	touch --no-create $@

# Documentation/Makefile に 追加した場合に反映させる。 (technicalに一部html化されてないのがあった)
$(DST_DIR)/Makefile : $(SRC_DIR)/Makefile
	cp $< $@

# Documentation/technical/api-index.sh を変更した場合に反映させる。
$(DST_DIR)/technical/api-index.sh : $(SRC_DIR)/technical/api-index.sh
	cp $< $@

# Documentation/asciidoc.conf 修正を反映させる
# cd Documantaion
# make asciidoc.conf
$(DST_DIR)/asciidoc.conf : $(SRC_DIR)/asciidoc.conf
	cp $< $@

ja: $(DST_FILES) $(DST_INSTALL_TEXT) $(DST_DIR)/Makefile $(DST_DIR)/technical/api-index.sh $(DST_DIR)/asciidoc.conf

# rsyncの $(SRC_DIR)の直後の / 重要。超重要
# cmds-*.txt are templates. not need translation. copy from $(SRC_DIR) to $(DST_DIR)
# rsync -av --exclude "*.txt" $(SRC_DIR)/ $(DST_DIR)
clean:
	find $(DST_DIR) -type f | xargs rm -f
	find $(DST_DIR) -empty | xargs rmdir
	rsync -av --include "cmds-*.adoc" --include "mergetools-*.adoc" --include "*.adoco" \
		--exclude "*.adoc" $(SRC_DIR)/ $(DST_DIR)

.PHONEY: ja clean help
