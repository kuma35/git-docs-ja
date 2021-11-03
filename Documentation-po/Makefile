
SRC_DIR = ../Documentation
SEDOUT_DIR = ../Documentation-sedout
SEDOUT_EXT = .txt
ASCIIDOC_EXT = .txt
PO_DIR = .
PO_EXT = .po
DST_DIR = ../Documentation-ja
TECHNICAL_DIR = technical
RELNOTES_DIR = RelNotes
CONFIG_DIR = config
HOWTO_DIR = howto

SRC_CURRENT = $(notdir $(wildcard $(SRC_DIR)/*$(ASCIIDOC_EXT)))
SRC_TECHNICAL = $(addprefix TECHNICAL_DIR/,$(notdir $(wildcard $(SRC_DIR)/TECHNICAL_DIR/*$(ASCIIDOC_EXT))))
SRC_RELNOTES = $(addprefix RELNOTES_DIR/,$(notdir $(wildcard $(SRC_DIR)/RELNOTES_DIR/*$(ASCIIDOC_EXT))))
SRC_CONFIG = $(addprefix CONFIG_DIR/,$(notdir $(wildcard $(SRC_DIR)/CONFIG_DIR/*$(ASCIIDOC_EXT))))
SRC_HOWTO = $(addprefix HOWTO_DIR/,$(notdir $(wildcard $(SRC_DIR)/HOWTO_DIR/*$(ASCIIDOC_EXT))))

SRC_PACKAGE = $(SRC_CURRENT)
SRC_PACKAGE += $(SRC_TECHNICAL)
SRC_PACKAGE += $(SRC_RELNOTES)
SRC_PACKAGE += $(SRC_CONFIG)
SRC_PACKAGE += $(SRC_HOWTO)

SRC_FILES = $(addprefix $(SRC_DIR)/,$(SRC_PACKAGE))

# $(warning SRC_FILES = $(SRC_FILES))

SEDOUT_FILES = $(addprefix $(SEDOUT_DIR)/,$(SRC_PACKAGE:$(ASCIIDOC_EXT)=$(SEDOUT_EXT)))

# $(warning SEDOUT_FILES = $(SEDOUT_FILES))

PO_FILES = $(addprefix $(PO_DIR)/,$(SRC_PACKAGE:$(ASCIIDOC_EXT)=$(PO_EXT)))

# $(warning PO_FILES = $(PO_FILES))

DST_FILES = $(addprefix $(DST_DIR)/,$(SRC_PACKAGE))

# $(warning DST_FILES = $(DST_FILES))


$(SEDOUT_FILES): $(SEDOUT_DIR)/%$(SEDOUT_EXT) : $(SRC_DIR)/%$(ASCIIDOC_EXT)
	sed -f ./protect-opt-dash.sed < $< > $@

$(PO_FILES): $(PO_DIR)/%$(PO_EXT) : $(SEDOUT_DIR)/%$(SEDOUT_EXT)
	po4a-updatepo -M utf8 -f asciidoc -m $< -p $@

$(DST_FILES): $(DST_DIR)/%$(ASCIIDOC_EXT) : $(PO_DIR)/%$(PO_EXT)
	po4a-translate -f asciidoc -keep 0 -M utf8 -m $(subst $(DST_DIR),$(SEDOUT_DIR),$(@:$(PO_EXT)=$(ASCIIDOC_EXT))) -p $< -l $@

ja: $(DST_FILES)

# rsyncの $(SRC_DIR)の直後の / 重要。超重用
clean:
	find $(DST_DIR) -type f | xargs rm -f
	find $(DST_DIR) -empty | xargs rmdir
	rsync -av --exclude "*.txt" $(SRC_DIR)/ $(DST_DIR)

.PHONEY: ja clean
