
build: build_harvest_icon build_harvest

.PHONY: build_harvest
build_harvest:
	@mkdir -p build/Harvest.iconset
	@nativefier \
		--overwrite \
		--name Harvest \
		--icon build/Harvest.icns \
		https://revsys.harvestapp.com \
		build

build_harvest_icon:
	@mkdir -p build/Harvest.iconset
	@sips -z 16 16 harvest.png --out build/Harvest.iconset/icon_16x16.png
	@sips -z 32 32 harvest.png --out build/Harvest.iconset/icon_16x16@2.png
	@sips -z 32 32 harvest.png --out build/Harvest.iconset/icon_32x32.png
	@sips -z 64 64 harvest.png --out build/Harvest.iconset/icon_32x32@2.png
	@sips -z 64 64 harvest.png --out build/Harvest.iconset/icon_64x64.png
	@sips -z 128 128 harvest.png --out build/Harvest.iconset/icon_128x128.png
	@sips -z 256 256 harvest.png --out build/Harvest.iconset/icon_128x128@2.png
	@sips -z 256 256 harvest.png --out build/Harvest.iconset/icon_256x256.png
	@sips -z 512 512 harvest.png --out build/Harvest.iconset/icon_256x256@2.png
	@sips -z 512 512 harvest.png --out build/Harvest.iconset/icon_512x512.png
	@iconutil -c icns build/Harvest.iconset
	@rm -R build/Harvest.iconset

.PHONY: symlink_harvest
symlink_harvest:
	ln -s $HOME/.homesick/repos/dotfiles/apps/buffer/build/Harvest-darwin-x64/Harvest.app ~/Applications/Harvest.app
