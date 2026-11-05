// Módulo "SwiftUI" para Linux y Windows: reexporta SwiftOpenUI, como el SwiftUI de
// Apple reexporta Foundation, y arranca la app con el backend del sistema.
@_exported import Foundation
@_exported import SwiftOpenUI

#if canImport(BackendGTK4)
import BackendGTK4
#elseif canImport(BackendWin32)
import BackendWin32
#endif

// Permite `@main struct TaskApp: App`, igual que en Apple.
extension App {
    public static func main() {
        #if canImport(BackendGTK4)
        GTK4Backend().run(Self.self)
        #elseif canImport(BackendWin32)
        Win32Backend().run(Self.self)
        #endif
    }
}
