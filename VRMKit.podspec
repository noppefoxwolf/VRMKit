Pod::Spec.new do |s|
  s.name             = 'VRMKit'
  s.version          = '0.4.0'
  s.summary          = 'VRM loader and VRM renderer'

  s.description      = <<-DESC
VRM loader and VRM renderer.

VRMKit can read VRM metadata and show the 3D models.
                       DESC

  s.homepage         = 'https://github.com/tattn/VRMKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'git' => 'tanakasan2525@gmail.com' }
  s.source           = { :git => 'https://github.com/tattn/VRMKit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tanakasan2525'

  s.swift_versions = ['5.1']
  s.ios.deployment_target = '11.0'

  s.source_files = 'Sources/VRMKit/**/*.{swift,h}'
  
  s.public_header_files = 'Sources/VRMKit/**/*.h'
  s.frameworks = 'Foundation'
end
