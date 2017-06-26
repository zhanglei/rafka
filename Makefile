.PHONY: install build test lint vet fmt clean list

# TODO(agis): include test when they're deterministic
install: vet fmt
	go install

# TODO(agis): include test when they're deterministic
build: vet fmt
	go build

test:
	test/end-to-end

lint:
	golint

vet:
	go vet

fmt:
	! gofmt -d -e -s *.go 2>&1 | tee /dev/tty | read

clean:
	go clean

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs
