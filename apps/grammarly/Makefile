
.PHONY: build
build:
	@nativefier \
		--name "Grammarly" \
		https://app.grammarly.com/ \
		build

	@rsync -a --delete-after \
		./build/Grammarly-darwin-x64/Grammarly.app/ \
		~/Applications/Grammarly.app
