
.PHONY: build
build: build_mastodon_icon build_mastodon

.PHONY: build_mastodon
build_mastodon:
	@mkdir -p build/Mastodon.iconset
	@nativefier \
		--overwrite \
		--name Mastodon \
		--icon build/Mastodon.icns \
		https://mastodon.social/web/ \
		build

.PHONY: build_mastodon_icon
build_mastodon_icon:
	@mkdir -p build/Mastodon.iconset
	@sips -z 16 16 mastodon.png --out build/Mastodon.iconset/icon_16x16.png
	@sips -z 32 32 mastodon.png --out build/Mastodon.iconset/icon_16x16@2.png
	@sips -z 32 32 mastodon.png --out build/Mastodon.iconset/icon_32x32.png
	@sips -z 64 64 mastodon.png --out build/Mastodon.iconset/icon_32x32@2.png
	@sips -z 64 64 mastodon.png --out build/Mastodon.iconset/icon_64x64.png
	@sips -z 128 128 mastodon.png --out build/Mastodon.iconset/icon_128x128.png
	@sips -z 256 256 mastodon.png --out build/Mastodon.iconset/icon_128x128@2.png
	@sips -z 256 256 mastodon.png --out build/Mastodon.iconset/icon_256x256.png
	@sips -z 512 512 mastodon.png --out build/Mastodon.iconset/icon_256x256@2.png
	@sips -z 512 512 mastodon.png --out build/Mastodon.iconset/icon_512x512.png
	@iconutil -c icns build/Mastodon.iconset
	@rm -R build/Mastodon.iconset
