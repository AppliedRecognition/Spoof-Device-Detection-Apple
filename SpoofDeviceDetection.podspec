Pod::Spec.new do |spec|

  spec.name = "SpoofDeviceDetection"
  spec.version = "1.0.0"
  spec.summary = "Spoof device detection for iOS"

  spec.description = "iOS library that detects presentation attacks that use devices with screens"

  spec.homepage = "https://github.com/AppliedRecognition/Spoof-Device-Detection-Apple"
  spec.license = { :type => "Commercial", :file => "LICENCE.txt" }
  
  spec.author = "Jakub Dolejs"
  
  spec.platform = :ios, "13.0"
  spec.swift_version = "5.0"
  
  spec.source = { :git => "https://github.com/AppliedRecognition/Spoof-Device-Detection-Apple.git", :tag => "#{spec.version}" }
  
  spec.dependency "LivenessDetection", "~> 1.0"

  default_subspecs = 'Core'
  
  spec.subspec 'Core' do |core|
    core.source_files = "Sources/SpoofDeviceDetection/*.swift"
  end
  
  spec.subspec 'Full' do |full|
    full.source_files = 'Sources/SpoofDeviceDetectionFull/*.swift'
    full.resource_bundles = {
        "SpoofDeviceDetectionFull" => ["Sources/SpoofDeviceDetectionFull/Resources/*.*"]
    }
    full.dependency    "SpoofDeviceDetection/Core"
  end

end
