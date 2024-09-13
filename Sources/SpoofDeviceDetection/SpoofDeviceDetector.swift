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
    
    lazy var request: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: self.model)
        request.imageCropAndScaleOption = .scaleFit
        return request
    }()
    
    /// Asynchronous constructor
    /// - Parameter modelURL: Model file URL
    /// - Since: 1.0.0
    @available(iOS 16, macOS 13, macCatalyst 16, *)
    public convenience init(modelURL: URL) async throws {
        let compiledModelURL = try await MLModel.compileModel(at: modelURL)
        try self.init(compiledModelURL: compiledModelURL, identifier: modelURL.lastPathComponent)
    }
    
    /// Constructor
    /// - Parameter modelURL: Model file URL
    /// - Since: 1.0.0
    public convenience init(modelURL: URL) throws {
        let compiledModelURL = try MLModel.compileModel(at: modelURL)
        try self.init(compiledModelURL: compiledModelURL, identifier: modelURL.lastPathComponent)
    }
    
    /// Constructor
    /// - Parameters:
    ///     - compiledModelURL: URL of the compiled model file
    ///     - identifier: Model identifier
    /// - Since: 1.3.0
    public init(compiledModelURL: URL, identifier: String) throws {
        let spoofDetector: MLModel = try MLModel(contentsOf: compiledModelURL)
        self.model = try VNCoreMLModel(for: spoofDetector)
        self.identifier = identifier
    }
    
    // MARK: - SpoofDetector
    
    public let identifier: String
    
    public var confidenceThreshold: Float = 0.5
    
    @available(iOS 15, *)
    public func detectSpoofInImage(_ image: UIImage, regionOfInterest roi: CGRect?) async throws -> Float {
        var spoofDevices = try await self.detectSpoofDevicesInImage(image)
        if let centreX = roi?.midX, let centreY = roi?.midY {
            let roiCentre = CGPoint(x: centreX, y: centreY)
            spoofDevices = spoofDevices.filter({ $0.boundingBox.contains(roiCentre) })
        }
        return spoofDevices.max(by: { $0.confidence < $1.confidence })?.confidence ?? 0
    }
    
    @available(iOS, introduced: 13.0, obsoleted: 15.0)
    public func detectSpoofInImage(_ image: UIImage, regionOfInterest roi: CGRect?) throws -> Float {
        var spoofDevices = try self.detectSpoofDevicesInImage(image)
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
        return try self._detectSpoofDevicesInImage(image)
    }
    
    @available(iOS, introduced: 13.0, obsoleted: 15.0)
    public func detectSpoofDevicesInImage(_ image: UIImage) throws -> [DetectedSpoof] {
        return try self._detectSpoofDevicesInImage(image)
    }
    
    private func _detectSpoofDevicesInImage(_ image: UIImage) throws -> [DetectedSpoof] {
        let longerSide = max(image.size.width, image.size.height)
        var scaleTransform: CGAffineTransform = .identity
        var scaledImage = image
        if longerSide > self.maxSideLength {
            let scale = self.maxSideLength / longerSide
            scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            let scaledSize = image.size.applying(scaleTransform)
            scaledImage = UIGraphicsImageRenderer(size: scaledSize).image { _ in
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
