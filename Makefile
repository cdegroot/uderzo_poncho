# Driver for the mixers. Note that we only
# have to test in the "libraries", the
# top level compiles everything anyway.

# TODO: fix uderzo_demo_nerves

APPS = clixir clixir_example uderzo #uderzo_demo_nerves
SYSTEM = $(shell uname -s | tr 'A-Z' 'a-z')

# By default, do everything to make the app run. This
# is what we want CircleCI to run.
all: setup deps test
	#cd uderzo_demo_nerves; mix compile

clean:
	for i in $(APPS); do cd $$i; rm -rf _build deps priv/clixir; cd ..; done

test:
	set -e; for i in $(APPS); do echo "Testing in $$i"; (cd $$i; mix test); done

deps:
	set -e; for i in $(APPS); do echo "Resolving deps in $$i"; (cd $$i; mix deps.get); done

setup:
	set -e
	asdf install
	mix local.hex --if-missing --force
	mix local.rebar --if-missing --force
	yes | mix archive.install hex nerves_bootstrap
	cd uderzo; make -f setup.mk $(SYSTEM)
