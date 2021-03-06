import Foundation
import XCTest

import KauppaCore
import KauppaAccountsModel
import KauppaProductsClient
import KauppaProductsModel

public typealias ProductsCallback = (ProductPatch) -> Void

public class TestProductsService: ProductsServiceCallable {
    var products = [UUID: Product]()
    var callbacks = [UUID: ProductsCallback]()

    public func createProduct(with data: Product, from address: Address?) throws -> Product {
        products[data.id!] = data
        return data
    }

    public func getProduct(for id: UUID, from address: Address?) throws -> Product {
        guard let product = products[id] else {
            throw ServiceError.invalidProductId
        }

        return product
    }

    // NOTE: Not meant to be called by orders
    public func getAttributes() throws -> [Attribute] {
        return []
    }

    // NOTE: Not meant to be called by orders
    public func getCategories() throws -> [Category] {
        return []
    }

    // NOTE: Not meant to be called by orders
    public func getProducts() throws -> [Product] {
        return []
    }

    // NOTE: Not meant to be called by orders
    public func deleteProduct(for id: UUID) throws -> () {
        throw ServiceError.invalidProductId
    }

    public func updateProduct(for id: UUID, with data: ProductPatch,
                              from address: Address?) throws -> Product
    {
        if let callback = callbacks[id] {
            callback(data)
        }

        return try getProduct(for: id, from: nil)       // This is just a stub
    }

    // NOTE: Not meant to be called by orders
    public func addProductProperty(for id: UUID, with data: ProductPropertyAdditionPatch,
                                   from address: Address?) throws -> Product
    {
        throw ServiceError.invalidProductId
    }

    // NOTE: Not meant to be called by orders
    public func deleteProductProperty(for id: UUID, with data: ProductPropertyDeletionPatch,
                                      from address: Address?) throws -> Product
    {
        throw ServiceError.invalidProductId
    }

    // NOTE: Not meant to be called by orders
    public func createCollection(with data: ProductCollectionData) throws -> ProductCollection {
        throw ServiceError.invalidCollectionId
    }

    // NOTE: Not meant to be called by cart
    public func getCollection(for id: UUID) throws -> ProductCollection {
        throw ServiceError.invalidCollectionId
    }

    // NOTE: Not meant to be called by orders
    public func updateCollection(for id: UUID, with data: ProductCollectionPatch) throws -> ProductCollection {
        throw ServiceError.invalidCollectionId
    }

    // NOTE: Not meant to be called by orders
    public func deleteCollection(for id: UUID) throws -> () {
        throw ServiceError.invalidCollectionId
    }

    // NOTE: Not meant to be called by orders
    public func addProduct(to id: UUID, using data: ProductCollectionItemPatch) throws -> ProductCollection {
        throw ServiceError.invalidCollectionId
    }

    // NOTE: Not meant to be called by orders
    public func removeProduct(from id: UUID, using data: ProductCollectionItemPatch) throws -> ProductCollection {
        throw ServiceError.invalidCollectionId
    }
}
