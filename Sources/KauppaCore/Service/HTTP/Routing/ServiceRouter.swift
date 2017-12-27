/// Router for individual services of Kauppa.
///
/// The `Routing` protocol is usually implemented for a third-party router. But, that router
/// (by itself) should not be used across Kauppa's service-specific routers, because this exposes
/// the actual router's public resources, and it also results in tight coupling (because request and
/// response types are specific to routers, and service routers need to alias these).
///
/// To avoid this nightmare, we use this class - which acts as an abstraction over the router.
/// Service-specific routers extend from this class and can use only the publicly exposed resources.
open class ServiceRouter<R: Routing> {
    public typealias Request = R.Request
    public typealias Response = R.Response

    private let router: R

    /// Initialize the router for this service. Note that this also initializes the routes
    /// necessary for the service by calling the overridable method `initializeRoutes`.
    public init(with router: R) {
        self.router = router
        self.initializeRoutes()
    }

    /// Stub. Child classes should override this function with their own set of routes.
    open func initializeRoutes() {}

    /// Wrapper for the actual route addition. Although this has the same signature as
    /// `add` method from `Routing` protocol, this  converts the throwable closure
    /// into a non-throwable one, by catching the error and encoding it appropriately
    /// as a `ServiceStatusMessage` object with the error code.
    ///
    /// - Parameters:
    ///   - route: A `RouteRepresentable` object.
    ///   - The closure which gets the associated request and response object from the service call.
    public func add<R>(route repr: R, _ handler: @escaping (Request, Response) throws -> Void)
        where R: RouteRepresentable
    {
        self.router.add(route: repr) { request, response in
            do {
                try handler(request, response)
            } catch let error as ServiceError {
                let status = ServiceStatusMessage(error: error)
                response.respondJSON(with: status, code: error.statusCode)
            } catch {
                let error = ServiceError.unknownError
                // TODO: Log unknown error
                let status = ServiceStatusMessage(error: error)
                response.respondJSON(with: status, code: error.statusCode)
            }
        }
    }
}
