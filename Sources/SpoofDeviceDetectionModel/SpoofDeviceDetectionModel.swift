//
//  SpoofDeviceDetectionModel.swift
//
//
//  Created by Jakub Dolejs on 03/05/2024.
//
import SpoofDeviceDetection
import Foundation

@available(iOS 13, *)
public extension SpoofDeviceDetector {
    
    /// Constructor
    ///
    /// Uses model packaged with the module
    /// - Since: 1.0.0
    convenience init() throws {
        let modelName = "ARC_PSD-001_1.4.151_lst_yl82087_NMS_ult087_cml72"
        guard let url = Bundle.module.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw SpoofDeviceDetectorError.modelNotFound
        }
        try self.init(compiledModelURL: url, identifier: modelName)
    }
    
    /// Async constructor
    ///
    /// Uses model packaged with the module
    /// - Since: 1.1.0
    @available(iOS 15, *)
    convenience init() async throws {
        let modelName = "ARC_PSD-001_1.4.151_lst_yl82087_NMS_ult087_cml72"
        guard let url = Bundle.module.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw SpoofDeviceDetectorError.modelNotFound
        }
        try await self.init(compiledModelURL: url, identifier: modelName)
    }
}
