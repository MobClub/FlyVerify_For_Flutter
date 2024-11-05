#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flyverify_plugin'
  s.version          = '1.0.1'
  s.summary          = 'flyverify for flutter.'
  s.description      = <<-DESC
                        flyverify for flutter.
                       DESC
  s.homepage         = 'http://www.mob.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'MobTech' => 'mobtechsdks@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'FlyVerify'
  s.static_framework = true
  s.ios.deployment_target = '9.0'
end

