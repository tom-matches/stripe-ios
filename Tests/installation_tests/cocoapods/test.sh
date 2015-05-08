#!/bin/sh

echo "Checking test Cocoapods app..."
cd $(dirname $0)
rm -rf Pods
rm Podfile.lock
pod install && set -o pipefail && xctool build -workspace CocoapodsTest.xcworkspace -scheme CocoapodsTest -sdk iphonesimulator -configuration Release ONLY_ACTIVE_ARCH=NO ARCHS=x86_64
