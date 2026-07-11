# SPM Migration Plan

## Goal

Move the app target from CocoaPods to Swift Package Manager while keeping the current Firebase-backed features intact.

## Package Mapping

- Firebase/Auth -> `FirebaseAuth` from `https://github.com/firebase/firebase-ios-sdk.git`
- Firebase/Firestore -> `FirebaseFirestore` from `https://github.com/firebase/firebase-ios-sdk.git`
- Firebase/Storage -> `FirebaseStorage` from `https://github.com/firebase/firebase-ios-sdk.git`
- Firebase/Database -> `FirebaseDatabase` from `https://github.com/firebase/firebase-ios-sdk.git`
- Firebase/Crashlytics -> `FirebaseCrashlytics` from `https://github.com/firebase/firebase-ios-sdk.git`
- Kingfisher -> `Kingfisher` from `https://github.com/onevcat/Kingfisher.git`
- IQKeyboardManagerSwift -> `IQKeyboardManagerSwift` from `https://github.com/hackiftekhar/IQKeyboardManager.git`
- lottie-ios -> `Lottie` from `https://github.com/airbnb/lottie-spm.git`
- MJRefresh -> `MJRefresh` from `https://github.com/CoderMJLee/MJRefresh.git`
- SwiftLint -> `SwiftLintPlugins` from `https://github.com/SimplyDanny/SwiftLintPlugins.git`

## Steps

1. Remove CocoaPods build settings, framework links, workspace references, and generated build phases.
2. Add SPM package references and app target package product dependencies.
3. Update Crashlytics and SwiftLint run scripts to use Swift Package checkouts/artifacts.
4. Resolve packages and build the app from the Xcode project.

## Verification

- `xcodebuild -resolvePackageDependencies -project BringAPetHome.xcodeproj -scheme BringAPetHome`
- `xcodebuild -project BringAPetHome.xcodeproj -scheme BringAPetHome -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`

## Result

- CocoaPods project wiring was removed.
- `BringAPetHome.xcworkspace` was removed after confirming the project builds directly from `BringAPetHome.xcodeproj`.
- `Podfile` and `Podfile.lock` were removed.
- Firebase-backed features remain linked through Swift Package Manager products.
- Build verification passed after replacing CocoaPods-era `import Firebase` umbrella imports with explicit Firebase module imports.
