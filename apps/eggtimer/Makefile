
build: build_app_icon build_app

.PHONY: build_app
build_app:
	mkdir -p build/EggTimer.iconset
	@nativefier \
		--overwrite \
		--name "Egg Timer" \
		--icon build/EggTimer.icns \
		http://e.ggtimer.com/ \
		build


.PHONY: build_app_icon
build_app_icon:
	@mkdir -p build/EggTimer.iconset
	@sips -z 16 16 app.png --out build/EggTimer.iconset/icon_16x16.png
	@sips -z 32 32 app.png --out build/EggTimer.iconset/icon_16x16@2.png
	@sips -z 32 32 app.png --out build/EggTimer.iconset/icon_32x32.png
	@sips -z 64 64 app.png --out build/EggTimer.iconset/icon_32x32@2.png
	@sips -z 64 64 app.png --out build/EggTimer.iconset/icon_64x64.png
	@sips -z 128 128 app.png --out build/EggTimer.iconset/icon_128x128.png
	@sips -z 256 256 app.png --out build/EggTimer.iconset/icon_128x128@2.png
	@sips -z 256 256 app.png --out build/EggTimer.iconset/icon_256x256.png
	@sips -z 512 512 app.png --out build/EggTimer.iconset/icon_256x256@2.png
	@sips -z 512 512 app.png --out build/EggTimer.iconset/icon_512x512.png
	@iconutil -c icns build/EggTimer.iconset
	@rm -R build/EggTimer.iconset

.PHONY: symlink_app
symlink_app:
	ln -s "${HOME}/.homesick/repos/dotfiles/apps/app/build/Egg Timer-darwin-x64/Egg Timer.app" "~/Applications/"
