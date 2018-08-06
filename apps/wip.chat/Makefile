
.PHONY: build
build:
	@nativefier \
		--overwrite \
		--name "WIP Chat" \
		--tray \
		https://wip.chat/ \
		build

	@rsync -av --delete-after \
		./build/WIP\ Chat-darwin-x64/WIP\ Chat.app/ \
		~/Applications/WIP\ Chat.app
