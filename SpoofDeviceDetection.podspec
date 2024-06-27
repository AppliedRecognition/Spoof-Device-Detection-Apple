Pod::Spec.new do |spec|

  spec.name = "SpoofDeviceDetection"
  spec.version = "1.0.0"
  spec.summary = "Spoof device detection for iOS"

  spec.description = "iOS library that detects presentation attacks that use devices with screens"

  spec.homepage = "https://github.com/AppliedRecognition/Spoof-Device-Detection-Apple"
  spec.license = { :type => "Commercial", :file => "LICENCE.txt" }
  
  spec.author = "Jakub Dolejs"
  
  spec.platform = :ios, "13.0"
  spec.swift_versions = ["5.5", "5.6", "5.7", "5.8", "5.9", "5.10"]
  
  spec.source = { :git => "https://github.com/AppliedRecognition/Spoof-Device-Detection-Apple.git", :tag => "#{spec.version}" }
  
  spec.dependency "LivenessDetectionCore", "~> 1.0"

  default_subspecs = 'Core'
  
  spec.subspec 'Core' do |core|
    core.source_files = "Sources/SpoofDeviceDetection/*.swift"
  end
  
  spec.subspec 'Model' do |full|
    full.source_files = 'Sources/SpoofDeviceDetectionModel/*.swift'
    full.resource_bundles = {
        "SpoofDeviceDetectionModel" => ["Sources/SpoofDeviceDetectionModel/Resources/*.*"]
    }
    full.dependency    "SpoofDeviceDetection/Core"
    full.module_name = "SpoofDeviceDetectionModel"
  end

end
