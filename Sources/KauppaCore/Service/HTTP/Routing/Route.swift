/// Represents a service route. An incoming request that matches with a
/// registered route and method will be associated with a service call.
public struct Route: Hashable {
    /// URL of this route.
    public let url: String
    /// Methods allowed for this route.
    public let method: HTTPMethod

    public init(url: String, method: HTTPMethod) {
        self.url = url
        self.method = method
    }
}

/// Object that can be represented as a route. The route objects themselves are integers.
/// However, their computed values are "supposed" to return an unique route.
public protocol RouteRepresentable: RawRepresentable
    where RawValue == UInt8
{
    /// The route represented by this object.
    var route: Route { get }
}

extension RouteRepresentable {
    /// Default method for getting all the routes belonging to this object.
    /// This assumes that the object is an enum, and its variants haven't been
    /// initialized with unexpected integers.
    // FIXME: This won't be necessary once we upgrade to swift:4.2
    static var allRoutes: [Route] {
        var routes = [Route]()
        var count: UInt8 = 0
        while let variant = Self.init(rawValue: count) {
            routes.append(variant.route)
            count += 1
        }

        return routes
    }
}
