ERL ?= erl
ERLC ?= erlc
REBAR ?= rebar

all: compile

static:
	@USE_STATIC_ICU="1" COUCHDB_STATIC="1" $(REBAR) compile


compile:
	@$(REBAR) compile

clean:
	@$(REBAR) clean
	@rm -f t/*.beam

test:
	@$(ERLC) -o t/ t/etap.erl
	prove t/*.t

verbose-test:
	@$(ERLC) -o t/ t/etap.erl
	prove -v t/*.t

cover: test
	@ERL_FLAGS="-pa ./ebin -pa ./t" \
		$(ERL) -detached -noshell -eval 'etap_report:create()' -s init stop
