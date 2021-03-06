import Foundation

import KauppaCore
import KauppaCartClient
import KauppaCartModel
import KauppaOrdersModel

/// Router specific to the cart service.
public class CartRouter<R: Routing>: ServiceRouter<R, CartRoutes> {
    let service: CartServiceCallable

    /// Initializes this router with a `Routing` object and a
    /// `CartServiceCallable` object.
    public init(with router: R, service: CartServiceCallable) {
        self.service = service
        super.init(with: router)
    }

    /// Overridden routes for cart service.
    public override func initializeRoutes() {
        add(route: .addItemToCart) { request, response in
            guard let id: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidAccountId
            }

            guard let unit: OrderUnit = request.getJSON() else {
                throw ServiceError.clientHTTPData
            }

            let cart = try self.service.addCartItem(for: id, with: unit, from: nil)
            try response.respondJSON(with: cart)
        }

        add(route: .removeItemFromCart) { request, response in
            guard let userId: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidAccountId
            }

            guard let itemId: UUID = request.getParameter(for: "item") else {
                throw ServiceError.invalidItemId
            }

            let cart = try self.service.removeCartItem(for: userId, with: itemId, from: nil)
            try response.respondJSON(with: cart)
        }

        add(route: .getCart) { request, response in
            guard let id: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidAccountId
            }

            let cart = try self.service.getCart(for: id, from: nil)
            try response.respondJSON(with: cart)
        }

        add(route: .updateCart) { request, response in
            guard let id: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidAccountId
            }

            guard let data: Cart = request.getJSON() else {
                throw ServiceError.clientHTTPData
            }

            let cart = try self.service.updateCart(for: id, with: data, from: nil)
            try response.respondJSON(with: cart)
        }

        add(route: .applyCoupon) { request, response in
            guard let id: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidAccountId
            }

            guard let data: CartCoupon = request.getJSON() else {
                throw ServiceError.clientHTTPData
            }

            let cart = try self.service.applyCoupon(for: id, using: data, from: nil)
            try response.respondJSON(with: cart)
        }

        add(route: .createCheckout) { request, response in
            guard let id: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidAccountId
            }

            guard let data: CheckoutData = request.getJSON() else {
                throw ServiceError.clientHTTPData
            }

            let cart = try self.service.createCheckout(for: id, with: data)
            try response.respondJSON(with: cart)
        }

        add(route: .placeOrder) { request, response in
            guard let id: UUID = request.getParameter(for: "id") else {
                throw ServiceError.invalidAccountId
            }

            let cart = try self.service.placeOrder(for: id)
            try response.respondJSON(with: cart)
        }
    }
}
