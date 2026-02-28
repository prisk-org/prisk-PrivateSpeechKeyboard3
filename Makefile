# Prisk Makefile
# Usage: make <target>

SCHEME       = Prisk
PROJECT      = Prisk.xcodeproj
SIMULATOR    = platform=iOS Simulator,name=iPhone 16,OS=latest
DERIVED_DATA = /Volumes/KIOXIA-512GB-20250803/DerivedData/Prisk
XCODEGEN     = /opt/homebrew/bin/xcodegen

.PHONY: gen build test clean open help

## Generate Xcode project from project.yml
gen:
	$(XCODEGEN) generate

## Open Xcode project
open: gen
	open $(PROJECT)

## Build (requires gen first)
build:
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(SIMULATOR)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
		| xcpretty

## Run unit tests
test:
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(SIMULATOR)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		-only-testing STTEngineTests \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
		| xcpretty

## Clean derived data
clean:
	rm -rf "$(DERIVED_DATA)"

## Full cycle: gen → build → test
all: gen build test

help:
	@grep -E '^##' Makefile | sed 's/## /  /'
