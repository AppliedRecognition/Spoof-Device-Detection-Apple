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
public class SpoofDeviceDetector: SpoofDetector {
    
    public var logger: Logger = NSLogLogger()
    
    let model: VNCoreMLModel
    lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
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
    
    public func detectSpoofInImage(_ image: UIImage, regionOfInterest roi: CGRect?) async throws -> Float {
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
    public func detectSpoofDevicesInImage(_ image: UIImage) throws -> [DetectedSpoof] {
        let operation = DetectionOperation(request: self.request, image: image)
        self.queue.addOperations([operation], waitUntilFinished: true)
        if let error = operation.error {
            throw error
        }
        return operation.results
    }
}

fileprivate class DetectionOperation: Operation {
    
    var image: UIImage
    let request: VNCoreMLRequest
    var error: Error?
    var maxSideLength: CGFloat = 4000
    var results: [DetectedSpoof] = []
    
    init(request: VNCoreMLRequest, image: UIImage) {
        self.request = request
        self.image = image
    }
    
    override func main() {
        do {
            let longerSide = max(image.size.width, image.size.height)
            var scaleTransform: CGAffineTransform = .identity
            if longerSide > self.maxSideLength {
                let scale = self.maxSideLength / longerSide
                scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
                let scaledSize = self.image.size.applying(scaleTransform)
                self.image = UIGraphicsImageRenderer(size: scaledSize).image { _ in
                    self.image.draw(in: CGRect(origin: .zero, size: scaledSize))
                }
            }
            guard let cgImage = self.image.cgImage else {
                throw ImageProcessingError.cgImageConversionError
            }
            let orientation = self.image.imageOrientation.cgImagePropertyOrientation
            try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([self.request])
            self.results = (self.request.results as? [VNRecognizedObjectObservation])?.map { DetectedSpoof(observation: $0, imageSize: self.image.size) } ?? []
            let invertedScaleTransform: CGAffineTransform
            if !scaleTransform.isIdentity {
                invertedScaleTransform = scaleTransform.inverted()
            } else {
                invertedScaleTransform = .identity
            }
            self.results = self.results.map { result in
                if !invertedScaleTransform.isIdentity {
                    return DetectedSpoof(boundingBox: result.boundingBox.applying(invertedScaleTransform), confidence: result.confidence)
                }
                return result
            }.filter { $0.confidence > 0 }
        } catch {
            self.error = error
        }
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
