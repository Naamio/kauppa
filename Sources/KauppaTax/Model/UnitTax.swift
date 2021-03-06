import KauppaCore

/// Tax data for an unit (product or order unit).
public struct UnitTax: Mappable {
    /// Category of the product.
    public var category: String? = nil
    /// Tax rate used for this product (in percentage).
    public var rate: Float = 0.0
    /// Tax for this item i.e., `quantity` times `taxRate` (set by service).
    public var total = Price()
    /// Whether the tax is inclusive for this unit.
    public var inclusive: Bool = false

    /// Initialize an instance with `nil` category and tax rate set to "0"
    public init() {}
}
