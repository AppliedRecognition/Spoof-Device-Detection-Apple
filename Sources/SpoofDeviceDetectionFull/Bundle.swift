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
    
    static var module: Bundle {
        let bundleURL = Bundle(for: SpoofDeviceDetectionFull.self).resourceURL?.appendingPathComponent("SpoofDeviceDetectionFull.bundle")
        return Bundle(url: bundleURL!)
    }
}
#endif
