
build: build_toggl_icon build_toggl

.PHONY: build_toggl
build_toggl:
	@mkdir -p build/Toggl.iconset
	@nativefier \
		--overwrite \
		--name "Toggl" \
		--icon build/Toggl.icns \
		--tray \
		https://www.toggl.com/app \
		build

.PHONY: build_toggl_icon
build_toggl_icon:
	@if [ ! -f build/toggl.png ]; then \
		@curl https://raw.githubusercontent.com/jiahaog/nativefier-icons/gh-pages/files/toggl.png > build/toggl.png ; \
	fi;

	@if [ ! -f build/Toggl.icns ]; then \
		@curl https://raw.githubusercontent.com/jiahaog/nativefier-icons/gh-pages/files/toggl.icns > build/Toggl.icns ; \
	fi;
