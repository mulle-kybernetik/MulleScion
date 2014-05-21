# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = "MulleScion"
  s.version          = '1848.9'
  s.summary          = "MulleScion a modern Template library for ObjC."
  s.description      = <<-DESC
                       MulleScion is indeed a modern Template library for ObjC. 
                       Yes.
                       DESC
  s.homepage         = "http://www.mulle-kybernetik.com/software/git/MulleScion/about"
  # s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'BSD3'
  s.author           = { "Nat!" => "nat@mulle-kybernetik.com" }
  s.source           = { :git => "http://www.mulle-kybernetik.com/repositories/MulleScion", :tag => 'CocoaPods-test' }
  # s.social_media_url = 'https://twitter.com/EXAMPLE'

  s.platform     = :ios, '5.0'
  s.platform     = :osx, '10.4'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.4'
  s.requires_arc = false
  s.compiler_flags = '-Wno-deprecated-declarations', "-DPROJECT_VERSION=#{s.version.to_s}"
  s.source_files = 'src/**/*.{c,m}', 'google-toolbox-for-mac/Foundation/GTMNSString+HTML.m'
  s.public_header_files = 'src/**/*.h', 'google-toolbox-for-mac/GTMDefines.h', 'google-toolbox-for-mac/Foundation/GTMNSString+HTML.h'
  # s.resources = 'Assets/*.png'

  s.ios.exclude_files = 'src/main.m', 'src/mongoose.c', 'src/mongoose.h', 'src/MulleMongoose.h', 'src/MulleMongoose.m', 'src/MulleScionObjectModel+StringReplacement.m', 'src/MulleScionObjectModel+StringReplacement.h'
  s.osx.exclude_files = 'src/main.m', 'src/mongoose.c', 'src/mongoose.h', 'src/MulleMongoose.h', 'src/MulleMongoose.m', 'src/MulleScionObjectModel+StringReplacement.m', 'src/MulleScionObjectModel+StringReplacement.h' 
  # s.frameworks = 'SomeFramework', 'AnotherFramework'
  # s.dependency 'mulle-tidy', '>= 18.49.0'
end
