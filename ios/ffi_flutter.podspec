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
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'
  s.preserve_paths = 'opencv2.framework'
#   s.public_header_files  = 'opencv2.framework/Versions/A/Headers/*.h'
  # telling linker to include opencv2 framework
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework opencv2' }

  # including OpenCV framework
  s.vendored_frameworks = 'opencv2.framework'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
