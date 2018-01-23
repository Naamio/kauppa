import Foundation

import KauppaCore

/// A cart unit represents a product with the specified quantity.
public struct CartUnit: Mappable {
    /// Product ID
    public var productId: UUID
    /// Required quantity of this product
    public var quantity: UInt8
    /// Tax rate used for this product (set by service).
    public var taxRate: Float? = nil
    /// Tax for this item i.e., `quantity` times `taxRate` (set by service).
    public var tax: UnitMeasurement<Currency>? = nil
    /// The price of this unit without tax (set by service).
    public var netPrice: UnitMeasurement<Currency>? = nil
    /// The price of this unit with tax (set by service).
    public var grossPrice: UnitMeasurement<Currency>? = nil

    public init(id: UUID, quantity: UInt8) {
        self.productId = id
        self.quantity = quantity
    }
}
