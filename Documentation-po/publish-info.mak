PROJ=$(HOME)/work/git-docs-ja
GIT_INFO=git.info
GITMAN_INFO=gitman.info
DIR_FILE=dir

all: $(PROJ)/docs/info/$(GIT_INFO) $(PROJ)/docs/info/$(GITMAN_INFO) $(PROJ)/docs/info/$(DIR_FILE)

$(DIR_FILE) : $(GIT_INFO) $(GITMAN_INFO)
	install-info --dir-file=$(DIR_FILE) --info-file=$(GIT_INFO)
	install-info --dir-file=$(DIR_FILE) --info-file=$(GITMAN_INFO)

$(PROJ)/docs/info/$(GIT_INFO) : $(GIT_INFO)
	cp -v $< $@

$(PROJ)/docs/info/$(GITMAN_INFO) : $(GITMAN_INFO)
	cp -v $< $@

$(PROJ)/docs/info/$(DIR_FILE) : $(DIR_FILE)
	cp -v $< $@

.PHONY: all
