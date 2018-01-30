import Foundation

import KauppaCore

public struct Product: Mappable {
    /// Unique identifier for this product.
    public let id = UUID()
    /// Creation timestamp
    public let createdOn: Date
    /// Last updated timestamp
    public var updatedAt: Date
    /// Product's data supplied by the user.
    public var data: ProductData

    public init(data: ProductData) {
        let date = Date()
        self.createdOn = date
        self.updatedAt = date
        self.data = data
    }
}
