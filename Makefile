FLUTTER := fvm flutter
# Shorebird bundles its own Flutter, so it is invoked directly (not via fvm).
SHOREBIRD := shorebird
MAIN_DEV := lib/main_dev.dart
MAIN_PROD := lib/main_prod.dart
DEFINES_DEV := --dart-define-from-file=config/dev.json
DEFINES_PROD := --dart-define-from-file=config/prod.json

.PHONY: \
	setup-ios \
	run-dev run-prod \
	build-apk-dev build-apk-prod \
	build-aab-dev build-aab-prod \
	build-ios-dev build-ios-prod \
	build-ipa-dev build-ipa-prod \
	analyze-app \
	run-app build-apk build-aab build-ios build-ipa build-app-split \
	shorebird-release-ios-dev shorebird-release-ios-prod \
	shorebird-release-android-dev shorebird-release-android-prod \
	shorebird-patch-ios-dev shorebird-patch-ios-prod \
	shorebird-patch-android-dev shorebird-patch-android-prod \
	shorebird-release shorebird-patch \
	clean-get

setup-ios:
	./scripts/setup_ios.sh

run-dev:
	$(FLUTTER) run --flavor dev -t $(MAIN_DEV) $(DEFINES_DEV)

run-prod:
	$(FLUTTER) run --flavor prod -t $(MAIN_PROD) $(DEFINES_PROD)

build-apk-dev:
	$(FLUTTER) build apk --flavor dev -t $(MAIN_DEV) $(DEFINES_DEV)

build-apk-prod:
	$(FLUTTER) build apk --flavor prod -t $(MAIN_PROD) $(DEFINES_PROD)

build-aab-dev:
	$(FLUTTER) build appbundle --flavor dev -t $(MAIN_DEV) $(DEFINES_DEV)

build-aab-prod:
	$(FLUTTER) build appbundle --flavor prod -t $(MAIN_PROD) $(DEFINES_PROD)

build-ios-dev:
	$(FLUTTER) build ios --debug --flavor dev -t $(MAIN_DEV) $(DEFINES_DEV)

build-ios-prod:
	$(FLUTTER) build ios --debug --flavor prod -t $(MAIN_PROD) $(DEFINES_PROD)

build-ipa-dev:
	$(FLUTTER) build ipa --flavor dev -t $(MAIN_DEV) $(DEFINES_DEV)

build-ipa-prod:
	$(FLUTTER) build ipa --flavor prod -t $(MAIN_PROD) $(DEFINES_PROD)

analyze-app:
	$(FLUTTER) build apk --flavor dev -t $(MAIN_DEV) $(DEFINES_DEV) --analyze-size --target-platform=android-arm64

run-app:
	@read -p "Enter FLAVOR (dev or prod): " FLAVOR; \
	case $$FLAVOR in \
		dev) TARGET="$(MAIN_DEV)"; DEFINES="$(DEFINES_DEV)" ;; \
		prod) TARGET="$(MAIN_PROD)"; DEFINES="$(DEFINES_PROD)" ;; \
		*) echo "Invalid flavor '$$FLAVOR'. Use dev or prod."; exit 1 ;; \
	esac; \
	echo "Running Flutter with flavor: $$FLAVOR and target: $$TARGET"; \
	$(FLUTTER) run --flavor $$FLAVOR -t $$TARGET $$DEFINES

build-apk:
	@read -p "Enter FLAVOR (dev or prod): " FLAVOR; \
	case $$FLAVOR in \
		dev) TARGET="$(MAIN_DEV)"; DEFINES="$(DEFINES_DEV)" ;; \
		prod) TARGET="$(MAIN_PROD)"; DEFINES="$(DEFINES_PROD)" ;; \
		*) echo "Invalid flavor '$$FLAVOR'. Use dev or prod."; exit 1 ;; \
	esac; \
	echo "Building APK with flavor: $$FLAVOR and target: $$TARGET"; \
	$(FLUTTER) build apk --flavor $$FLAVOR -t $$TARGET $$DEFINES

build-aab:
	@read -p "Enter FLAVOR (dev or prod): " FLAVOR; \
	case $$FLAVOR in \
		dev) TARGET="$(MAIN_DEV)"; DEFINES="$(DEFINES_DEV)" ;; \
		prod) TARGET="$(MAIN_PROD)"; DEFINES="$(DEFINES_PROD)" ;; \
		*) echo "Invalid flavor '$$FLAVOR'. Use dev or prod."; exit 1 ;; \
	esac; \
	echo "Building AAB with flavor: $$FLAVOR and target: $$TARGET"; \
	$(FLUTTER) build appbundle --flavor $$FLAVOR -t $$TARGET $$DEFINES

build-ios:
	@read -p "Enter FLAVOR (dev or prod): " FLAVOR; \
	case $$FLAVOR in \
		dev) TARGET="$(MAIN_DEV)"; DEFINES="$(DEFINES_DEV)" ;; \
		prod) TARGET="$(MAIN_PROD)"; DEFINES="$(DEFINES_PROD)" ;; \
		*) echo "Invalid flavor '$$FLAVOR'. Use dev or prod."; exit 1 ;; \
	esac; \
	echo "Building iOS app with flavor: $$FLAVOR and target: $$TARGET"; \
	$(FLUTTER) build ios --debug --flavor $$FLAVOR -t $$TARGET $$DEFINES

build-ipa:
	@read -p "Enter FLAVOR (dev or prod): " FLAVOR; \
	case $$FLAVOR in \
		dev) TARGET="$(MAIN_DEV)"; DEFINES="$(DEFINES_DEV)" ;; \
		prod) TARGET="$(MAIN_PROD)"; DEFINES="$(DEFINES_PROD)" ;; \
		*) echo "Invalid flavor '$$FLAVOR'. Use dev or prod."; exit 1 ;; \
	esac; \
	echo "Building IPA with flavor: $$FLAVOR and target: $$TARGET"; \
	$(FLUTTER) build ipa --flavor $$FLAVOR -t $$TARGET $$DEFINES

build-app-split:
	@read -p "Enter FLAVOR (dev or prod): " FLAVOR; \
	case $$FLAVOR in \
		dev) TARGET="$(MAIN_DEV)"; DEFINES="$(DEFINES_DEV)" ;; \
		prod) TARGET="$(MAIN_PROD)"; DEFINES="$(DEFINES_PROD)" ;; \
		*) echo "Invalid flavor '$$FLAVOR'. Use dev or prod."; exit 1 ;; \
	esac; \
	echo "Building split APK with flavor: $$FLAVOR and target: $$TARGET"; \
	$(FLUTTER) build apk --flavor $$FLAVOR -t $$TARGET $$DEFINES --obfuscate --split-debug-info=build/app/outputs/symbols

# --- Shorebird (code push) ---
# `--flavor`/`--target` are Shorebird options and stay before `--`; everything
# after `--` (the dart-defines) is forwarded to the underlying `flutter build`.
# A patch MUST use the same target + defines as the release it patches.

shorebird-release-ios-dev:
	$(SHOREBIRD) release ios --flavor dev --target $(MAIN_DEV) $(DEFINES_DEV)

shorebird-release-ios-prod:
	$(SHOREBIRD) release ios --flavor prod --target $(MAIN_PROD) $(DEFINES_PROD)

shorebird-release-android-dev:
	$(SHOREBIRD) release android --flavor dev --target $(MAIN_DEV) $(DEFINES_DEV)

shorebird-release-android-prod:
	$(SHOREBIRD) release android --flavor prod --target $(MAIN_PROD) $(DEFINES_PROD)

shorebird-patch-ios-dev:
	$(SHOREBIRD) patch ios --flavor dev --target $(MAIN_DEV) $(DEFINES_DEV)

shorebird-patch-ios-prod:
	$(SHOREBIRD) patch ios --flavor prod --target $(MAIN_PROD) $(DEFINES_PROD)

shorebird-patch-android-dev:
	$(SHOREBIRD) patch android --flavor dev --target $(MAIN_DEV) $(DEFINES_DEV)

shorebird-patch-android-prod:
	$(SHOREBIRD) patch android --flavor prod --target $(MAIN_PROD) $(DEFINES_PROD)

shorebird-release:
	@read -p "Enter PLATFORM (ios or android): " PLATFORM; \
	read -p "Enter FLAVOR (dev or prod): " FLAVOR; \
	case $$FLAVOR in \
		dev) TARGET="$(MAIN_DEV)"; DEFINES="$(DEFINES_DEV)" ;; \
		prod) TARGET="$(MAIN_PROD)"; DEFINES="$(DEFINES_PROD)" ;; \
		*) echo "Invalid flavor '$$FLAVOR'. Use dev or prod."; exit 1 ;; \
	esac; \
	case $$PLATFORM in \
		ios|android) ;; \
		*) echo "Invalid platform '$$PLATFORM'. Use ios or android."; exit 1 ;; \
	esac; \
	echo "Shorebird release $$PLATFORM with flavor: $$FLAVOR and target: $$TARGET"; \
	$(SHOREBIRD) release $$PLATFORM --flavor $$FLAVOR --target $$TARGET $(DEFINES)

shorebird-patch:
	@read -p "Enter PLATFORM (ios or android): " PLATFORM; \
	read -p "Enter FLAVOR (dev or prod): " FLAVOR; \
	case $$FLAVOR in \
		dev) TARGET="$(MAIN_DEV)"; DEFINES="$(DEFINES_DEV)" ;; \
		prod) TARGET="$(MAIN_PROD)"; DEFINES="$(DEFINES_PROD)" ;; \
		*) echo "Invalid flavor '$$FLAVOR'. Use dev or prod."; exit 1 ;; \
	esac; \
	case $$PLATFORM in \
		ios|android) ;; \
		*) echo "Invalid platform '$$PLATFORM'. Use ios or android."; exit 1 ;; \
	esac; \
	echo "Shorebird patch $$PLATFORM with flavor: $$FLAVOR and target: $$TARGET"; \
	$(SHOREBIRD) patch $$PLATFORM --flavor $$FLAVOR --target $$TARGET $(DEFINES)

clean-get:
	$(FLUTTER) clean && $(FLUTTER) pub get
