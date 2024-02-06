//
//  ViewModel.swift
//  StableDiffusionSapmple
//
//  Created by HiroakiSaito on 2024/02/04.
//

import Foundation
import StableDiffusion
import CoreGraphics

@MainActor
class ViewModel: ObservableObject {
    @Published var pipeline: StableDiffusionPipeline?
    @Published var image: [CGImage]?
    @Published var prompt: String = "cat"
    @Published var imageCount: Int = 1
    @Published var stepCount: Double = 30
    @Published var seed: Double = 500
    @Published var step: Int = 0
    @Published var status: StableDiffusionStatus = .ready


    func loadModels() async {
        guard let resourceURl = Bundle.main.resourceURL else { return }
        do {
            Task.detached { @MainActor in
                self.status = .loadStart
            }
            // TODO: controlNetについて調べる
            let pipeline = try StableDiffusionPipeline(resourcesAt: resourceURl, controlNet: ["LllyasvielControlV11F1ESd15Tile"])
            Task.detached { @MainActor in
                self.pipeline = pipeline
                self.status = .loadFinish
            }
        } catch {
            Task.detached { @MainActor in
                self.status = .error
            }
        }
    }

    func generateImage() async {
        do {
            Task.detached { @MainActor in
                self.image = nil
                self.status = .generateStart
            }
            let image = try self.pipeline?.generateImages(
                configuration: .init(prompt: self.prompt)
            ) { progress in
                Task.detached { @MainActor in
                    self.image = progress.currentImages.map({ cgImage in
                        guard let cgImage else { fatalError() }
                        return cgImage
                    })
                    self.step = progress.step
                }
                return true
            }.map({ cgImage in
                guard let cgImage else { fatalError() }
                return cgImage
            })
            Task.detached { @MainActor in
                self.image = image
                self.status = .generateFinish
            }
        } catch {
            Task.detached { @MainActor in
                self.status = .error
            }
        }
    }
}
