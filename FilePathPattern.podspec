Pod::Spec.new do |s|
  s.name                = "FilePathPattern"
  s.version             = "0.1.1"
  s.summary             = "Regular expression based file path pattern matcher for iOS."
  s.homepage            = "https://github.com/innerfunction/FilePathPattern-ios"
  s.license             = { :type => "Apache", :file => "LICENSE" }
  s.author              = { "Julian Goacher" => "julian.goacher@innerfunction.com" }
  s.platform            = :ios
  s.source              = { :git => "https://github.com/innerfunction/FilePathPattern-ios.git", :tag => "0.1.0" }
  s.source_files        = "IFFilePathPattern.{h,m}"
end
