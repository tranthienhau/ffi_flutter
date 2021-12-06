#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ffi_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ffi_flutter'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.platform = :ios, '8.0'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework opencv2 -all_load' }
  s.ios.vendored_frameworks = 'opencv2.framework'
  # including OpenCV framework
#   s.vendored_frameworks = 'opencv2.framework'
#   s.dependency 'OpenCV2'
  # including native framework
  s.frameworks = 'AVFoundation'

# #   including C++ library
  s.libraries = 'c++'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
