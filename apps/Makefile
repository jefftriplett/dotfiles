# asana
# buffer
# grammarly
# mastodon
# myfitnesspal
# noisli
# overcast
# pablo
# plex
# toggl
# tweetdeck

# office 365 outlook

# https://raw.githubusercontent.com/webcatalog/webcatalog-apps/master/apps/myfitnesspal/myfitnesspal.yml
# https://raw.githubusercontent.com/webcatalog/webcatalog-apps/master/apps/myfitnesspal/myfitnesspal-icon.png


define build_app
	$(call build_iconset $(1),$(2),$(3))
	$(call build_nativefier $(1),$(2),$(3))
endef

define build_iconset
	@echo '$(1)'
	@mkdir -p "build/$(1).iconset"
	@sips -z 16 16 $(1).png --out build/$(1).iconset/icon_16x16.png
	@sips -z 32 32 $(1).png --out build/$(1).iconset/icon_16x16@2x.png
	@sips -z 24 24 $(1).png --out build/$(1).iconset/icon_24x24.png
	@sips -z 32 32 $(1).png --out build/$(1).iconset/icon_32x32.png
	@sips -z 64 64 $(1).png --out build/$(1).iconset/icon_32x32@2x.png
	@sips -z 48 48 $(1).png --out build/$(1).iconset/icon_48x48.png
	@sips -z 64 64 $(1).png --out build/$(1).iconset/icon_64x64.png
	@sips -z 128 128 $(1).png --out build/$(1).iconset/icon_128x128.png
	@sips -z 256 256 $(1).png --out build/$(1).iconset/icon_128x128@2x.png
	@sips -z 256 256 $(1).png --out build/$(1).iconset/icon_256x256.png
	@sips -z 512 512 $(1).png --out build/$(1).iconset/icon_256x256@2x.png
	@sips -z 512 512 $(1).png --out build/$(1).iconset/icon_512x512.png
	@sips -z 1024 1024 $(1).png --out build/$(1).iconset/icon_512x512@2x.png
	@sips -z 1024 1024 $(1).png --out build/$(1).iconset/icon_1024x1024.png
	@iconutil -c icns build/$(1).iconset -o build/$(1).icns
	# @rm -R build/$(1).iconset
endef


define build_nativefier
	@mkdir -p build/Buffer.iconset
	@nativefier \
		--overwrite \
		--name $(2) \
		--icon $(1)/$(1).icns \
		$(3) \
		build
endef


.PHONY: build
build:
	$(call build_app,"buffer","Buffer","https://buffer.com/")
	$(call build_app,"toggl","Toggl","https://www.toggl.com/app")


testing:
	# $(call create_app,asana)
	# $(call create_app,grammarly)
	# $(call create_app,mastodon)
	# $(call create_app,myfitnesspal)
	# $(call create_app,noisli)
	# $(call create_app,overcast)
	# $(call create_app,pablo)
	# $(call create_app,plex)
	# $(call create_app,toggl)
	# $(call create_app,tweetdeck)
