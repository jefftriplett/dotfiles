
.PHONY: build
build:
	@nativefier \
		--overwrite \
		--name "Asana" \
		https://asana.com/ \
		build

	@rsync -a --delete-after \
		./build/Asana-darwin-x64/Asana.app/ \
		~/Applications/Asana.app
