# Driver for the mixers. Note that we only
# have to test in the "libraries", the
# top level compiles everything anyway.

APPS = clixir uderzo uderzo_demo_nerves

# By default, do everything to make the app run.
all: setup deps
	cd uderzo_demo_nerves; mix do deps.get, compile

test: deps
	for i in $(APPS); do cd $$i; mix test --no-start; cd ..; done

deps:
	for i in $(APPS); do cd $$i; mix deps.get; cd ..; done

setup:
	asdf install
	mix local.hex --if-missing --force
	mix local.rebar --if-missing --force
	yes | mix archive.install hex nerves_bootstrap
