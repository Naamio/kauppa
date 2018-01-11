import Foundation
import XCTest

import KauppaCore
import KauppaProductsModel
@testable import KauppaAccountsModel
@testable import KauppaOrdersModel
@testable import KauppaOrdersRepository
@testable import KauppaOrdersService

class TestOrdersService: XCTestCase {
    let productsService = TestProductsService()
    let accountsService = TestAccountsService()
    var shippingService = TestShipmentsService()
    var giftsService = TestGiftsService()

    static var allTests: [(String, (TestOrdersService) -> () throws -> Void)] {
        return [
            ("Test successful order creation", testOrderCreation),
            ("Test order with invalid account", testOrderWithInvalidAccount),
            ("Test order with invalid product", testOrderWithInvalidProduct),
            ("Test order with ambiguous currencies", testOrderWithAmbiguousCurrencies),
            ("Test order with no products", testOrderWithNoProducts),
            ("Test order with product unavailable in inventory", testOrderWithUnavailableProduct),
            ("Test order zero quantity", testOrderWithZeroQuantity),
            ("Test order with one product having zero quantity", testOrderWithOneProductHavingZeroQuantity),
            ("Test order with duplicate products", testOrderWithDuplicateProducts),
            ("Test order cancellation", testOrderCancellation),
            ("Test order deletion", testOrderDeletion),
        ]
    }

    override func setUp() {
        productsService.products = [:]
        accountsService.accounts = [:]
        shippingService = TestShipmentsService()
        giftsService = TestGiftsService()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // Test order creation - this should properly query the accounts service (for user account),
    // products service (for getting product details and updating inventory), shipping service
    // (for queuing the item for shipment), and gifts service (for checking gift cards, if any)
    func testOrderCreation() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)
        var productData = ProductData(title: "", subtitle: "", description: "")
        productData.inventory = 5
        productData.price = UnitMeasurement(value: 3.0, unit: .usd)
        productData.weight = UnitMeasurement(value: 5.0, unit: .gram)
        let product = try! productsService.createProduct(data: productData)

        var accountData = AccountData()
        accountData.email = "foo@bar.com"
        let account = try! accountsService.createAccount(withData: accountData)

        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)
        let mailSent = expectation(description: "mail has been sent")
        let mailService = TestMailer(callback: { request in
            XCTAssertEqual(request.from, "orders@kauppa.com")
            XCTAssertEqual(request.to, ["foo@bar.com"])
            XCTAssertEqual(request.subject, "Your order has been placed")
            mailSent.fulfill()
        })

        // If we setup the mail service, then it's supposed to raise a mail request.
        ordersService.mailService = MailClient(with: mailService, mailsFrom: "orders@kauppa.com")
        let inventoryUpdated = expectation(description: "product inventory updated")
        productsService.callbacks[product.id] = { patch in
            XCTAssertEqual(patch.inventory, 2)      // inventory amount changed
            inventoryUpdated.fulfill()
        }

        let shipmentInitiated = expectation(description: "shipment has been notified")
        shippingService.callback = { (id: Any) in
            let _ = id as! UUID
            shipmentInitiated.fulfill()
        }

        var unit = OrderUnit(product: product.id, quantity: 3)
        unit.status = OrderUnitStatus(quantity: 5)      // try to set fulfilled quantity
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil,
                                  placedBy: account.id, products: [unit])
        let order = try! ordersService.createOrder(data: orderData)
        // Make sure that the quantity is tracked while summing up values
        XCTAssertEqual(order.totalItems, 3)
        XCTAssertEqual(order.totalWeight.value, 15.0)
        XCTAssertEqual(order.totalPrice.value, 9.0)
        XCTAssertEqual(order.finalPrice.value, 9.0)
        XCTAssertNotNil(order.billingAddress)
        XCTAssertNotNil(order.shippingAddress)
        XCTAssertEqual(order.products.count, 1)
        XCTAssertNil(order.products[0].status)      // status has been reset to nil

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }

    // An order with no product items should fail.
    func testOrderWithNoProducts() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)

        let accountData = AccountData()
        let account = try! accountsService.createAccount(withData: accountData)

        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil,
                                  placedBy: account.id, products: [])
        do {
            let _ = try ordersService.createOrder(data: orderData)
            XCTFail()
        } catch let err {   // no products - failure
            XCTAssertEqual(err as! OrdersError, OrdersError.noItemsToProcess)
        }
    }

    // An order should always be associated with a valid account.
    func testOrderWithInvalidAccount() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)

        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil,
                                  placedBy: UUID(), products: [])
        do {
            let _ = try ordersService.createOrder(data: orderData)
            XCTFail()
        } catch let err {
            XCTAssertEqual(err as! AccountsError, AccountsError.invalidAccount)
        }
    }

    // An order should fail if its list of items has an invalid product.
    func testOrderWithInvalidProduct() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)

        let accountData = AccountData()
        let account = try! accountsService.createAccount(withData: accountData)

        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)

        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id,
                                  products: [OrderUnit(product: UUID(), quantity: 3)])
        do {
            let _ = try ordersService.createOrder(data: orderData)
            XCTFail()
        } catch let err {   // random UUID - invalid product
            XCTAssertEqual(err as! ProductsError, ProductsError.invalidProduct)
        }
    }

    // An order should fail if the product doesn't have enough items in the inventory.
    func testOrderWithUnavailableProduct() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)
        let productData = ProductData(title: "", subtitle: "", description: "")
        // By default, inventory has zero items
        let product = try! productsService.createProduct(data: productData)

        let accountData = AccountData()
        let account = try! accountsService.createAccount(withData: accountData)
        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)

        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id,
                                  products: [OrderUnit(product: product.id, quantity: 3)])
        do {
            let _ = try ordersService.createOrder(data: orderData)
            XCTFail()
        } catch let err {   // no products - failure
            XCTAssertEqual(err as! OrdersError, OrdersError.productUnavailable)
        }
    }

    // An order with product items but with zero quantity should still fail.
    func testOrderWithZeroQuantity() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)
        var productData = ProductData(title: "", subtitle: "", description: "")
        productData.inventory = 5
        productData.price = UnitMeasurement(value: 3.0, unit: .usd)
        productData.weight = UnitMeasurement(value: 5.0, unit: .gram)
        let product = try! productsService.createProduct(data: productData)

        let accountData = AccountData()
        let account = try! accountsService.createAccount(withData: accountData)

        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)
        // Products with zero quantity will be skipped - in this case, that's the
        // only product, and hence it fails
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id,
                                  products: [OrderUnit(product: product.id, quantity: 0)])
        do {
            let _ = try ordersService.createOrder(data: orderData)
            XCTFail()
        } catch let err {
            XCTAssertEqual(err as! OrdersError, OrdersError.noItemsToProcess)
        }
    }

    // An order with one produt having zero quantity will be ignored.
    func testOrderWithOneProductHavingZeroQuantity() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)
        var productData = ProductData(title: "", subtitle: "", description: "")
        productData.inventory = 10
        let anotherProductData = productData

        let firstProduct = try! productsService.createProduct(data: productData)
        let secondProduct = try! productsService.createProduct(data: anotherProductData)

        let accountData = AccountData()
        let account = try! accountsService.createAccount(withData: accountData)

        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id,
                                  products: [OrderUnit(product: firstProduct.id, quantity: 3),
                                             OrderUnit(product: secondProduct.id, quantity: 0)])
        let order = try! ordersService.createOrder(data: orderData)
        // Second product (zero quantity) will be skipped while placing the order
        XCTAssertEqual(order.totalItems, 3)
    }

    // An order with duplicated product items will still be tracked.
    func testOrderWithDuplicateProducts() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)
        var productData = ProductData(title: "", subtitle: "", description: "")
        productData.inventory = 10
        productData.price = UnitMeasurement(value: 3.0, unit: .usd)
        productData.weight = UnitMeasurement(value: 5.0, unit: .gram)
        let product = try! productsService.createProduct(data: productData)

        let accountData = AccountData()
        let account = try! accountsService.createAccount(withData: accountData)

        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)

        let inventoryUpdated = expectation(description: "product inventory updated")
        productsService.callbacks[product.id] = { patch in
            XCTAssertEqual(patch.inventory, 4)
            inventoryUpdated.fulfill()
        }
        // Multiple quantities of the same product
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id,
                                  products: [OrderUnit(product: product.id, quantity: 3),
                                             OrderUnit(product: product.id, quantity: 3)])
        let order = try! ordersService.createOrder(data: orderData)
        // All quantities are accumulated in the end
        XCTAssertEqual(order.totalItems, 6)
        XCTAssertEqual(order.totalWeight.value, 30.0)
        XCTAssertEqual(order.totalPrice.value, 18.0)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    // All items in the order should have the same currency - if they mismatch, then it's an error.
    func testOrderWithAmbiguousCurrencies() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)
        var productData = ProductData(title: "", subtitle: "", description: "")
        productData.price = UnitMeasurement(value: 3.0, unit: .usd)
        productData.inventory = 10

        let firstProduct = try! productsService.createProduct(data: productData)
        productData.price.unit = .euro
        let secondProduct = try! productsService.createProduct(data: productData)

        let accountData = AccountData()
        let account = try! accountsService.createAccount(withData: accountData)
        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id,
                                  products: [OrderUnit(product: firstProduct.id, quantity: 3),
                                             OrderUnit(product: secondProduct.id, quantity: 3)])
        do {
            let _ = try ordersService.createOrder(data: orderData)
            XCTFail()
        } catch let err {
            XCTAssertEqual(err as! OrdersError, OrdersError.ambiguousCurrencies)
        }
    }

    // Cancelling an order should update the `cancelledAt` timestamp.
    func testOrderCancellation() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)
        var productData = ProductData(title: "", subtitle: "", description: "")
        productData.inventory = 5
        let product = try! productsService.createProduct(data: productData)

        let accountData = AccountData()
        let account = try! accountsService.createAccount(withData: accountData)

        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id,
                                  products: [OrderUnit(product: product.id, quantity: 3)])
        let order = try! ordersService.createOrder(data: orderData)
        XCTAssertNil(order.cancelledAt)

        let updatedOrder = try! ordersService.cancelOrder(id: order.id)
        XCTAssertNotNil(updatedOrder.cancelledAt)
    }

    // Service should support deleting orders.
    func testOrderDeletion() {
        let store = TestStore()
        let repository = OrdersRepository(withStore: store)
        var productData = ProductData(title: "", subtitle: "", description: "")
        productData.inventory = 5
        let product = try! productsService.createProduct(data: productData)

        let accountData = AccountData()
        let account = try! accountsService.createAccount(withData: accountData)

        let ordersService = OrdersService(withRepository: repository,
                                          accountsService: accountsService,
                                          productsService: productsService,
                                          shippingService: shippingService,
                                          giftsService: giftsService)
        let orderData = OrderData(shippingAddress: Address(), billingAddress: nil, placedBy: account.id,
                                  products: [OrderUnit(product: product.id, quantity: 3)])
        let order = try! ordersService.createOrder(data: orderData)
        let _ = try! ordersService.deleteOrder(id: order.id)
    }
}
