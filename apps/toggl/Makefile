
.PHONY: build
build:
	@nativefier \
		--overwrite \
		--name "Toggl" \
		https://www.toggl.com/app \
		build

	@rsync -av --delete-after \
		build/Toggl-darwin-x64/Toggl.app/ \
		~/Applications/Toggl.app
