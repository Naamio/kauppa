import Foundation
import XCTest

@testable import KauppaTaxModel
@testable import KauppaTaxRepository

class TestTaxRepository: XCTestCase {
    static var allTests: [(String, (TestTaxRepository) -> () throws -> Void)] {
        return [
            ("Test country creation", testCountryCreation),
            ("Test country update", testCountryUpdate),
            ("Test country deletion", testCountryDeletion),
            ("Test region creation", testRegionCreation),
            ("Test region update", testRegionUpdate),
            ("Test region deletion", testRegionDeletion),
            ("Test store calls", testStoreCalls),
        ]
    }

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    /// Test country creation through repository. This should cache the data and call the store.
    func testCountryCreation() {
        let store = TestStore()
        let data = Country(name: "", taxRate: TaxRate())
        let repository = TaxRepository(with: store)
        try! repository.createCountry(with: data)   // validation happens in service
        XCTAssertTrue(store.createCountryCalled)    // store has been called for creation
    }

    /// Updating a country should change the timestamp, update cache, and should call the store.
    func testCountryUpdate() {
        let store = TestStore()
        var data = Country(name: "", taxRate: TaxRate())
        let repository = TaxRepository(with: store)
        try! repository.createCountry(with: data)
        data.name = "foo"
        let newData = try! repository.updateCountry(with: data)
        XCTAssertTrue(newData.createdOn != newData.updatedAt)
        // We're just testing the function calls (extensive testing is done in service)
        XCTAssertEqual(newData.name, "foo")
        XCTAssertTrue(store.updateCountryCalled)    // update called on store
    }

    /// Check that deleting a country deletes it from the cache and store.
    func testCountryDeletion() {
        let store = TestStore()
        let data = Country(name: "", taxRate: TaxRate())
        let repository = TaxRepository(with: store)
        try! repository.createCountry(with: data)
        XCTAssertFalse(repository.countries.isEmpty)
        XCTAssertFalse(repository.countryNames.isEmpty)
        try! repository.deleteCountry(for: data.id)
        XCTAssertTrue(repository.countries.isEmpty)
        XCTAssertTrue(repository.countryNames.isEmpty)
        XCTAssertTrue(store.deleteCountryCalled)
    }

    /// Test region creation through the repository. Ths should simply call the store,
    /// since there regions could be a lot to cache.
    func testRegionCreation() {
        let store = TestStore()
        let data = Region(name: "", taxRate: TaxRate(), kind: .city, country: UUID())
        let repository = TaxRepository(with: store)
        try! repository.createRegion(with: data)    // validation happens in service
        XCTAssertTrue(store.createRegionCalled)     // store called for creation
    }

    /// Updating a country should change the timestamp, update cache and should call the store.
    func testRegionUpdate() {
        let store = TestStore()
        var data = Region(name: "", taxRate: TaxRate(), kind: .city, country: UUID())
        let repository = TaxRepository(with: store)
        try! repository.createRegion(with: data)
        data.name = "foo"
        let newData = try! repository.updateRegion(with: data)
        XCTAssertTrue(newData.createdOn != newData.updatedAt)
        // We're just testing the function calls (extensive testing is done in service)
        XCTAssertEqual(newData.name, "foo")
        XCTAssertTrue(store.updateRegionCalled)
    }

    /// Check that deleting a region deletes it from the cache and store.
    func testRegionDeletion() {
        let store = TestStore()
        let data = Region(name: "", taxRate: TaxRate(), kind: .city, country: UUID())
        let repository = TaxRepository(with: store)
        try! repository.createRegion(with: data)
        XCTAssertFalse(repository.regions.isEmpty)
        try! repository.deleteRegion(for: data.id)
        XCTAssertTrue(repository.regions.isEmpty)
        XCTAssertTrue(store.deleteRegionCalled)
    }

    // Ensures that repository calls the store appropriately.
    func testStoreCalls() {
        let store = TestStore()
        let countryData = Country(name: "foo", taxRate: TaxRate())
        let repository = TaxRepository(with: store)
        try! repository.createCountry(with: countryData)
        repository.countries = [:]      // clear the repository
        let _ = try! repository.getCountry(id: countryData.id)
        XCTAssertTrue(store.getCountryCalled)   // this should've called the store
        store.getCountryCalled = false          // now, pretend that we never called the store
        let _ = try! repository.getCountry(id: countryData.id)
        // store shouldn't be called, because it was recently fetched by the repository
        XCTAssertFalse(store.getCountryCalled)

        repository.countryNames = [:]       // reset the names
        let _ = try! repository.getCountry(name: "foo")
        XCTAssertTrue(store.getCountryCalled)   // this should call the store
        store.getCountryCalled = false
        let _ = try! repository.getCountry(name: "foo")
        XCTAssertFalse(store.getCountryCalled)      // future `get` shouldn't call the store

        // similar events should happen for region
        let regionData = Region(name: "bar", taxRate: TaxRate(), kind: .city, country: countryData.id)
        try! repository.createRegion(with: regionData)
        repository.regions = [:]    // clear the repository
        let _ = try! repository.getRegion(for: regionData.id)
        XCTAssertTrue(store.getRegionCalled)
        store.getRegionCalled = false
        let _ = try! repository.getRegion(for: regionData.id)
        XCTAssertFalse(store.getRegionCalled)

        repository.countryNames = [:]       // reset the country names
        repository.regionNames = [:]        // and region names
        let _ = try! repository.getRegion(name: "bar", for: "foo")
        XCTAssertTrue(store.getCountryCalled)   // this should call the store for getting country name
        XCTAssertTrue(store.getRegionCalled)    // ... and region name.
        store.getCountryCalled = false
        store.getRegionCalled = false
        let _ = try! repository.getRegion(name: "bar", for: "foo")
        XCTAssertFalse(store.getCountryCalled)      // future `get` shouldn't call the store
        XCTAssertFalse(store.getRegionCalled)
    }
}
