
.PHONY: build
build:
	@nativefier \
		--name "Buffer" \
		https://buffer.com/ \
		build

	@rsync -a --delete-after \
		./build/Buffer-darwin-x64/Buffer.app/ \
		~/Applications/Buffer.app


# .PHONY: build_buffer_icon
# build_buffer_icon:
# 	@mkdir -p build/Buffer.iconset
# 	@sips -z 16 16 buffer.png --out build/Buffer.iconset/icon_16x16.png
# 	@sips -z 32 32 buffer.png --out build/Buffer.iconset/icon_16x16@2.png
# 	@sips -z 32 32 buffer.png --out build/Buffer.iconset/icon_32x32.png
# 	@sips -z 64 64 buffer.png --out build/Buffer.iconset/icon_32x32@2.png
# 	@sips -z 64 64 buffer.png --out build/Buffer.iconset/icon_64x64.png
# 	@sips -z 128 128 buffer.png --out build/Buffer.iconset/icon_128x128.png
# 	@sips -z 256 256 buffer.png --out build/Buffer.iconset/icon_128x128@2.png
# 	@sips -z 256 256 buffer.png --out build/Buffer.iconset/icon_256x256.png
# 	@sips -z 512 512 buffer.png --out build/Buffer.iconset/icon_256x256@2.png
# 	@sips -z 512 512 buffer.png --out build/Buffer.iconset/icon_512x512.png
# 	@iconutil -c icns build/Buffer.iconset
# 	@rm -R build/Buffer.iconset


# .PHONY: symlink_buffer
# symlink_buffer:
# 	ln -s $HOME/.homesick/repos/dotfiles/apps/buffer/build/Buffer-darwin-x64/Buffer.app ~/Applications/Buffer.app
