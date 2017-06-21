Pod::Spec.new do |s|
  s.name             = "MulleScion"
  s.version          = '1858.1'
  s.summary          = "MulleScion a modern Template library for ObjC."
  s.description      = <<-DESC
                       MulleScion is indeed a modern Template library for ObjC.
                       Yes.
                       DESC
  s.homepage         = "http://www.mulle-kybernetik.com/software/git/MulleScion/about"
  s.screenshots      = "docx/MulleScionTemplatesDataFlow.png", "docx/MulleScionDataFlow.png"
  s.license          = 'BSD3'
  s.author           = { "Nat!" => "nat@mulle-kybernetik.com" }
  s.source           = { :git => "https://github.com/mulle-nat/MulleScion.git", :tag => '#{s.version.to_s}' }

  s.platform              = :ios, '5.0'
  s.platform              = :osx, '10.6'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.6'
  s.requires_arc          = false
  s.compiler_flags        = '-Wno-deprecated-declarations', "-DPROJECT_VERSION=#{s.version.to_s}"
  s.source_files          = 'src/**/*.{h,m,c}'

  s.ios.exclude_files     = 'src/main.m', 'src/mongoose.c', 'src/mongoose.h', 'src/MulleMongoose.h', 'src/MulleMongoose.m', 'src/MulleScionObjectModel+StringReplacement.m', 'src/MulleScionObjectModel+StringReplacement.h', "src/hoedown/*", "src/mongoose/*"
  s.osx.exclude_files     = 'src/main.m', 'src/mongoose.c', 'src/mongoose.h', 'src/MulleMongoose.h', 'src/MulleMongoose.m', 'src/MulleScionObjectModel+StringReplacement.m', 'src/MulleScionObjectModel+StringReplacement.h', "src/hoedown/*", "src/mongoose/*"
  s.library               = "z"
  s.dependency            'GoogleToolboxForMac/NSString+HTML', '2.0.0'
end
