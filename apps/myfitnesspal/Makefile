
.PHONY: build
build:
	@nativefier \
		--overwrite \
		--name "MyFitnessPal" \
		--tray \
		https://www.myfitnesspal.com/ \
		build

	@rsync -av --delete-after \
		build/MyFitnessPal-darwin-x64/MyFitnessPal.app/ \
		~/Applications/MyFitnessPal.app
