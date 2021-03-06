import Foundation
import XCTest

import KauppaCore
@testable import KauppaAccountsModel
@testable import KauppaOrdersModel
@testable import KauppaOrdersRepository
@testable import KauppaOrdersService
@testable import KauppaProductsModel
@testable import KauppaTaxModel
@testable import TestTypes

class TestOrdersService: XCTestCase {
    let productsService = TestProductsService()
    var accountsService = TestAccountsService()
    var shippingService = TestShipmentsService()
    var couponService = TestCouponService()
    var taxService = TestTaxService()

    static var allTests: [(String, (TestOrdersService) -> () throws -> Void)] {
        return [
            ("Test successful order creation", testOrderCreation),
            ("Test order with invalid account", testOrderWithInvalidAccount),
            ("Test order with invalid product", testOrderWithInvalidProduct),
            ("Test order with unverified email", testOrderWithUnverifiedMail),
            ("Test order with ambiguous currencies", testOrderWithAmbiguousCurrencies),
            ("Test order with no products", testOrderWithNoProducts),
            ("Test order with product unavailable in inventory", testOrderWithUnavailableProduct),
            ("Test order zero quantity", testOrderWithZeroQuantity),
            ("Test order with one product having zero quantity", testOrderWithOneProductHavingZeroQuantity),
            ("Test order with duplicate products", testOrderWithDuplicateProducts),
            ("Test order with tax inclusive products", TestOrderWithTaxInclusiveProducts),
            ("Test order cancellation", testOrderCancellation),
            ("Test order deletion", testOrderDeletion),
        ]
    }

    override func setUp() {
        productsService.products = [:]
        accountsService = TestAccountsService()
        shippingService = TestShipmentsService()
        couponService = TestCouponService()
        taxService = TestTaxService()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // Test order creation - this should properly query the accounts service (for user account),
    // products service (for getting product details and updating inventory), shipping service
    // (for queuing the item for shipment), and coupon service (for checking gift cards, if any)
    func testOrderCreation() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        productData.inventory = 5
        productData.taxCategory = "food"
        productData.price = Price(3)
        productData.weight = UnitMeasurement(value: 5.0, unit: .gram)
        let product = try! productsService.createProduct(with: productData, from: Address())

        var anotherProductData = Product(title: "", subtitle: "", description: "")
        anotherProductData.inventory = 5
        anotherProductData.taxCategory = "drink"   // create another product with a different category
        anotherProductData.price = Price(4)
        anotherProductData.weight = UnitMeasurement(value: 5.0, unit: .gram)
        let anotherProduct = try! productsService.createProduct(with: anotherProductData, from: Address())

        var accountData = Account()
        // Two emails in customer account data.
        var emails = [Email("foo@bar.com"), Email("baz@bar.com")]
        emails[0].isVerified = true     // the first one is verified
        accountData.emails = ArraySet(emails)
        let account = try! accountsService.createAccount(with: accountData)

        var rate = TaxRate()
        rate.general = 15.0
        rate.categories["food"] = 10.0      // different tax rate for food
        taxService.rate = rate

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)
        let mailSent = expectation(description: "mail has been sent")
        let mailService = TestMailer(callback: { request in
            XCTAssertEqual(request.from, "orders@kauppa.com")
            // mail service receives only one recipient (which is the verified mail)
            XCTAssertEqual(request.to, ["foo@bar.com"])
            XCTAssertEqual(request.subject, "Your order has been placed")
            mailSent.fulfill()
        })

        // If we setup the mail service, then it's supposed to raise a mail request.
        ordersService.mailService = MailClient(with: mailService, mailsFrom: "orders@kauppa.com")
        let inventoryUpdated = expectation(description: "product inventory updated")
        productsService.callbacks[product.id!] = { patch in
            XCTAssertEqual(patch.inventory, 2)      // inventory amount changed
            inventoryUpdated.fulfill()
        }

        var unit = OrderUnit(for: product.id!, with: 3)
        unit.status = OrderUnitStatus(for: 5)      // try to set fulfilled quantity
        let nextUnit = OrderUnit(for: anotherProduct.id!, with: 2)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil,
                                  placedBy: account.id!, products: [unit, nextUnit])
        let order = try! ordersService.createOrder(with: orderData)
        // Make sure that the quantity is tracked while summing up values
        XCTAssertEqual(order.totalItems, 5)
        XCTAssertEqual(order.products[0].tax!.total.value, 0.9)
        XCTAssertEqual(order.products[0].netPrice!.value, 9)
        XCTAssertEqual(order.products[0].grossPrice!.value, 9.9)
        TestApproxEqual(order.products[1].tax!.total.value, 1.2)
        XCTAssertEqual(order.products[1].netPrice!.value, 8)
        XCTAssertEqual(order.products[1].grossPrice!.value, 9.2)
        XCTAssertEqual(order.totalWeight.value, 25.0)
        XCTAssertEqual(order.netPrice.value, 17.0)          // total price of items
        XCTAssertEqual(order.totalTax.value, 2.1)           // tax (0.9 + 0.6 * 2)
        XCTAssertEqual(order.grossPrice.value, 19.1)
        XCTAssertNotNil(order.billingAddress)
        XCTAssertNotNil(order.shippingAddress)
        XCTAssertEqual(order.products.count, 2)
        XCTAssertNil(order.products[0].status)      // status has been reset to nil

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }

    // An order placed from an account which doesn't have any verified mails.
    func testOrderWithUnverifiedMail() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        productData.inventory = 5
        productData.price = Price(3)
        let product = try! productsService.createProduct(with: productData, from: Address())

        var accountData = Account()
        accountsService.markAsVerified = false      // disable auto-enabling verification
        accountData.emails = ArraySet([Email("foo@bar.com")])
        let account = try! accountsService.createAccount(with: accountData)

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)

        let unit = OrderUnit(for: product.id!, with: 3)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil,
                                  placedBy: account.id!, products: [unit])
        do {
            let _ = try ordersService.createOrder(with: orderData)
            XCTFail()
        } catch let err {
            XCTAssertEqual(err as! ServiceError, ServiceError.unverifiedAccount)
        }
    }

    // An order with no product items should fail.
    func testOrderWithNoProducts() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)

        let account = try! accountsService.createAccount(with: Account())

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil,
                                  placedBy: account.id!, products: [])
        do {
            let _ = try ordersService.createOrder(with: orderData)
            XCTFail()
        } catch let err {   // no products - failure
            XCTAssertEqual(err as! ServiceError, ServiceError.noItemsToProcess)
        }
    }

    // An order should always be associated with a valid account.
    func testOrderWithInvalidAccount() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil,
                                  placedBy: UUID(), products: [])
        do {
            let _ = try ordersService.createOrder(with: orderData)
            XCTFail()
        } catch let err {
            XCTAssertEqual(err as! ServiceError, ServiceError.invalidAccountId)
        }
    }

    // An order should fail if its list of items has an invalid product.
    func testOrderWithInvalidProduct() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)

        let account = try! accountsService.createAccount(with: Account())

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)

        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id!,
                                  products: [OrderUnit(for: UUID(), with: 3)])
        do {
            let _ = try ordersService.createOrder(with: orderData)
            XCTFail()
        } catch let err {   // random UUID - invalid product
            XCTAssertEqual(err as! ServiceError, ServiceError.invalidProductId)
        }
    }

    // An order should fail if the product doesn't have enough items in the inventory.
    func testOrderWithUnavailableProduct() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        let productData = Product(title: "", subtitle: "", description: "")
        // By default, inventory has zero items
        let product = try! productsService.createProduct(with: productData, from: Address())

        let account = try! accountsService.createAccount(with: Account())
        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)

        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id!,
                                  products: [OrderUnit(for: product.id!, with: 3)])
        do {
            let _ = try ordersService.createOrder(with: orderData)
            XCTFail()
        } catch let err {   // no products - failure
            XCTAssertEqual(err as! ServiceError, ServiceError.productUnavailable)
        }
    }

    // An order with product items but with zero quantity should still fail.
    func testOrderWithZeroQuantity() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        productData.inventory = 5
        productData.price = Price(3)
        productData.weight = UnitMeasurement(value: 5.0, unit: .gram)
        let product = try! productsService.createProduct(with: productData, from: Address())

        let account = try! accountsService.createAccount(with: Account())

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)
        // Products with zero quantity will be skipped - in this case, that's the
        // only product, and hence it fails
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id!,
                                  products: [OrderUnit(for: product.id!, with: 0)])
        do {
            let _ = try ordersService.createOrder(with: orderData)
            XCTFail()
        } catch let err {
            XCTAssertEqual(err as! ServiceError, ServiceError.noItemsToProcess)
        }
    }

    // An order with one produt having zero quantity will be ignored.
    func testOrderWithOneProductHavingZeroQuantity() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        productData.inventory = 10
        let anotherProductData = productData

        let firstProduct = try! productsService.createProduct(with: productData, from: Address())
        let secondProduct = try! productsService.createProduct(with: anotherProductData,
                                                               from: Address())
        let account = try! accountsService.createAccount(with: Account())

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id!,
                                  products: [OrderUnit(for: firstProduct.id!, with: 3),
                                             OrderUnit(for: secondProduct.id!, with: 0)])
        let order = try! ordersService.createOrder(with: orderData)
        // Second product (zero quantity) will be skipped while placing the order
        XCTAssertEqual(order.totalItems, 3)
    }

    // An order with duplicated product items will still be tracked.
    func testOrderWithDuplicateProducts() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        productData.inventory = 10
        productData.price = Price(3)
        productData.weight = UnitMeasurement(value: 5.0, unit: .gram)
        let product = try! productsService.createProduct(with: productData, from: Address())

        let account = try! accountsService.createAccount(with: Account())

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)

        let inventoryUpdated = expectation(description: "product inventory updated")
        productsService.callbacks[product.id!] = { patch in
            XCTAssertEqual(patch.inventory, 4)
            inventoryUpdated.fulfill()
        }
        // Multiple quantities of the same product
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id!,
                                  products: [OrderUnit(for: product.id!, with: 3),
                                             OrderUnit(for: product.id!, with: 3)])
        let order = try! ordersService.createOrder(with: orderData)
        // All quantities are accumulated in the end
        XCTAssertEqual(order.totalItems, 6)
        XCTAssertEqual(order.totalWeight.value, 30.0)
        XCTAssertEqual(order.netPrice.value, 18.0)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    // Products that are inclusive of taxes shouldn't contribute to gross price in an order.
    func TestOrderWithTaxInclusiveProducts() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        productData.inventory = 5
        productData.taxCategory = "food"
        productData.taxInclusive = true
        productData.price = Price(3)
        productData.weight = UnitMeasurement(value: 5.0, unit: .gram)
        let product = try! productsService.createProduct(with: productData, from: Address())

        var anotherProductData = Product(title: "", subtitle: "", description: "")
        anotherProductData.inventory = 5
        anotherProductData.taxCategory = "drink"   // create another product with a different category
        anotherProductData.price = Price(4)
        anotherProductData.weight = UnitMeasurement(value: 5.0, unit: .gram)
        let anotherProduct = try! productsService.createProduct(with: anotherProductData, from: Address())

        var accountData = Account()
        var emails = [Email("foo@bar.com")]
        emails[0].isVerified = true     // the first one is verified
        accountData.emails = ArraySet(emails)
        let account = try! accountsService.createAccount(with: accountData)

        var rate = TaxRate()
        rate.general = 15.0
        rate.categories["food"] = 10.0      // different tax rate for food
        taxService.rate = rate

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)

        let units = [OrderUnit(for: product.id!, with: 3), OrderUnit(for: anotherProduct.id!, with: 2)]
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil,
                                  placedBy: account.id!, products: units)
        let order = try! ordersService.createOrder(with: orderData)
        // Make sure that the quantity is tracked while summing up values
        XCTAssertEqual(order.totalItems, 5)
        XCTAssertEqual(order.products[0].tax!.total.value, 0.9)
        XCTAssertTrue(order.products[0].tax!.inclusive)
        XCTAssertEqual(order.products[0].netPrice!.value, 9)
        XCTAssertEqual(order.products[0].grossPrice!.value, 9)
        TestApproxEqual(order.products[1].tax!.total.value, 1.2)
        XCTAssertFalse(order.products[1].tax!.inclusive)
        XCTAssertEqual(order.products[1].netPrice!.value, 8)
        XCTAssertEqual(order.products[1].grossPrice!.value, 9.2)
        XCTAssertEqual(order.netPrice.value, 17.0)      // total price of items
        TestApproxEqual(order.totalTax.value, 1.2)      // tax (0 + 0.6 * 2)
        XCTAssertEqual(order.grossPrice.value, 18.2)
    }

    // All items in the order should have the same currency - if they mismatch, then it's an error.
    func testOrderWithAmbiguousCurrencies() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        productData.price = Price(3)
        productData.inventory = 10
        let firstProduct = try! productsService.createProduct(with: productData, from: Address())

        var anotherData = Product(title: "", subtitle: "", description: "")
        anotherData.price = Price(3)
        anotherData.currency = .euro
        anotherData.inventory = 10
        let secondProduct = try! productsService.createProduct(with: anotherData, from: Address())

        let account = try! accountsService.createAccount(with: Account())
        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id!,
                                  products: [OrderUnit(for: firstProduct.id!, with: 3),
                                             OrderUnit(for: secondProduct.id!, with: 3)])
        do {
            let _ = try ordersService.createOrder(with: orderData)
            XCTFail()
        } catch let err {
            XCTAssertEqual(err as! ServiceError, ServiceError.ambiguousCurrencies)
        }
    }

    // Cancelling an order should update the `cancelledAt` timestamp.
    func testOrderCancellation() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        productData.inventory = 5
        let product = try! productsService.createProduct(with: productData, from: Address())

        let account = try! accountsService.createAccount(with: Account())

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id!,
                                  products: [OrderUnit(for: product.id!, with: 3)])
        let order = try! ordersService.createOrder(with: orderData)
        XCTAssertNil(order.cancelledAt)

        let updatedOrder = try! ordersService.cancelOrder(for: order.id)
        XCTAssertNotNil(updatedOrder.cancelledAt)
    }

    // Service should support deleting orders.
    func testOrderDeletion() {
        let store = TestStore()
        let repository = OrdersRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        productData.inventory = 5
        let product = try! productsService.createProduct(with: productData, from: Address())

        let account = try! accountsService.createAccount(with: Account())

        let ordersService = OrdersService(with: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          couponService: couponService,
                                          taxService: taxService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id!,
                                  products: [OrderUnit(for: product.id!, with: 3)])
        let order = try! ordersService.createOrder(with: orderData)
        let _ = try! ordersService.deleteOrder(for: order.id)
    }
}
