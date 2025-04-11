//
//  SpoofDeviceDetector.swift
//  LivenessDetection
//
//  Created by Jakub Dolejs on 03/02/2023.
//

import Foundation
import UIKit
import Vision
import CoreML
import LivenessDetection

/// Spoof device detection
///
/// Detect spoof devices like smartphones, tablets or photographs
/// - Since: 1.0.0
@available(iOS 13, *)
public class SpoofDeviceDetector: SpoofDetector {
    
    var maxSideLength: CGFloat = 4000
    
    let model: VNCoreMLModel
    let computeUnits: MLComputeUnits
    let modelVersion: String?
    
    lazy var request: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: self.model)
        request.imageCropAndScaleOption = .scaleFit
        return request
    }()
    
    /// This task is launched in the initializer. It times inference on a dummy input. If the task times out the hardware is too slow to be responsive.
    private lazy var capabilityCheckTask: Task<Bool, Never> = {
        Task.detached(priority: .background) { [self] in
            await self.runTimedInference()
        }
    }()
    /// Check the output of the device capability check. If the value is `false` the hardware is too slow to run inference responsively. If that's the case the detection
    /// function returns as if no spoof devices were detected. This is a graceful way to exit on devices incapable of running the ML model inference fast enough.
    private func isDeviceCapable() async -> Bool {
        await self.capabilityCheckTask.value
    }
    
    /// Asynchronous constructor
    /// - Parameter modelURL: Model file URL
    /// - Since: 1.0.0
    @available(iOS 16, macOS 13, macCatalyst 16, *)
    public convenience init(modelURL: URL, configuration: MLModelConfiguration? = nil) async throws {
        let compiledModelURL = try await MLModel.compileModel(at: modelURL)
        try await self.init(compiledModelURL: compiledModelURL, identifier: modelURL.lastPathComponent, configuration: configuration)
    }
    
    /// Constructor
    /// - Parameter modelURL: Model file URL
    /// - Since: 1.0.0
    public convenience init(modelURL: URL, configuration: MLModelConfiguration? = nil) throws {
        let compiledModelURL = try MLModel.compileModel(at: modelURL)
        try self.init(compiledModelURL: compiledModelURL, identifier: modelURL.lastPathComponent, configuration: configuration)
    }
    
    /// Constructor
    /// - Parameters:
    ///   - compiledModelURL: URL of the compiled model file
    ///   - identifier: Model identifier
    /// - Since: 1.0.0
    public init(compiledModelURL: URL, identifier: String, configuration: MLModelConfiguration? = nil) throws {
        let spoofDetector: MLModel = try MLModel(contentsOf: compiledModelURL, configuration: configuration ?? .init())
        self.computeUnits = spoofDetector.configuration.computeUnits
        self.modelVersion = spoofDetector.modelDescription.metadata[.versionString] as? String
        self.model = try VNCoreMLModel(for: spoofDetector)
        self.identifier = identifier
        _ = self.capabilityCheckTask
    }
    
    @available(iOS 16, macOS 13, macCatalyst 16, *)
    /// Constructor
    /// - Parameters:
    ///   - compiledModelURL: URL of the compiled model file
    ///   - identifier: Model identifier
    /// - Since: 1.1.0
    public init(compiledModelURL: URL, identifier: String, configuration: MLModelConfiguration? = nil) async throws {
        let spoofDetector: MLModel = try MLModel(contentsOf: compiledModelURL, configuration: configuration ?? .init())
        self.computeUnits = spoofDetector.configuration.computeUnits
        self.modelVersion = spoofDetector.modelDescription.metadata[.versionString] as? String
        self.model = try VNCoreMLModel(for: spoofDetector)
        self.identifier = identifier
        _ = self.capabilityCheckTask
    }
    
    // MARK: - SpoofDetector
    
    public let identifier: String
    
    public var confidenceThreshold: Float = 0.5
    
    @available(iOS 15, *)
    public func detectSpoofInImage(_ image: UIImage, regionOfInterest roi: CGRect?) async throws -> Float {
        if await !self.isDeviceCapable() {
            return 0
        }
        var spoofDevices = try await self.detectSpoofDevicesInImage(image)
        if let centreX = roi?.midX, let centreY = roi?.midY {
            let roiCentre = CGPoint(x: centreX, y: centreY)
            spoofDevices = spoofDevices.filter({ $0.boundingBox.contains(roiCentre) })
        }
        return spoofDevices.max(by: { $0.confidence < $1.confidence })?.confidence ?? 0
    }
    
    @available(iOS, introduced: 13.0, obsoleted: 15.0)
    public func detectSpoofInImage(_ image: UIImage, regionOfInterest roi: CGRect?) throws -> Float {
        var spoofDevices = try self._detectSpoofDevicesInImage(image)
        if let centreX = roi?.midX, let centreY = roi?.midY {
            let roiCentre = CGPoint(x: centreX, y: centreY)
            spoofDevices = spoofDevices.filter({ $0.boundingBox.contains(roiCentre) })
        }
        return spoofDevices.max(by: { $0.confidence < $1.confidence })?.confidence ?? 0
    }
    
    /// Detect spoof devices in image
    /// - Parameter image: Image
    /// - Returns: Array of detected spoof devices
    /// - Since: 1.0.0
    @available(iOS 15, *)
    public func detectSpoofDevicesInImage(_ image: UIImage) async throws -> [DetectedSpoof] {
        if await !self.isDeviceCapable() {
            return []
        }
        return try self._detectSpoofDevicesInImage(image)
    }
    
    /// Detect spoof devices in image
    /// - Parameter image: image
    /// - Returns: Array of detected spoof devices
    /// - Since: 1.1.0
    @available(iOS, introduced: 13.0, obsoleted: 15.0)
    public func detectSpoofDevicesInImage(_ image: UIImage) throws -> [DetectedSpoof] {
        return try self._detectSpoofDevicesInImage(image)
    }
    
    /// Time a dummy inference run with default timeout of 2 seconds
    private func runTimedInference(timeout: TimeInterval = 2.0) async -> Bool {
        do {
            let osVersion = await UIDevice.current.systemVersion
            // Use cached result from UserDefaults if available
            if let data = UserDefaults.standard.data(forKey: "speedCheckResult"),
                let speedCheckResult = try? JSONDecoder().decode(SpeedCheckResult.self, from: data),
                speedCheckResult.osVersion == osVersion, speedCheckResult.date.timeIntervalSinceNow < 7*24*60*60,
                self.computeUnits == speedCheckResult.computeUnits,
                self.modelVersion == speedCheckResult.modelVersion {
                return speedCheckResult.isFastEnough
            }
            let result = try await withThrowingTaskGroup(of: Bool.self) { group in
                group.addTask {
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 1.0
                    let size = CGSize(width: 2000, height: 3000)
                    let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
                        UIColor.black.setFill()
                        context.fill(CGRect(origin: .zero, size: size))
                    }
                    _ = try self._detectSpoofDevicesInImage(image)
                    return true
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    throw CancellationError()
                }
                return try await group.next() ?? false
            }
            // Cache the result
            if let cache = try? JSONEncoder().encode(SpeedCheckResult(osVersion: osVersion, date: Date(), isFastEnough: result, computeUnits: self.computeUnits, modelVersion: self.modelVersion)) {
                UserDefaults.standard.setValue(cache, forKey: "speedCheckResult")
            }
            return result
        } catch {
            return false
        }
    }
    
    private func _detectSpoofDevicesInImage(_ image: UIImage) throws -> [DetectedSpoof] {
        let longerSide = max(image.size.width, image.size.height)
        var scaleTransform: CGAffineTransform = .identity
        var scaledImage = image
        if longerSide > self.maxSideLength {
            let scale = self.maxSideLength / longerSide
            scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            var scaledSize = image.size.applying(scaleTransform)
            scaledSize = CGSize(width: round(scaledSize.width), height: round(scaledSize.height))
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            scaledImage = UIGraphicsImageRenderer(size: scaledSize, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: scaledSize))
            }
        }
        guard let cgImage = scaledImage.cgImage else {
            throw ImageProcessingError.cgImageConversionError
        }
        let orientation = scaledImage.imageOrientation.cgImagePropertyOrientation
        try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([self.request])
        let results = (self.request.results as? [VNRecognizedObjectObservation])?.map { DetectedSpoof(observation: $0, imageSize: image.size) } ?? []
        let invertedScaleTransform: CGAffineTransform
        if !scaleTransform.isIdentity {
            invertedScaleTransform = scaleTransform.inverted()
        } else {
            invertedScaleTransform = .identity
        }
        return results.map { result in
            if !invertedScaleTransform.isIdentity {
                return DetectedSpoof(boundingBox: result.boundingBox.applying(invertedScaleTransform), confidence: result.confidence)
            }
            return result
        }.filter { $0.confidence > 0 }
    }
}

fileprivate extension UIImage.Orientation {
    
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
    
    var isMirrored: Bool {
        switch self {
        case .upMirrored, .downMirrored, .leftMirrored, .rightMirrored:
            return true
        default:
            return false
        }
    }
}

fileprivate struct SpeedCheckResult: Codable {
    let osVersion: String
    let date: Date
    let isFastEnough: Bool
    let computeUnits: MLComputeUnits
    let modelVersion: String?
}

extension MLComputeUnits: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        guard let val = MLComputeUnits(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid rawValue \(rawValue) for MLComputeUnits")
        }
        self = val
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
