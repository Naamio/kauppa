// swift-tools-version:4.0

import PackageDescription

let modelTargets: [Target] = [
    .target(
        name: "KauppaAccountsModel",
        dependencies: ["KauppaCore"],
        path: "Sources/KauppaAccounts/Model"
    ),
    .target(
        name: "KauppaCartModel",
        dependencies: ["KauppaCore", "KauppaAccountsModel", "KauppaOrdersModel", "KauppaTaxModel"],
        path: "Sources/KauppaCart/Model"
    ),
    .target(
        name: "KauppaCouponModel",
        dependencies: ["KauppaCore"],
        path: "Sources/KauppaCoupon/Model"
    ),
    .target(
        name: "KauppaNaamioModel",
        dependencies: ["KauppaCore"],
        path: "Sources/KauppaNaamio/Model"
    ),
    .target(
        name: "KauppaOrdersModel",
        dependencies: [
            "KauppaCore",
            "KauppaAccountsModel",
            "KauppaCouponModel",
            "KauppaProductsModel",
            "KauppaTaxModel"
        ],
        path: "Sources/KauppaOrders/Model"
    ),
    .target(
        name: "KauppaProductsModel",
        dependencies: ["KauppaCore", "KauppaTaxModel"],
        path: "Sources/KauppaProducts/Model"
    ),
    .target(
        name: "KauppaShipmentsModel",
        dependencies: ["KauppaCore", "KauppaAccountsModel", "KauppaOrdersModel"],
        path: "Sources/KauppaShipments/Model"
    ),
    .target(
        name: "KauppaTaxModel",
        dependencies: ["KauppaCore"],
        path: "Sources/KauppaTax/Model"
    )
]

let storeTargets: [Target] = [
    .target(
        name: "KauppaAccountsStore",
        dependencies: ["KauppaCore", "KauppaAccountsModel"],
        path: "Sources/KauppaAccounts/Store"
    ),
    .target(
        name: "KauppaCartStore",
        dependencies: ["KauppaCore", "KauppaCartModel"],
        path: "Sources/KauppaCart/Store"
    ),
    .target(
        name: "KauppaCouponStore",
        dependencies: ["KauppaCore", "KauppaCouponModel"],
        path: "Sources/KauppaCoupon/Store"
    ),
    .target(
        name: "KauppaOrdersStore",
        dependencies: ["KauppaCore", "KauppaOrdersModel"],
        path: "Sources/KauppaOrders/Store"
    ),
    .target(
        name: "KauppaProductsStore",
        dependencies: ["KauppaCore", "KauppaProductsModel"],
        path: "Sources/KauppaProducts/Store"
    ),
    .target(
        name: "KauppaShipmentsStore",
        dependencies: ["KauppaCore", "KauppaShipmentsModel"],
        path: "Sources/KauppaShipments/Store"
    ),
    .target(
        name: "KauppaTaxStore",
        dependencies: ["KauppaCore", "KauppaTaxModel"],
        path: "Sources/KauppaTax/Store"
    )
]

let repositoryTargets: [Target] = [
    .target(
        name: "KauppaAccountsRepository",
        dependencies: ["KauppaAccountsStore", "KauppaAccountsModel", "KauppaCore"],
        path: "Sources/KauppaAccounts/Repository"
    ),
    .target(
        name: "KauppaCartRepository",
        dependencies: ["KauppaCartModel", "KauppaCartStore", "KauppaCore"],
        path: "Sources/KauppaCart/Repository"
    ),
    .target(
        name: "KauppaCouponRepository",
        dependencies: ["KauppaCouponModel", "KauppaCouponStore", "KauppaCore"],
        path: "Sources/KauppaCoupon/Repository"
    ),
    .target(
        name: "KauppaOrdersRepository",
        dependencies: ["KauppaOrdersModel", "KauppaOrdersStore", "KauppaCore"],
        path: "Sources/KauppaOrders/Repository"
    ),
    .target(
        name: "KauppaProductsRepository",
        dependencies: ["KauppaProductsModel", "KauppaProductsStore", "KauppaCore"],
        path: "Sources/KauppaProducts/Repository"
    ),
    .target(
        name: "KauppaShipmentsRepository",
        dependencies: [
            "KauppaShipmentsModel",
            "KauppaShipmentsStore",
            "KauppaCore",
            "KauppaAccountsModel",
            "KauppaOrdersModel"
        ],
        path: "Sources/KauppaShipments/Repository"
    ),
    .target(
        name: "KauppaTaxRepository",
        dependencies: ["KauppaTaxModel", "KauppaTaxStore", "KauppaCore"],
        path: "Sources/KauppaTax/Repository"
    )
]

let serviceTargets: [Target] = [
    .target(
        name: "KauppaAccountsService",
        dependencies: ["KauppaAccountsRepository", "KauppaAccountsModel", "KauppaCore", "KauppaAccountsClient"],
        path: "Sources/KauppaAccounts/Service"
    ),
    .target(
        name: "KauppaCartService",
        dependencies: [
            "KauppaCore",
            "KauppaCartClient",
            "KauppaCartRepository",
            "KauppaCartModel",
            "KauppaAccountsModel",
            "KauppaAccountsClient",
            "KauppaOrdersClient",
            "KauppaOrdersModel",
            "KauppaCouponClient",
            "KauppaProductsClient",
            "KauppaTaxClient",
            "KauppaTaxModel"
        ],
        path: "Sources/KauppaCart/Service"
    ),
    .target(
        name: "KauppaCouponService",
        dependencies: [
            "KauppaCore",
            "KauppaCouponClient",
            "KauppaCouponRepository",
            "KauppaCouponModel",
        ],
        path: "Sources/KauppaCoupon/Service"
    ),
    .target(
        name: "KauppaNaamioService",
        dependencies: [
            "KauppaCore",
            "KauppaNaamioModel",
        ],
        path: "Sources/KauppaNaamio/Service"
    ),
    .target(
        name: "KauppaOrdersService",
        dependencies: [
            "KauppaCore",
            "KauppaCouponModel",
            "KauppaCouponClient",
            "KauppaOrdersClient",
            "KauppaOrdersRepository",
            "KauppaOrdersModel",
            "KauppaAccountsClient",
            "KauppaProductsClient",
            "KauppaShipmentsClient",
            "KauppaTaxClient",
            "KauppaTaxModel",
        ],
        path: "Sources/KauppaOrders/Service"
    ),
    .target(
        name: "KauppaProductsService",
        dependencies: [
            "KauppaCore",
            "KauppaAccountsModel",
            "KauppaProductsClient",
            "KauppaProductsRepository",
            "KauppaProductsModel",
            "KauppaTaxClient"
        ],
        path: "Sources/KauppaProducts/Service"
    ),
    .target(
        name: "KauppaShipmentsService",
        dependencies: [
            "KauppaCore",
            "KauppaAccountsModel",
            "KauppaOrdersClient",
            "KauppaShipmentsClient",
            "KauppaShipmentsRepository",
            "KauppaShipmentsModel"
        ],
        path: "Sources/KauppaShipments/Service"
    ),
    .target(
        name: "KauppaTaxService",
        dependencies: [
            "KauppaCore",
            "KauppaTaxClient",
            "KauppaAccountsModel",
            "KauppaTaxModel",
            "KauppaTaxRepository"
        ],
        path: "Sources/KauppaTax/Service"
    )
]

let clientTargets: [Target] = [
    .target(
        name: "KauppaAccountsClient",
        dependencies: ["KauppaAccountsModel"],
        path: "Sources/KauppaAccounts/Client"
    ),
    .target(
        name: "KauppaCartClient",
        dependencies: ["KauppaCartModel", "KauppaOrdersModel"],
        path: "Sources/KauppaCart/Client"
    ),
    .target(
        name: "KauppaCouponClient",
        dependencies: ["KauppaCouponModel"],
        path: "Sources/KauppaCoupon/Client"
    ),
    .target(
        name: "KauppaOrdersClient",
        dependencies: ["KauppaOrdersModel", "KauppaShipmentsModel"],
        path: "Sources/KauppaOrders/Client"
    ),
    .target(
        name: "KauppaProductsClient",
        dependencies: ["KauppaProductsModel", "KauppaAccountsModel"],
        path: "Sources/KauppaProducts/Client"
    ),
    .target(
        name: "KauppaShipmentsClient",
        dependencies: ["KauppaShipmentsModel"],
        path: "Sources/KauppaShipments/Client"
    ),
    .target(
        name: "KauppaTaxClient",
        dependencies: ["KauppaTaxModel", "KauppaAccountsModel"],
        path: "Sources/KauppaTax/Client"
    )
]

let daemonTargets: [Target] = [
    .target(
        name: "Kauppa",
        dependencies: [
            "KauppaAccounts",
            "KauppaCart",
            "KauppaCoupon",
            "KauppaOrders",
            "KauppaProducts",
            "KauppaShipments",
            "KauppaTax"
        ]
    ),
    .target(
        name: "KauppaAccounts",
        dependencies: [
            "KauppaAccountsClient",
            "KauppaAccountsService",
            "KauppaAccountsRepository",
            "KauppaAccountsModel",
            "KauppaCore"
        ],
        exclude: ["Client", "Service", "Repository", "Model", "Store"]
    ),
    .target(
        name: "KauppaCart",
        dependencies: [
            "KauppaCartClient",
            "KauppaCartService",
            "KauppaCartRepository",
            "KauppaCartModel",
            "KauppaCore"
        ],
        exclude: ["Client", "Service", "Repository", "Model", "Store"]
    ),
    .target(
        name: "KauppaCoupon",
        dependencies: [
            "KauppaCouponClient",
            "KauppaCouponService",
            "KauppaCouponRepository",
            "KauppaCouponModel",
            "KauppaCore"
        ],
        exclude: ["Client", "Service", "Repository", "Model", "Store"]
    ),
    .target(
        name: "KauppaNaamio",
        dependencies: [
            "KauppaCore",
            "KauppaNaamioModel",
            "KauppaNaamioService"
        ],
        exclude: ["Model", "Service"]
    ),
    .target(
        name: "KauppaOrders",
        dependencies: [
            "KauppaOrdersClient",
            "KauppaOrdersService",
            "KauppaOrdersRepository",
            "KauppaOrdersModel",
            "KauppaCore"
        ],
        exclude: ["Client", "Service", "Repository", "Model", "Store"]
    ),
    .target(
        name: "KauppaProducts",
        dependencies: [
            "KauppaProductsClient",
            "KauppaProductsService",
            "KauppaProductsRepository",
            "KauppaProductsModel",
            "KauppaCore"
        ],
        exclude: ["Client", "Service", "Repository", "Model", "Store"]
    ),
    .target(
        name: "KauppaShipments",
        dependencies: [
            "KauppaShipmentsClient",
            "KauppaShipmentsService",
            "KauppaShipmentsRepository",
            "KauppaShipmentsModel",
            "KauppaCore"
        ],
        exclude: ["Client", "Service", "Repository", "Model", "Store"]
    ),
    .target(
        name: "KauppaTax",
        dependencies: [
            "KauppaTaxClient",
            "KauppaTaxService",
            "KauppaTaxRepository",
            "KauppaTaxModel",
            "KauppaCore"
        ],
        exclude: ["Client", "Service", "Repository", "Model", "Store"]
    )
]

let testTargets: [Target] = [
    .testTarget(
        name: "KauppaAccountsTests",
        dependencies: ["KauppaAccountsService", "KauppaAccountsModel", "KauppaCore", "TestTypes"]
    ),
    .testTarget(
        name: "KauppaCoreTests",
        dependencies: ["KauppaCore", "TestTypes"]
    ),
    .testTarget(
        name: "TestTypes",
        dependencies: ["KauppaCore"]
    ),
    .testTarget(
        name: "KauppaCartTests",
        dependencies: [
            "KauppaCore",
            "KauppaAccountsClient",
            "KauppaAccountsModel",
            "KauppaOrdersClient",
            "KauppaOrdersModel",
            "KauppaProductsClient",
            "KauppaProductsModel",
            "KauppaShipmentsModel",
            "KauppaTaxClient",
            "KauppaTaxModel",
            "KauppaCartModel",
            "KauppaCartRepository",
            "KauppaCartService",
            "TestTypes"
        ]
    ),
    .testTarget(
        name: "KauppaCouponTests",
        dependencies: [
            "KauppaCore",
            "KauppaCouponClient",
            "KauppaCouponModel",
            "KauppaCouponRepository",
            "KauppaCouponService",
            "TestTypes"
        ]
    ),
    .testTarget(
        name: "KauppaNaamioTests",
        dependencies: [
            "KauppaCore",
            "KauppaNaamioModel",
            "KauppaNaamioService",
            "TestTypes"
        ]
    ),
    .testTarget(
        name: "KauppaOrdersTests",
        dependencies: [
            "KauppaCore",
            "KauppaAccountsClient",
            "KauppaAccountsModel",
            "KauppaProductsClient",
            "KauppaProductsModel",
            "KauppaOrdersClient",
            "KauppaOrdersModel",
            "KauppaOrdersStore",
            "KauppaOrdersRepository",
            "KauppaOrdersService",
            "KauppaOrdersStore",
            "KauppaTaxModel",
            "KauppaTaxClient",
            "TestTypes"
        ]
    ),
    .testTarget(
        name: "KauppaProductsTests",
        dependencies: [
            "KauppaAccountsModel",
            "KauppaProductsModel",
            "KauppaProductsRepository",
            "KauppaProductsService",
            "KauppaTaxClient",
            "KauppaTaxModel",
            "KauppaCore",
            "TestTypes"
        ]
    ),
    .testTarget(
        name: "KauppaShipmentsTests",
        dependencies: [
            "KauppaAccountsModel",
            "KauppaOrdersClient",
            "KauppaOrdersModel",
            "KauppaShipmentsModel",
            "KauppaShipmentsRepository",
            "KauppaShipmentsService",
            "KauppaCore",
            "TestTypes"
        ]
    ),
    .testTarget(
        name: "KauppaTaxTests",
        dependencies: [
            "KauppaCore",
            "KauppaTaxClient",
            "KauppaTaxModel",
            "KauppaTaxRepository",
            "KauppaTaxService",
            "TestTypes"
        ]
    )
]

var targets: [Target] = [
    .target(
        name: "KauppaCore",
        dependencies: ["Kitura", "Loki", "NIO", "NIOOpenSSL", "PostgreSQL", "SwiftKuery", "SwiftyRequest"]
    )
]

targets.append(contentsOf: modelTargets)
targets.append(contentsOf: repositoryTargets)
targets.append(contentsOf: storeTargets)
targets.append(contentsOf: serviceTargets)
targets.append(contentsOf: clientTargets)
targets.append(contentsOf: daemonTargets)
targets.append(contentsOf: testTargets)

let package = Package(
    name: "Kauppa",
    products: [
        .executable(
            name: "Kauppa",
            targets: ["Kauppa"]
        ),
        .executable(
            name: "KauppaAccounts",
            targets: ["KauppaAccounts"]
        ),
        .executable(
            name: "KauppaCart",
            targets: ["KauppaCart"]
        ),
        .executable(
            name: "KauppaCoupon",
            targets: ["KauppaCoupon"]
        ),
        .executable(
            name: "KauppaNaamio",
            targets: ["KauppaNaamio"]
        ),
        .executable(
            name: "KauppaOrders",
            targets: ["KauppaOrders"]
        ),
        .executable(
            name: "KauppaProducts",
            targets: ["KauppaProducts"]
        ),
        .executable(
            name: "KauppaShipments",
            targets: ["KauppaShipments"]
        ),
        .executable(
            name: "KauppaTax",
            targets: ["KauppaTax"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura", .upToNextMajor(from: "2.3.0")),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery", .upToNextMajor(from: "1.3.1")),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Naamio/loki", .upToNextMajor(from: "0.4.0")),
        .package(url: "https://github.com/apple/swift-nio", .upToNextMajor(from: "1.7.0")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/vapor/postgresql", .upToNextMajor(from: "1.0.0-rc.2.2")),
    ],
    targets: targets
)
