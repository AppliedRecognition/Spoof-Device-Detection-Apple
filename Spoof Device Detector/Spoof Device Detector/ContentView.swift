//
//  ContentView.swift
//  Spoof Device Detector
//
//  Created by Jakub Dolejs on 08/04/2025.
//

import SwiftUI
import PhotosUI
import SpoofDeviceDetection
import SpoofDeviceDetectionModel
import CoreML

struct ContentView: View {
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var spoofDetector: SpoofDeviceDetector?
    @State private var error: String?
    @State private var message: String?
    
    var body: some View {
        VStack {
            if let error = self.error {
                Text(verbatim: error)
                Button {
                    self.error = nil
                } label: {
                    Text("OK")
                }
            } else if spoofDetector == nil {
                ProgressView().progressViewStyle(.circular)
            } else {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                }
                if let msg = self.message {
                    Text(verbatim: msg)
                }
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Pick a Photo")
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                guard let spoofDetector = self.spoofDetector, let pickedItem = newItem else {
                    return
                }
                do {
                    await MainActor.run {
                        self.message = "Running spoof detection"
                    }
                    guard let data = try await pickedItem.loadTransferable(type: Data.self) else {
                        return
                    }
                    guard let uiImage = UIImage(data: data) else {
                        return
                    }
                    await MainActor.run {
                        self.selectedImage = uiImage
                    }
                    let (spoofDeviceResult, time) = await measure {
                        try await spoofDetector.detectSpoofDevicesInImage(uiImage)
                    }
                    switch spoofDeviceResult {
                    case .success(let spoofs):
                        if !spoofs.isEmpty {
                            let strokeColours: [UIColor] = [
                                .red, .green, .yellow, .cyan, .orange, .blue, .magenta
                            ]
                            let strokeWidth = min(uiImage.size.width, uiImage.size.height) * 0.01
                            let annotatedImage = UIGraphicsImageRenderer(size: uiImage.size).image { context in
                                uiImage.draw(at: .zero)
                                let cg = context.cgContext
                                var i = 0
                                cg.setLineWidth(strokeWidth)
                                for spoof in spoofs {
                                    cg.setStrokeColor(strokeColours[i % strokeColours.count].cgColor)
                                    cg.stroke(spoof.boundingBox)
                                    i += 1
                                }
                            }
                            await MainActor.run {
                                self.selectedImage = annotatedImage
                                self.message = String(format: "Detected %d spoof device(s) in %.02f s", spoofs.count, time)
                            }
                        } else {
                            await MainActor.run {
                                self.message = String(format: "No spoof devices detected in %.02f s", time)
                            }
                        }
                    case .failure(let error):
                        await MainActor.run {
                            self.message = String(format: "Spoof detection failed in %.02f s: %@", time, error.localizedDescription)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.message = error.localizedDescription
                    }
                }
            }
        }
        .task {
            let (result, time) = await measure {
                let config = MLModelConfiguration()
                let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
                if allKeys.contains("computeUnits"), let computeUnits = MLComputeUnits(rawValue: UserDefaults.standard.integer(forKey: "computeUnits")) {
                    config.computeUnits = computeUnits
                }
                return try await SpoofDeviceDetector(configuration: config)
            }
            switch result {
            case .success(let detector):
                self.spoofDetector = detector
                self.message = String(format: "Spoof detector loaded in %.02f s", time)
            case .failure(let error):
                self.error = String(format: "Failed to load spoof detector in %.02f s: %@", time, error.localizedDescription)
            }
        }
        .navigationTitle("Spoof detection test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func copy(of image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else {
            return image
        }
        
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    ContentView()
}
