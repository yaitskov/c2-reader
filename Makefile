CABAL := wasm32-wasi-cabal

.PHONY: all update build optim serve clean sync clear

all: update clear sync build optim

update:
	$(CABAL) update
clear:
	rm -rf public
sync:
	mkdir -p public
	rsync -r static/ public
# cp -r static public
build:
	$(CABAL) build c2reader
	app=$$($(CABAL) list-bin c2reader | tail -n 1); \
	$$(wasm32-wasi-ghc --print-libdir)/post-link.mjs --input $$app --output public/ghc_wasm_jsffi.js; \
	cp -v $$app public/app.wasm

optim:
	wasm-opt -all --disable-compact-imports -O2 public/app.wasm -o public/app.wasm
	wasm-tools strip -o public/app.wasm public/app.wasm

serve:
	http-server public -p 8080 -c-1

clean:
	rm -rf dist-newstyle public
