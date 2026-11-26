// swift-tools-version:5.9
// Lets the report rules be built and tested without Xcode (also on Linux): `swift test`.
// The app itself is built from Goruldu.xcodeproj, which compiles the same files in `Core/`.
import PackageDescription

let package = Package(
    name: "GorulduCore",
    targets: [
        .target(name: "GorulduCore", path: "Core"),
        .testTarget(
            name: "GorulduCoreTests",
            dependencies: ["GorulduCore"],
            path: "tests/CoreTests",
            resources: [.process("Fixtures")]
        ),
    ]
)
