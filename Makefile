# Driver for the mixers. Note that we only
# have to test in the "libraries", the
# top level compiles everything anyway.

APPS = uderzo_demo_nerves

all:
	cd uderzo_demo_nerves; mix do deps.get, compile

test: deps
	for i in $(APPS); do cd $$i; mix test --no-start; done

deps:
	for i in $(APPS); do cd $$i; mix deps.get; done

setup:
	mix local.hex --if-missing --force
	mix local.rebar --if-missing --force
	yes | mix archive.install hex nerves_bootstrap
