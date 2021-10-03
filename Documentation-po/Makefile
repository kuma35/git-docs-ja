
SRC_DIR = ../Documentation
ASCIIDOC_EXT = .txt
PO_DIR = .
PO_EXT = .po
DST_DIR = ../Documentation-ja

SRC_CURRENT = $(notdir $(wildcard $(SRC_DIR)/*$(ASCIIDOC_EXT)))
SRC_TECHNICAL = $(addprefix technical/,$(notdir $(wildcard $(SRC_DIR)/technical/*$(ASCIIDOC_EXT))))
SRC_RELNOTES = $(addprefix RelNotes/,$(notdir $(wildcard $(SRC_DIR)/RelNotes/*$(ASCIIDOC_EXT))))
SRC_CONFIG = $(addprefix config/,$(notdir $(wildcard $(SRC_DIR)/config/*$(ASCIIDOC_EXT))))
SRC_HOWTO = $(addprefix howto/,$(notdir $(wildcard $(SRC_DIR)/howto/*$(ASCIIDOC_EXT))))

SRC_PACKAGE = $(SRC_CURRENT)
SRC_PACKAGE += $(SRC_TECHNICAL)
SRC_PACKAGE += $(SRC_RELNOTES)
SRC_PACKAGE += $(SRC_CONFIG)
SRC_PACKAGE += $(SRC_HOWTO)

SRC_FILES = $(addprefix $(SRC_DIR)/,$(SRC_PACKAGE))

# $(warning SRC_FILES = $(SRC_FILES))

PO_FILES = $(addprefix $(PO_DIR)/,$(SRC_PACKAGE:$(ASCIIDOC_EXT)=$(PO_EXT)))

# $(warning PO_FILES = $(PO_FILES))

DST_FILES = $(addprefix $(DST_DIR)/,$(SRC_PACKAGE))

# $(warning DST_FILES = $(DST_FILES))


$(PO_FILES): $(PO_DIR)/%.po : $(SRC_DIR)/%.txt
	po4a-updatepo -M utf8 -f asciidoc -m $< -p $@

$(DST_FILES): $(DST_DIR)/%.txt : $(PO_DIR)/%.po
	po4a-translate -f asciidoc -keep 0 -M utf8 -m $(subst $(DST_DIR),$(SRC_DIR),$(@:$(PO_EXT)=$(ASCIIDOC_EXT))) -p $< -l $@

ja: $(DST_FILES)

# rsyncの $(SRC_DIR)の直後の / 重要。超重用
clean:
	find $(DST_DIR) -type f | xargs rm -f
	find $(DST_DIR) -empty | xargs rmdir
	rsync -av --exclude "*.txt" $(SRC_DIR)/ $(DST_DIR)

.PHONEY: ja clean
