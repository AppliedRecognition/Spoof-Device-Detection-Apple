//
//  SettingsView.swift
//  Spoof Device Detector
//
//  Created by Jakub Dolejs on 08/04/2025.
//

import SwiftUI
import CoreML

struct SettingsView: View {
    
    @State var selectedUnits: Int = MLComputeUnits.all.rawValue
    let unitOptions: [(String,Int)] = [
        ("All",MLComputeUnits.all.rawValue),
        ("CPU and GPU", MLComputeUnits.cpuAndGPU.rawValue),
        ("CPU and Neural Engine", MLComputeUnits.cpuAndNeuralEngine.rawValue),
        ("CPU only", MLComputeUnits.cpuOnly.rawValue)
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("Model compute units")
                Spacer()
                Picker("Model compute units", selection: self.$selectedUnits) {
                    ForEach(self.unitOptions, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .onChange(of: selectedUnits) { computeUnits in
            UserDefaults.standard.setValue(computeUnits, forKey: "computeUnits")
        }
        .onAppear {
            let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
            let units: Int
            if allKeys.contains("computeUnits") {
                units = UserDefaults.standard.integer(forKey: "computeUnits")
            } else {
                units = MLComputeUnits.all.rawValue
            }
            self.selectedUnits = units
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
