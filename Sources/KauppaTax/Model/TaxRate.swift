import KauppaCore

/// Tax rate information for a specific country or region. All values are
/// supposed to be in percentages.
public struct TaxRate: Mappable {
    /// Tax rate for any product.
    public var general: Float = 0.0
    /// Tax rates for different categories of products in the country/region.
    /// (also called tax classes)
    public var categories = [String: Float]()

    /// Initialize tax rate with no purpose - whose general tax rate is zero and doesn't
    /// have any categories.
    public init() {}

    /// Apply tax rate overrides from another instance of `TaxRate`
    ///
    /// - Parameters:
    ///   - The other `TaxRate` using which this tax rate should be overridden.
    public mutating func applyOverrideFrom(_ other: TaxRate) {
        general = other.general
        for (category, rate) in other.categories {
            categories[category] = rate
        }
    }
}
