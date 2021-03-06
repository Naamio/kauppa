import Foundation

import KauppaCore
import KauppaOrdersModel
import KauppaShipmentsModel
import KauppaShipmentsClient

/// Router specific to the shipments service.
public class ShipmentsRouter<R: Routing>: ServiceRouter<R, ShipmentsRoutes> {
    let service: ShipmentsServiceCallable

    /// Initializes this router with a `Routing` object and
    /// an `ShipmentsServiceCallable` object.
    public init(with router: R, service: ShipmentsServiceCallable) {
        self.service = service
        super.init(with: router)
    }

    /// Overridden routes for shipments service.
    public override func initializeRoutes() {
        add(route: .createShipment) { request, response in
            guard let id: UUID = request.getParameter(for: "order") else {
                throw ServiceError.invalidOrderId
            }

            var items: [OrderUnit]? = nil
            if let list: MappableArray<OrderUnit> = request.getJSON() {
                items = list.inner
            }

            let shipment = try self.service.createShipment(for: id, with: items)
            try response.respondJSON(with: shipment)
        }

        add(route: .notifyShipping) { request, response in
            guard let id: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidOrderId
            }

            let shipment = try self.service.notifyShipping(for: id)
            try response.respondJSON(with: shipment)
        }

        add(route: .notifyDelivery) { request, response in
            guard let id: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidOrderId
            }

            let shipment = try self.service.notifyDelivery(for: id)
            try response.respondJSON(with: shipment)
        }

        add(route: .schedulePickup) { request, response in
            guard let id: UUID = request.getParameter(for: "order") else {
                throw ServiceError.invalidOrderId
            }

            guard let data: PickupItems = request.getJSON() else {
                throw ServiceError.clientHTTPData
            }

            let shipment = try self.service.schedulePickup(for: id, with: data)
            try response.respondJSON(with: shipment)
        }

        add(route: .completePickup) { request, response in
            guard let id: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidOrderId
            }

            let shipment = try self.service.completePickup(for: id)
            try response.respondJSON(with: shipment)
        }
    }
}
