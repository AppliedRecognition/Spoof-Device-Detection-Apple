//
//  Errors.swift
//
//
//  Created by Jakub Dolejs on 07/05/2024.
//

import Foundation

public enum ImageProcessingError: Error {
    case cgImageConversionError
}

public enum SpoofDeviceDetectorError: Error {
    case modelNotFound
}
