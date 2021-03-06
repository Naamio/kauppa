import Foundation

import KauppaCore
import KauppaAccountsModel
import KauppaCouponClient
import KauppaCouponModel
import KauppaOrdersModel
import KauppaProductsClient
import KauppaProductsModel
import KauppaShipmentsClient
import KauppaTaxClient
import KauppaTaxModel

/// Factory class for creating orders. This iterates over the list of products, verifies
/// that the products exist in the inventory, checks their currencies, updates the inventory,
///  validates coupons, calculates prices and finally places the order.
class OrdersFactory {
    let data: OrderData
    let account: Account
    let productsService: ProductsServiceCallable

    /// The `Order` struct that should be extracted once the factory has processed.
    private(set) var order: Order

    // Initial values required for keeping track of order properties during creation.
    private var productPrice = Price()
    private var priceUnit: Currency? = nil
    private var taxRate: TaxRate? = nil
    private var totalPrice = Price()
    private var totalTax = Price()
    private let weightCounter = WeightCounter()
    private var units = [DetailedUnit]()
    private var inventoryUpdates = [UUID: UInt32]()
    private var appliedCoupons = [Coupon]()

    /// Initialize this factory with the order data, account and product service.
    ///
    /// - Parameters:
    ///   - with: The `OrderData` source for placing the order.
    ///   - from: The `Account` which placed this order.
    ///   - using: Anything that implements `ProductsServiceCallable`
    init(with data: OrderData, from account: Account,
         using productsService: ProductsServiceCallable)
    {
        self.productsService = productsService
        self.data = data
        self.account = account
        order = Order(placedBy: account.id!)
    }

    /// Method to create an order using the provided data (entrypoint for factory production).
    ///
    /// - Parameters:
    ///   - using: Anything that implements `CouponServiceCallable`
    ///   - calculatingWith: Anything that implements `TaxServiceCallable`
    /// - Throws: `ServiceError`
    ///   - If there were no items
    ///   - If there was an error validating the coupons.
    ///   - If there was an error in queueing shipment.
    func createOrder(using couponService: CouponServiceCallable,
                     calculatingWith taxService: TaxServiceCallable) throws
    {
        taxRate = try taxService.getTaxRate(for: data.shippingAddress)
        for orderUnit in data.products {
            try feed(orderUnit)
        }

        try updateProductInventory()

        order.currency = priceUnit!
        order.placedBy = account.id!
        order.shippingAddress = data.shippingAddress
        order.billingAddress = data.billingAddress
        order.totalTax = totalTax
        order.netPrice = totalPrice
        order.totalWeight = weightCounter.sum()
        order.grossPrice = try applyCouponsOnPrice(using: couponService)

        try updateCoupons(using: couponService)
    }

    /// Method to create detailed order for mail service.
    ///
    /// - Returns: `DetailedOrder` with account, coupons and products information.
    ///
    /// NOTE: This should be called only after `createOrder(withShipping:)`
    func createOrder() -> DetailedOrder {
        var detailedOrder: DetailedOrder = GenericOrder(placedBy: account)
        detailedOrder.products = units
        detailedOrder.appliedCoupons = appliedCoupons
        order.copyValues(into: &detailedOrder)
        return detailedOrder
    }

    /// Step 1: Check that the product currency matches with other items' currencies.
    /// (This sets the current unit's price and the currency unit used throughout the order)
    private func checkCurrency(for product: Product) throws {
        productPrice = product.price
        if let unit = priceUnit {
            if unit != product.currency {
                throw ServiceError.ambiguousCurrencies
            }
        } else {
            priceUnit = product.currency
        }
    }

    /// Step 2: Update the dictionary which tracks individual products' inventory
    /// requirements. This should be called only by `feed`
    private func updateConsumedInventory(for product: Product,
                                         with unit: OrderUnit) throws
    {
        // Let's also check for duplicated product (if it exists in our dict)
        let available = inventoryUpdates[product.id!] ?? product.inventory
        if available < unit.quantity {
            throw ServiceError.productUnavailable
        }

        let leftover = available - UInt32(unit.quantity)
        inventoryUpdates[product.id!] = leftover
    }

    /// Step 3: Calculate tax and prices for a given order unit. This sets the tax rate,
    /// tax, net price and gross price for a give unit (meant to be called by `feed`).
    private func calculateUnitPrices(for unit: inout OrderUnit) {
        unit.netPrice = Price(Float(unit.quantity)) * productPrice
        unit.setPrices(using: taxRate!)
    }

    /// Final step: Update the counters which track the sum of values.
    private func updateCounters(for unit: OrderUnit, with product: Product) {
        totalPrice += unit.netPrice!
        if !unit.tax!.inclusive {   // Add tax only if product's tax is not inclusive
            totalTax += unit.tax!.total
        }

        var weight = product.weight ?? UnitMeasurement(value: 0.0, unit: .gram)
        weight.value *= Double(unit.quantity)
        weightCounter.add(weight)
        order.totalItems += UInt16(unit.quantity)
    }

    /// Feed an order unit to this factory. This checks each product, tracks inventory,
    /// sets the net price, gross price and tax for each unit and finally, it updates
    /// the weight, total price and item count.
    private func feed(_ unit: OrderUnit) throws {
        var unit = unit
        unit.resetInternalProperties()      // reset this unit
        if unit.quantity == 0 {        // skip zero'ed items
            return
        }

        let product = try productsService.getProduct(for: unit.product,
                                                     from: data.shippingAddress)
        try checkCurrency(for: product)
        try updateConsumedInventory(for: product, with: unit)
        unit.setTax(using: product.taxCategory)    // set the category for taxes
        unit.tax!.inclusive = product.taxInclusive ?? false
        calculateUnitPrices(for: &unit)

        order.products.append(unit)
        units.append(GenericOrderUnit(for: product, with: unit.quantity))
        updateCounters(for: unit, with: product)
    }

    /// Update all the products with their new inventory.
    private func updateProductInventory() throws {
        if inventoryUpdates.isEmpty {
            throw ServiceError.noItemsToProcess
        }

        for (id, leftover) in inventoryUpdates {
            var patch = ProductPatch()
            patch.inventory = leftover
            // FIXME: This shouldn't fail. If it does, the changes should be rolled back.
            let _ = try? productsService.updateProduct(for: id, with: patch,
                                                       from: data.shippingAddress)
        }
    }

    /// Apply the user-provided coupons to this order. This affects the `finalPrice`
    ///
    /// NOTE: This should be called only after `feed`ing all items.
    private func applyCouponsOnPrice(using couponService: CouponServiceCallable) throws -> Price {
        var finalPrice = totalPrice + totalTax
        for id in data.appliedCoupons {
            var coupon = try couponService.getCoupon(for: id)
            try coupon.data.deductPrice(from: &finalPrice, with: priceUnit!)
            appliedCoupons.append(coupon)
        }

        return finalPrice
    }

    /// Update the coupons after applying them in the order.
    private func updateCoupons(using couponService: CouponServiceCallable) throws {
        for (i, coupon) in appliedCoupons.enumerated() {
            var patch = CouponPatch()
            patch.balance = coupon.data.balance
            appliedCoupons[i] = try couponService.updateCoupon(for: coupon.id, with: patch)
        }
    }
}
