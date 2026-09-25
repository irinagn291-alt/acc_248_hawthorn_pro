import RealityKit
import SwiftUI
import UIKit

/// One non-AR particle field behind the tin. No session and no camera feed.
struct DriftField: UIViewRepresentable {
    var frozen: Bool

    func makeUIView(context: Context) -> UIView {
        let host = UIView(frame: .zero)
        host.backgroundColor = .clear
        guard #available(iOS 18.0, *) else { return host }
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        let paper = UIColor(named: "background") ?? .clear
        let spice = UIColor(named: "accent") ?? .clear
        view.environment.background = .color(paper)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let anchor = AnchorEntity(world: .zero)
        let mesh = MeshResource.generateSphere(radius: 0.012)
        var material = UnlitMaterial()
        material.color = .init(tint: spice)
        let spots: [SIMD3<Float>] = [
            [-0.18, 0.12, -0.4], [0.16, 0.2, -0.55], [-0.05, -0.08, -0.35],
            [0.22, -0.16, -0.6], [-0.24, -0.2, -0.5], [0.04, 0.28, -0.7],
            [0.3, 0.02, -0.45], [-0.12, 0.22, -0.62]
        ]
        for spot in spots {
            let sphere = ModelEntity(mesh: mesh, materials: [material])
            sphere.position = spot
            anchor.addChild(sphere)
            context.coordinator.spheres.append(sphere)
        }
        view.scene.addAnchor(anchor)
        host.addSubview(view)
        context.coordinator.frozen = frozen
        context.coordinator.start()
        return host
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.frozen = frozen
        if #available(iOS 18.0, *), let field = uiView.subviews.first {
            field.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        var spheres: [ModelEntity] = []
        var frozen = false
        private var started = false

        func start() {
            guard !started else { return }
            started = true
            Task { await self.run() }
        }

        private func run() async {
            while !Task.isCancelled {
                let pause: Duration = frozen ? .milliseconds(400) : .seconds(3)
                if !frozen {
                    for (index, sphere) in spheres.enumerated() {
                        let lift: Float = index.isMultiple(of: 2) ? 0.04 : -0.03
                        let next = sphere.position + SIMD3<Float>(0, lift, 0)
                        sphere.move(to: Transform(translation: next), relativeTo: sphere.parent, duration: 3.2, timingFunction: .linear)
                    }
                }
                try? await Task.sleep(for: pause)
            }
        }
    }
}
