# Vestel Multicooker Watch

Bu proje bir watchOS uygulamasıdır. Uygulamayı Xcode ile veya terminal üzerinden simülatörde çalıştırabilirsiniz.

## Gereksinimler

- Xcode kurulu olmalı
- watchOS Simulator açık olmalı

## Xcode ile çalıştırma

1. `VestelMulticookerWatch.xcodeproj` dosyasını Xcode ile açın.
2. Scheme olarak `VestelMulticookerWatch` seçin.
3. Target olarak bir watchOS Simulator seçin.
4. Run düğmesine basın.

## Terminal ile derleme

```zsh
xcodebuild -scheme VestelMulticookerWatch -workspace VestelMulticookerWatch.xcodeproj/project.xcworkspace -destination 'platform=watchOS Simulator,id=AE1A24E5-736D-42DC-8F47-84D1FA506F48' build
```

## Terminal ile simülatörde çalıştırma

Önce uygulama bundle yolunu ayarlayın:

```zsh
APP_PATH="$HOME/Library/Developer/Xcode/DerivedData/VestelMulticookerWatch-fdikuwqjhwdgqqevetzcbgrznhzu/Build/Products/Debug-watchsimulator/VestelMulticookerWatch.app"
BUNDLE_ID="com.berfin.vestelmulticooker.watchkitapp"
```

Sonra uygulamayı simülatöre kurup açın:

```zsh
xcrun simctl install booted "$APP_PATH" && xcrun simctl launch booted "$BUNDLE_ID"
```

## Not

- `APP_PATH` içindeki DerivedData klasörü, Xcode derleme yaptıktan sonra değişebilir.
- Gerekirse doğru yolu bulmak için `find ~/Library/Developer/Xcode/DerivedData -path '*VestelMulticookerWatch.app' -print` komutunu kullanın.
