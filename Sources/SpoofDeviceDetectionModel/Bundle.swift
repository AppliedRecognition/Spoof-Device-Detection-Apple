//
//  Bundle.swift
//
//
//  Created by Jakub Dolejs on 08/05/2024.
//
#if SPM
import Foundation
#else
import class Foundation.Bundle

extension Foundation.Bundle {
    
    @available(iOS 13, *)
    static var module: Bundle {
        guard let bundleURL = Bundle(for: SpoofDeviceDetector.self).resourceURL?.appendingPathComponent("SpoofDeviceDetectionModel.bundle") else {
            fatalError("Missing resource bundle")
        }
        guard let bundle = Bundle(url: bundleURL) else {
            fatalError("Failed to load resource bundle")
        }
        return bundle
    }
}
#endif
