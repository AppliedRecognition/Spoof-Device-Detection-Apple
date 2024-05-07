//
//  DetectedSpoofDevice.swift
//  LivenessDetection
//
//  Created by Jakub Dolejs on 03/02/2023.
//

import UIKit
import Vision

/// Represents a detected spoof device
/// - Since: 1.0.0
public struct DetectedSpoof: Codable {
    
    enum CodingKeys: String, CodingKey {
        case confidence, boundingBox
    }
    
    enum BoundingBoxCodingKeys: String, CodingKey {
        case x, y, width, height
    }
    
    /// Bounding box of the detected spoof device
    /// - Since: 1.0.0
    public let boundingBox: CGRect
    /// Confidence in the detection (value between `0.0` and `1.0` where `1` means 100% confidence that
    /// the bounding box contains a spoof device
    /// - Since: 1.0.0
    public let confidence: Float
    
    @available(iOS 12.0, *)
    init(observation: VNRecognizedObjectObservation, imageSize: CGSize) {
        let flippedBox = CGRect(x: observation.boundingBox.minX, y: 1 - observation.boundingBox.maxY, width: observation.boundingBox.width, height: observation.boundingBox.height)
        self.boundingBox = VNImageRectForNormalizedRect(flippedBox, Int(imageSize.width), Int(imageSize.height))
        self.confidence = observation.confidence
    }
    
    init(boundingBox: CGRect, confidence: Float) {
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.confidence = try container.decode(Float.self, forKey: .confidence)
        let boundingBoxContainer = try container.nestedContainer(keyedBy: BoundingBoxCodingKeys.self, forKey: .boundingBox)
        let x = try boundingBoxContainer.decode(CGFloat.self, forKey: .x)
        let y = try boundingBoxContainer.decode(CGFloat.self, forKey: .y)
        let width = try boundingBoxContainer.decode(CGFloat.self, forKey: .width)
        let height = try boundingBoxContainer.decode(CGFloat.self, forKey: .height)
        self.boundingBox = CGRect(x: x, y: y, width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.confidence, forKey: .confidence)
        var boundingBoxContainer = container.nestedContainer(keyedBy: BoundingBoxCodingKeys.self, forKey: .boundingBox)
        try boundingBoxContainer.encode(self.boundingBox.minX, forKey: .x)
        try boundingBoxContainer.encode(self.boundingBox.minY, forKey: .y)
        try boundingBoxContainer.encode(self.boundingBox.width, forKey: .width)
        try boundingBoxContainer.encode(self.boundingBox.height, forKey: .height)
    }
    
    /// Flip (mirror) the bounding box along its vertical axis
    ///
    /// May be useful if the detection is done on an image that's mirrored for display, e.g., capturing a selfie
    /// - Parameter imageSize: Size of the image in which the spoof device was detected
    /// - Returns: The detection with (mirrored) bounding box
    /// - Since: 1.0.0
    public func flipped(imageSize: CGSize) -> DetectedSpoof {
        let transform = CGAffineTransform(scaleX: -1, y: 1).concatenating(CGAffineTransform(translationX: imageSize.width, y: 0))
        return DetectedSpoof(boundingBox: self.boundingBox.applying(transform), confidence: self.confidence)
    }
}
