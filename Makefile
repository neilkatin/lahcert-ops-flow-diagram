

all: ops-flow.html
.PHONY: all

ops-flow.html: script.sh ops-flow.template
	./script.sh
