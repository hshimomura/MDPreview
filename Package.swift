// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "MDPreview",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .executable(name: "MDPreview", targets: ["MDPreview"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/gonzalezreal/textual",
      exact: "0.5.0"
    )
  ],
  targets: [
    .executableTarget(
      name: "MDPreview",
      dependencies: [
        .product(name: "Textual", package: "textual")
      ],
      resources: [
        .copy("Resources")
      ]
    ),
    .testTarget(
      name: "MDPreviewTests",
      dependencies: ["MDPreview"]
    ),
  ]
)
