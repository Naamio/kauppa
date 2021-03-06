import Foundation
import XCTest

import KauppaAccountsModel
@testable import KauppaCore
@testable import KauppaProductsModel
@testable import KauppaProductsRepository
@testable import KauppaProductsService

class TestProductAttributes: XCTestCase {
    var taxService = TestTaxService()

    static var allTests: [(String, (TestProductAttributes) -> () throws -> Void)] {
        return [
            ("Test attribute creation through products", testAttributeCreation),
            ("Test updating custom attribute values", testAttributeValueUpdates),
            ("Test enum variants creation", testEnumVariantsCreation),
        ]
    }

    override func setUp() {
        taxService = TestTaxService()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // Check that attributes can be created during product creation/update.
    func testAttributeCreation() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        let service = ProductsService(with: repository, taxService: taxService)
        var productData = Product(title: "foo", subtitle: "bar", description: "foobar")
        let baseProduct = try! service.createProduct(with: productData, from: Address())

        let validTests: [(String?, String?, String, String?)] = [
            ("surfaceArea", "area", "2", "sq. ft"),
            ("price", "currency", "3.75", "USD"),
            ("altitude", "length", "10", "km"),
            ("reducedWeight", "mass", "20", "kg"),
            ("someFount", "number", "127", nil),
            ("name", "string", "foobar", nil),
            ("fooExists", "boolean", "true", nil),
            ("boilingPoint", "temperature", "100", "C"),
            ("size", "volume", "2", "l")
        ]

        let invalidTests: [(String?, String?, String, String?)] = [
            (nil, "string", "booya", nil),
            ("", "area", "5", "sq. ft"),
            ("foo", "currency", "5", nil),
            ("boo", "length", "2", ""),
            ("something", "asdasdf", "20", nil)
        ]

        var tests = [(String?, String?, String, String?)]()
        tests.append(contentsOf: validTests)
        tests.append(contentsOf: invalidTests)

        for (i, (name, type, value, unit)) in tests.enumerated() {
            var attribute = CustomAttribute(with: value)
            attribute.name = name
            if let type = type {
                attribute.type = BaseType(rawValue: type)
            }

            attribute.unit = unit
            productData.custom = [attribute]

            let result1 = try? service.createProduct(with: productData, from: Address())

            var patch = ProductPatch()
            patch.custom = [attribute]
            let result2 = try? service.updateProduct(for: baseProduct.id!, with: patch, from: Address())

            if i < validTests.count {
                XCTAssertNotNil(result1)
                XCTAssertNotNil(result2)
            } else {
                XCTAssertNil(result1)
                XCTAssertNil(result2)
            }
        }
    }

    /// Check that existing attributes can be updated to new values.
    func testAttributeValueUpdates() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        let service = ProductsService(with: repository, taxService: taxService)
        var productData = Product(title: "foo", subtitle: "bar", description: "foobar")
        productData.custom = []

        let initialValues = [
            ("price", "currency", "3.75", "USD"),
            ("altitude", "length", "10", "km"),
            ("reducedWeight", "mass", "20", "kg"),
            ("someFount", "number", "127", nil),
            ("name", "string", "foobar", nil),
        ]

        for (name, type, value, unit) in initialValues {
            var attribute = CustomAttribute(with: value)
            attribute.name = name
            attribute.type = BaseType(rawValue: type)
            attribute.unit = unit
            productData.custom!.append(attribute)
        }

        let baseProduct = try! service.createProduct(with: productData, from: Address())
        for (i, (_, _, value, unit)) in initialValues.enumerated() {
            XCTAssertNil(baseProduct.custom![i].name)
            XCTAssertNotNil(baseProduct.custom![i].type)
            XCTAssertEqual(baseProduct.custom![i].value, value)
            XCTAssertEqual(baseProduct.custom![i].unit, unit)
        }

        let finalValues = [
            ("2.5", "EUR"),
            ("5", "km"),
            ("20", "lb"),
            ("255", nil),
            ("booya", nil)
        ]

        var attributes = [CustomAttribute]()
        for (oldAttr, (value, unit)) in zip(baseProduct.custom!, finalValues) {
            var attribute = CustomAttribute(with: value)
            attribute.unit = unit
            attribute.id = oldAttr.id
            attributes.append(attribute)
        }

        var patch = ProductPatch()
        patch.custom = attributes
        let updatedProduct = try! service.updateProduct(for: baseProduct.id!, with: patch, from: Address())

        for (i, (value, unit)) in finalValues.enumerated() {
            XCTAssertEqual(updatedProduct.custom![i].id, baseProduct.custom![i].id)
            XCTAssertNotNil(updatedProduct.custom![i].type)
            XCTAssertEqual(updatedProduct.custom![i].value, value)
            XCTAssertEqual(updatedProduct.custom![i].unit, unit)
        }
    }

    /// Test for possible errors in enum creation through products.
    func testEnumVariantsCreation() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        let service = ProductsService(with: repository, taxService: taxService)
        var productData = Product(title: "foo", subtitle: "bar", description: "foobar")

        var attribute = CustomAttribute(with: "bar")
        attribute.name = "foobar"
        attribute.type = BaseType(rawValue: "enum")
        productData.custom = [attribute]

        let tests: [(String, [String]?, ServiceError)] = [
            // no variants
            ("", nil,                       ServiceError.notEnoughVariants),
            // empty variant
            ("", ["", "booya"],             ServiceError.invalidEnumVariant),
            // single variant
            ("foo", ["foo"],                ServiceError.notEnoughVariants),
            // single variant after removing duplicates
            ("foo", ["foo", "fOO", "foO"],  ServiceError.notEnoughVariants),
            // value not in variants
            ("foo", ["bar", "baz"],         ServiceError.invalidAttributeValue)
        ]

        for (value, variants, error) in tests {
            productData.custom![0].value = value
            if let variants = variants {
                productData.custom![0].variants = ArraySet(variants)
            }

            do {
                let _ = try service.createProduct(with: productData, from: Address())
                XCTFail()
            } catch let err {
                XCTAssertEqual(err as! ServiceError, error)
            }
        }

        productData.custom![0].variants = ArraySet(["foo", "bar", "baz"])
        productData.custom![0].value = "Foo"
        let product = try! service.createProduct(with: productData, from: Address())
        XCTAssertNotNil(product.custom![0].id)
        XCTAssertEqual(product.custom![0].type, .enum_)
        XCTAssertEqual(product.custom![0].value, "foo")
    }
}
