import Foundation

import KauppaCore
import KauppaProductsModel

/// Methods that mutate the underlying store with information.
public protocol ProductsPersisting: Persisting {
    /// Create a new product with the product information from repository.
    func createNewProduct(productData: Product) throws -> ()

    /// Delete a product corresponding to an ID.
    func deleteProduct(id: UUID) throws -> ()

    /// Update a product with the product information. ID will be obtained
    /// from the data.
    func updateProduct(productData: Product) throws -> ()

    /// Create a new collection with information from the repository.
    func createNewCollection(data: ProductCollection) throws -> ()

    /// Update an existing collection with data from repository.
    func updateCollection(data: ProductCollection) throws -> ()

    /// Delete a collection corresponding to an ID.
    func deleteCollection(id: UUID) throws -> ()
}