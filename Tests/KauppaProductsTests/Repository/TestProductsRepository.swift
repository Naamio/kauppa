import Foundation
import XCTest

@testable import KauppaCore
@testable import KauppaProductsModel
@testable import KauppaProductsRepository
@testable import KauppaProductsStore

class TestProductsRepository: XCTestCase {

    static var allTests: [(String, (TestProductsRepository) -> () throws -> Void)] {
        return [
            ("Test product creation", testProductCreation),
            ("Test product deletion", testProductDeletion),
            ("Test update of product", testProductUpdate),
            ("Test collection creation", testCollectionCreation),
            ("Test collection update", testCollectionUpdate),
            ("Test collection deletion", testCollectionDeletion),
            ("Test store function calls", testProductStoreCalls),
            ("Test attribute store calls", testAttributeCalls),
            ("Test category store calls", testCategoryCalls),
        ]
    }

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    /// This doesn't carry any validation - it just ensures that the repository can create a
    /// product with necessary timestamps and calls the store.
    func testProductCreation() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        let product = Product(title: "", subtitle: "", description: "")
        let data = try! repository.createProduct(with: product)
        // These two timestamps should be the same in creation
        XCTAssertEqual(data.createdOn, data.updatedAt)
        XCTAssertTrue(store.createCalled)   // store has been called for creation
        XCTAssertNotNil(repository.products[data.id!])      // repository now has product data
    }

    /// Repository should call the store for product deletion and delete cached data.
    func testProductDeletion() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        let data = try! repository.createProduct(with: Product(title: "", subtitle: "", description: ""))
        let _ = try! repository.deleteProduct(for: data.id!)
        XCTAssertTrue(repository.products.isEmpty)      // repository shouldn't have the product
        XCTAssertTrue(store.deleteCalled)       // delete should've been called in store (by repository)
    }

    /// Updating a product should change the timestamp, update cache, and should call the store.
    func testProductUpdate() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        var product = Product(title: "", subtitle: "", description: "")
        let data = try! repository.createProduct(with: product)
        XCTAssertEqual(data.createdOn, data.updatedAt)
        product.title = "Foo"
        let updatedProduct = try! repository.updateProduct(with: product)
        // We're just testing the function calls (extensive testing is done in service)
        XCTAssertEqual(updatedProduct.title, "Foo")
        XCTAssertTrue(store.updateCalled)   // update called on store
    }

    /// Same thing as product creation - for colleciton (product IDs are checked by service).
    func testCollectionCreation() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        var productData = Product(title: "", subtitle: "", description: "")
        let product1 = try! repository.createProduct(with: productData)
        productData.color = "black"
        let product2 = try! repository.createProduct(with: productData)

        let collection = ProductCollectionData(name: "", description: "",
                                               products: [product1.id!, product2.id!])
        let data = try! repository.createCollection(with: collection)
        // These two timestamps should be the same in creation
        XCTAssertEqual(data.createdOn, data.updatedAt)
        XCTAssertTrue(store.collectionCreateCalled)     // store has been called for creation
        XCTAssertNotNil(repository.collections[data.id])    // repository now has collection data
    }

    /// Same as product update - for collection
    func testCollectionUpdate() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        var collection = ProductCollectionData(name: "", description: "", products: [])
        let data = try! repository.createCollection(with: collection)
        collection.name = "foo"
        let updatedCollection = try! repository.updateCollection(for: data.id, with: collection)
        // We're just testing the function calls (extensive testing is done in service)
        XCTAssertEqual(updatedCollection.data.name, "foo")
        XCTAssertTrue(store.collectionUpdateCalled)     // update called on store
    }

    /// Same as product deleteion - for collection
    func testCollectionDeletion() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        let collection = ProductCollectionData(name: "", description: "", products: [])
        let data = try! repository.createCollection(with: collection)
        let result: ()? = try? repository.deleteCollection(for: data.id)
        XCTAssertNotNil(result)
        XCTAssertTrue(repository.collections.isEmpty)   // repository shouldn't have the collection
        XCTAssertTrue(store.collectionDeleteCalled)     // delete should've been called in store
    }

    /// Ensures that product and collection repositories call the stores appropriately.
    func testProductStoreCalls() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        let product = try! repository.createProduct(with: Product(title: "", subtitle: "", description: ""))
        repository.products = [:]       // clear the repository
        let _ = try! repository.getProduct(for: product.id!)
        XCTAssertTrue(store.getCalled)  // this should've called the store
        store.getCalled = false         // now, pretend that we never called the store
        let _ = try! repository.getProduct(for: product.id!)
        // store shouldn't be called, because it was recently fetched by the repository
        XCTAssertFalse(store.getCalled)

        let collection = ProductCollectionData(name: "", description: "", products: [product.id!])
        let data = try! repository.createCollection(with: collection)
        repository.collections = [:]    // clear the repository
        let _ = try! repository.getCollection(for: data.id)
        XCTAssertTrue(store.collectionGetCalled)    // store should've been called
        store.collectionGetCalled = false       // pretend that store hasn't been called
        let _ = try! repository.getCollection(for: data.id)
        // store shouldn't be called, because it was recently fetched by the repository
        XCTAssertFalse(store.collectionGetCalled)
    }

    /// Test that attribute creation and getting properly calls store.
    func testAttributeCalls() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        let attribute = try! repository.createAttribute(with: "FOO", and: .enum_,
                                                        variants: ArraySet(["Bar", "Baz"]))
        XCTAssertNotNil(attribute.variants)
        XCTAssertEqual(attribute.variants!.inner, ["bar", "baz"])
        XCTAssertEqual(attribute.name, "foo")

        repository.attributes = [:]
        XCTAssertFalse(store.attributeGetCalled)
        let _ = try! repository.getAttribute(for: attribute.id)
        XCTAssertTrue(store.attributeGetCalled)

        store.attributeGetCalled = false
        let _ = try! repository.getAttribute(for: attribute.id)
        XCTAssertFalse(store.attributeGetCalled)
    }

    /// Test that category creation and getting properly calls store.
    func testCategoryCalls() {
        let store = TestStore()
        let repository = ProductsRepository(with: store)
        let category = try! repository.createCategory(with: Category(name: "fOOBar"))
        XCTAssertTrue(store.categoryCreationCalled)
        XCTAssertNotNil(category.id)
        XCTAssertNotNil(category.name)
        XCTAssertEqual(category.name!, "foobar")

        repository.categories = [:]
        XCTAssertFalse(store.categoryGetCalled)
        let _ = try! repository.getCategory(for: category.id!)
        XCTAssertTrue(store.categoryGetCalled)

        store.categoryGetCalled = false
        repository.categoryNames = [:]
        let _ = try! repository.getCategory(for: category.name!)
        XCTAssertTrue(store.categoryGetCalled)

        store.categoryGetCalled = false
        let _ = try! repository.getCategory(for: category.id!)
        XCTAssertFalse(store.categoryGetCalled)
        let _ = try! repository.getCategory(for: category.name!)
        XCTAssertFalse(store.categoryGetCalled)
    }
}
