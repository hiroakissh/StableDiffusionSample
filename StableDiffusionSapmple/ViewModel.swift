//
//  ViewModel.swift
//  StableDiffusionSapmple
//
//  Created by HiroakiSaito on 2024/02/04.
//

import Foundation
import StableDiffusion
import CoreGraphics

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
            Task.detached {
                self.status = .loadStart
            }
            // TODO: controlNetについて調べる
            let pipeline = try StableDiffusionPipeline(resourcesAt: resourceURl, controlNet: ["lllyasviel/sd-controlnet-canny"])
            Task.detached {
                self.pipeline = pipeline
                self.status = .loadFinish
            }
        } catch {
            Task.detached {
                self.status = .error
            }
        }
    }

    func generateImage() async {
        do {
            Task.detached {
                self.image = nil
                self.status = .generateStart
            }
            let image = try self.pipeline?.generateImages(
                configuration: .init(prompt: self.prompt)
            ) { progress in
                Task.detached {
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
            Task.detached {
                self.image = image
                self.status = .generateFinish
            }
        } catch {
            Task.detached {
                self.status = .error
            }
        }
    }
}
