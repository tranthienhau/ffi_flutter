#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_add.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_add'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'chauvansang97@gmail.com' }
  s.source           = { :path => '.' }
  s.static_framework = true
  s.platform = :ios, '8.0'
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'NSLogger'
  s.public_header_files = 'Classes/Curl/*.h', '../cpp/general/general_funtion.h'

  s.vendored_libraries = 'Classes/Framework/libcurl.a'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' 'arm64' 'x86_64' }
  s.swift_version = '5.0'
  # telling CocoaPods not to remove framework
  s.preserve_paths = 'opencv2.framework'
#   s.public_header_files  = 'opencv2.framework/Versions/A/Headers/*.h'
  # telling linker to include opencv2 framework
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework opencv2' }

  # including OpenCV framework
  s.vendored_frameworks = 'opencv2.framework'

  # including native framework
  s.frameworks = 'AVFoundation'

#   including C++ library
  s.library = 'c++'
end
