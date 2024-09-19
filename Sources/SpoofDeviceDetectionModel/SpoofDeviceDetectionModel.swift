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
    
    convenience init() throws {
        let modelName = "ARC_PSD-001_1.4.151_lst_yl82087_NMS_ult087_cml72"
        guard let url = Bundle.module.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw NSError() // TODO
        }
        try self.init(compiledModelURL: url, identifier: modelName)
    }
}
