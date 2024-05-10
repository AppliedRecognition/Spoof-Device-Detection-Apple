//
//  SpoofDeviceDetectionModel.swift
//
//
//  Created by Jakub Dolejs on 03/05/2024.
//
import SpoofDeviceDetection
import Foundation

public extension SpoofDeviceDetector {
    
    convenience init() throws {
        guard let url = Bundle.module.url(forResource: "ARC_PSD-001_1.1.122_bst_yl80201_NMS_ult201_cml70", withExtension: "mlmodelc") else {
            throw NSError() // TODO
        }
        try self.init(compiledModelURL: url, identifier: "ARC_PSD-001")
    }
}
