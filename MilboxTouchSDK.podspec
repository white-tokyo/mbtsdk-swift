Pod::Spec.new do |s|

s.name         = "MilboxTouchSDK"
s.version      = "1.0.1"
s.summary      = "MilboxTouch sdk for ios."
s.homepage     = "https://github.com/white-tokyo/mbtsdk-swift"
s.license      = { :type => "MIT", :file => "LICENSE" }
s.authors      = { 'moajo' => 't.ohtani@giftedagent.com' }
s.platform     = :ios, "8.0"
s.ios.deployment_target = "8.0"
s.source       = { :git => "https://github.com/white-tokyo/mbtsdk-swift.git", :tag => s.version }
s.source_files  = "MilboxTouch/*.swift"
s.requires_arc = true

end
