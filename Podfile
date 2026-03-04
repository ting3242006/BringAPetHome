platform :ios, '17.0'

target 'BringAPetHome' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for BringAPetHome

pod 'SwiftLint'
pod 'Firebase/Auth', '~> 12.10'
pod 'Firebase/Firestore', '~> 12.10'
pod 'Firebase/Storage', '~> 12.10'
pod 'Firebase/Database', '~> 12.10'
pod 'Kingfisher'
pod 'IQKeyboardManagerSwift'
pod 'lottie-ios'
pod 'Firebase/Crashlytics', '~> 12.10'
pod 'MJRefresh'


post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end

  # Xcode 26 + old BoringSSL-GRPC can inject an invalid flag:
  # "-GCC_WARN_INHIBIT_ALL_WARNINGS" (parsed as unsupported "-G").
  # Strip it after each pod install so Pods can compile.
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      deployment_target = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if deployment_target.nil? || Gem::Version.new(deployment_target) < Gem::Version.new('17.0')
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      end
    end

    next unless target.name == 'BoringSSL-GRPC'

    target.source_build_phase.files.each do |file|
      next unless file.settings && file.settings['COMPILER_FLAGS']

      flags = file.settings['COMPILER_FLAGS'].split
      flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
      file.settings['COMPILER_FLAGS'] = flags.join(' ')
    end
  end
end

end
