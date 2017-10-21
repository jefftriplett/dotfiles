
build: build_toggl_icon build_toggl

.PHONY: build_toggl
build_toggl:
	@mkdir -p build/Toggl.iconset
	@nativefier \
		--overwrite \
		--name Toggl \
		--icon build/Toggl.icns \
		https://www.toggl.com/app \
		build

.PHONY: build_toggl_icon
build_toggl_icon:
	@mkdir -p build/Toggl.iconset
	@sips -z 16 16 toggl.png --out build/Toggl.iconset/icon_16x16.png
	@sips -z 32 32 toggl.png --out build/Toggl.iconset/icon_16x16@2.png
	@sips -z 32 32 toggl.png --out build/Toggl.iconset/icon_32x32.png
	@sips -z 64 64 toggl.png --out build/Toggl.iconset/icon_32x32@2.png
	@sips -z 64 64 toggl.png --out build/Toggl.iconset/icon_64x64.png
	@sips -z 128 128 toggl.png --out build/Toggl.iconset/icon_128x128.png
	@sips -z 256 256 toggl.png --out build/Toggl.iconset/icon_128x128@2.png
	@sips -z 256 256 toggl.png --out build/Toggl.iconset/icon_256x256.png
	@sips -z 512 512 toggl.png --out build/Toggl.iconset/icon_256x256@2.png
	@sips -z 512 512 toggl.png --out build/Toggl.iconset/icon_512x512.png
	@iconutil -c icns build/Toggl.iconset
	@rm -R build/Toggl.iconset
