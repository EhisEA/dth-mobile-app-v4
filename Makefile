FLUTTER := fvm flutter
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

clean-get:
	$(FLUTTER) clean && $(FLUTTER) pub get
