import Foundation

import KauppaCore
import KauppaAccountsModel
import KauppaCartModel
import KauppaOrdersModel
import KauppaShipmentsModel
import KauppaShipmentsStore

/// Manages the retrieval and persistance of shipment data from store.
public class ShipmentsRepository {
    // FIXME: To avoid running out of memory, we should clean the
    // least recently used items every now and then.
    var shipments = [UUID: Shipment]()
    var store: ShipmentsStorable

    public init(withStore store: ShipmentsStorable) {
        self.store = store
    }

    /// Create a shipment object for an order.
    public func createShipment(forOrder id: UUID, address: Address, items: [CartUnit],
                               status: ShipmentStatus? = nil) throws -> Shipment
    {
        let date = Date()
        var data = Shipment(id: UUID(), createdOn: date, updatedAt: date,
                            orderId: id, address: address)
        data.items = items
        if let status = status {
            data.status = status
        }

        try store.createShipment(data: data)
        shipments[data.id] = data
        return data
    }

    /// Get the shipment for a given ID.
    public func getShipment(id: UUID) throws -> Shipment {
        guard let shipment = shipments[id] else {
            let data = try store.getShipment(id: id)
            shipments[id] = data
            return data
        }

        return shipment
    }

    /// Update shipment with data from the service.
    public func updateShipment(data: Shipment) throws -> Shipment {
        var shipment = data
        shipment.updatedAt = Date()
        shipments[data.id] = shipment
        try store.updateShipment(data: shipment)
        return shipment
    }
}