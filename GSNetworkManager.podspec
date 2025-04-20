#
# Be sure to run `pod lib lint GSNetworkManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GSNetworkManager'
  s.version          = '0.3.0'
  s.summary = "A lightweight and Easy to use Networking Library"
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/megaganjotsingh/GSNetworkManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'megaganjotsingh' => 'megaganjotsingh@gmail.com' }
  s.source           = { :git => 'https://github.com/megaganjotsingh/GSNetworkManager.git', :tag => s.version.to_s }
  s.swift_versions = ['5.0']

  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'

  s.source_files = 'Source/**/*'
  
  # s.resource_bundles = {
  #   'GSNetworkManager' => ['GSNetworkManager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
