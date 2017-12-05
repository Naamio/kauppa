import Foundation

import KauppaProductsModel
import KauppaProductsStore

public class ProductsRepository {
    // FIXME: To avoid running out of memory, we should clean the
    // least recently used items every now and then.
    var products = [UUID: Product]()

    let store: ProductsStorable

    public init(withStore store: ProductsStorable) {
        self.store = store
    }

    /// Create product from the given product data.
    public func createProduct(data: ProductData) throws -> Product {
        let id = UUID()
        let date = Date()
        let product = Product(id: id, createdOn: date,
                              updatedAt: date, data: data)
        try self.store.createNewProduct(productData: product)
        products[id] = product
        return product
    }

    /// Delete the product corresponding to an ID.
    public func deleteProduct(id: UUID) throws -> () {
        products.removeValue(forKey: id)
        return try store.deleteProduct(id: id)
    }

    /// Get the product data corresponding to an ID.
    public func getProductData(id: UUID) throws -> ProductData {
        let product = try getProduct(id: id)
        return product.data
    }

    /// Update the product data for a given product ID.
    public func updateProductData(id: UUID, data: ProductData) throws -> Product {
        var product = try getProduct(id: id)
        let date = Date()
        product.updatedAt = date
        product.data = data
        products[id] = product
        try store.updateProduct(productData: product)
        return product
    }

    /// Fetch the whole product (from repository, if it's available, or store, if not).
    public func getProduct(id: UUID) throws -> Product {
        guard let product = products[id] else {
            let product = try store.getProduct(id: id)
            products[id] = product
            return product
        }

        return product
    }
}
