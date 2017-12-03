import Foundation

import KauppaOrdersModel
import KauppaOrdersStore

public class OrdersRepository {
    // FIXME: To avoid running out of memory, we should clean the
    // least recently used items every now and then.
    var orders = [UUID: Order]()

    let store: OrdersStore

    public init(withStore store: OrdersStore) {
        self.store = store
    }

    public func createOrder(withData data: Order) -> Order? {
        let id = UUID()
        let date = Date()
        var data = data
        data.id = id
        data.createdOn = date
        data.updatedAt = date

        orders[id] = data
        store.createNewOrder(orderData: data)
        return data
    }
}
