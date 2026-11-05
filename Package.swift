// swift-tools-version: 6.2
// Paquete para Linux y Windows. Compila la MISMA carpeta TaskApp/ que usa Xcode
// (en Mac e iOS se sigue abriendo TaskApp.xcodeproj y se usa el SwiftUI de Apple).
import PackageDescription

#if os(Linux)
let backend: Target.Dependency = .product(name: "BackendGTK4", package: "swiftopenui")
#elseif os(Windows)
let backend: Target.Dependency = .product(name: "BackendWin32", package: "swiftopenui")
#else
let backend: Target.Dependency? = nil
#endif

let package = Package(
    name: "TaskApp",
    dependencies: [.package(path: "../swiftopenui")],
    targets: [
        // Sustituye al SwiftUI de Apple: `import SwiftUI` trae SwiftOpenUI y su backend.
        .target(
            name: "SwiftUI",
            dependencies: [.product(name: "SwiftOpenUI", package: "swiftopenui")] + [backend].compactMap { $0 },
            path: "Compat/SwiftUI"
        ),
        // Sustituye a Combine: ObservableObject y @Published vienen de SwiftOpenUI.
        .target(name: "Combine", dependencies: ["SwiftUI"], path: "Compat/Combine"),
        // Mismos ajustes de Swift que el proyecto de Xcode.
        .executableTarget(
            name: "TaskApp",
            dependencies: ["SwiftUI", "Combine"],
            path: "TaskApp",
            exclude: ["Assets.xcassets"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
    ]
)
