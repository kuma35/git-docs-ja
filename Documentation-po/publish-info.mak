# spcify BRANCH from command line arguments:
# i.e. make -f publish-info.maek BRANCH=${BRANCH}
PROJ=$(HOME)/work/git-docs-ja
PUB_INFO_DIR=$(PROJ)/docs/$(BRANCH)/info
GIT_INFO=git.info
GITMAN_INFO=gitman.info
DIR_FILE=dir

all: $(PUB_INFO_DIR)/$(GIT_INFO) $(PUB_INFO_DIR)/$(GITMAN_INFO) $(PUB_INFO_DIR)/$(DIR_FILE)

$(DIR_FILE) : $(GIT_INFO) $(GITMAN_INFO)
	install-info --dir-file=$(DIR_FILE) --info-file=$(GIT_INFO)
	install-info --dir-file=$(DIR_FILE) --info-file=$(GITMAN_INFO)

$(PROJ)/docs/$(BRANCH)/info/$(GIT_INFO) : $(GIT_INFO)
	cp -v $< $@

$(PROJ)/docs/$(BRANCH)/info/$(GITMAN_INFO) : $(GITMAN_INFO)
	cp -v $< $@

$(PROJ)/docs/$(BRANCH)/info/$(DIR_FILE) : $(DIR_FILE)
	cp -v $< $@

.PHONY: all
