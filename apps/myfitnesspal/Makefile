
build: build_myfitnesspal_icon build_myfitnesspal

.PHONY: build_myfitnesspal
build_myfitnesspal:
	@mkdir -p build/MyFitnessPal.iconset
	@nativefier \
		--overwrite \
		--name MyFitnessPal \
		--icon build/MyFitnessPal.icns \
		http://www.myfitnesspal.com/ \
		build

.PHONY: build_myfitnesspal_icon
build_myfitnesspal_icon:
	@mkdir -p build/MyFitnessPal.iconset
	@sips -z 16 16 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_16x16.png
	@sips -z 32 32 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_16x16@2.png
	@sips -z 32 32 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_32x32.png
	@sips -z 64 64 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_32x32@2.png
	@sips -z 64 64 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_64x64.png
	@sips -z 128 128 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_128x128.png
	@sips -z 256 256 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_128x128@2.png
	@sips -z 256 256 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_256x256.png
	@sips -z 512 512 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_256x256@2.png
	@sips -z 512 512 myfitnesspal.png --out build/MyFitnessPal.iconset/icon_512x512.png
	@iconutil -c icns build/MyFitnessPal.iconset
	@rm -R build/MyFitnessPal.iconset
