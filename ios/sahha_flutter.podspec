#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sahha_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sahha_flutter'
  s.version          = '0.3.5'
  s.summary          = 'Sahha Flutter SDK'
  s.description      = 'The Sahha SDK provides a convenient way for Flutter apps to connect to the Sahha API.'
  s.homepage         = 'https://sahha.ai'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sahha' => 'developer@sahha.ai' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Sahha', '0.3.5'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
