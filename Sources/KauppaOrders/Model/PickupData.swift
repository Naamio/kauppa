
import KauppaCore

/// Data required for initiating a pickup.
public struct PickupData: Mappable {
    /// Pickup all units in the order.
    public var pickupAll: Bool? = nil
    /// Pickup specified units in an order.
    public var units: [OrderUnit]? = nil
}
