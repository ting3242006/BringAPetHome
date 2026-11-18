//
//  BringAPetHomeTests.swift
//  BringAPetHomeTests
//
//  Created by Ting on 2022/7/20.
//

import CoreData
import XCTest
@testable import BringAPetHome

class BringAPetHomeTests: XCTestCase {

    var sut: URLSession!
    var shelterManager: ShelterManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = URLSession(configuration: .default)
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testApiCallCompletes() throws {
          // given
          let urlString = "https://data.moa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL"
          let url = URL(string: urlString)!
          let promise = expectation(description: "Completion handler invoked")
          var statusCode: Int?
          var responseError: Error?

          // when
          let dataTask = sut.dataTask(with: url) { _, response, error in
            statusCode = (response as? HTTPURLResponse)?.statusCode
            responseError = error
            promise.fulfill()
          }
          dataTask.resume()
          wait(for: [promise], timeout: 15)

          // then
          XCTAssertNil(responseError)
          XCTAssertEqual(statusCode, 200)
        }

    // decoder API 能不能裝進 shelterDataModel 裡面
    // 或檢查 API 跟專案裡的有沒有一樣

    func testApiStatusCode() throws {
        let url = URL(string: "https://data.moa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL")!
        let promise = expectation(description: "Status code: 200")

        sut.dataTask(with: url) { _, response, error in
            if let error = error {
                XCTFail("Error: \(error.localizedDescription)")
                return
            }
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if statusCode == 200 {
                    promise.fulfill()
                } else {
                    XCTFail("Status Code: \(statusCode)")
                }
            }
        }.resume()
        wait(for: [promise], timeout: 15)
    }

    @MainActor
    func testRemoveFavoriteUsesFull64BitID() throws {
        let context = try makeFavoriteContext()
        let targetID = 4_294_967_419
        try insertFavorite(id: 123, into: context)
        try insertFavorite(id: Int64(targetID), into: context)
        try context.save()

        XCTAssertTrue(FavoriteStore.remove(id: targetID, in: context))

        let verificationContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        verificationContext.persistentStoreCoordinator = context.persistentStoreCoordinator
        XCTAssertEqual(try verificationContext.fetch(Animal.fetchRequest()).map(\.id), [123])
    }

    @MainActor
    func testRemoveMissingFavoriteReturnsTrue() throws {
        let context = try makeFavoriteContext()

        XCTAssertTrue(FavoriteStore.remove(id: 123, in: context))
    }

    @MainActor
    func testRemoveFavoriteRollsBackWhenSaveFails() throws {
        let context = try makeFavoriteContext()
        try insertFavorite(id: 123, into: context)
        try context.save()
        context.failSaves = true

        XCTAssertFalse(FavoriteStore.remove(id: 123, in: context))
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try context.fetch(Animal.fetchRequest()).map(\.id), [123])
    }

    @MainActor
    func testRemoveFavoritePreservesPendingChanges() throws {
        let context = try makeFavoriteContext()
        try insertFavorite(id: 123, into: context)
        let otherFavorite = try insertFavorite(id: 456, into: context)
        try context.save()
        otherFavorite.place = "新北市"

        XCTAssertFalse(FavoriteStore.remove(id: 123, in: context))
        XCTAssertEqual(otherFavorite.changedValues()["place"] as? String, "新北市")
        XCTAssertEqual(try context.fetch(Animal.fetchRequest()).map(\.id).sorted(), [123, 456])
    }

    @MainActor
    @discardableResult
    private func insertFavorite(id: Int64, into context: NSManagedObjectContext) throws -> Animal {
        let entity = try XCTUnwrap(NSEntityDescription.entity(forEntityName: "Animal", in: context))
        let favorite = Animal(entity: entity, insertInto: context)
        favorite.id = id
        return favorite
    }

    @MainActor
    private func makeFavoriteContext() throws -> FavoriteTestContext {
        let bundle = Bundle(for: FavoriteStore.self)
        let modelURL = try XCTUnwrap(bundle.url(forResource: "AnimalData", withExtension: "momd"))
        let model = try XCTUnwrap(NSManagedObjectModel(contentsOf: modelURL))
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil)
        let context = FavoriteTestContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }

    func testShareMessageIncludesAnimalDetailsAndDeepLink() {
        let animal = AnimalData(animalId: 12345,
                                place: "臺北市",
                                kind: "貓",
                                sex: "F",
                                bodytype: "SMALL",
                                colour: "三花",
                                age: "CHILD",
                                status: "OPEN",
                                remark: "親人",
                                opendate: "2026-07-12",
                                shelterName: "臺北市動物之家",
                                albumFile: "https://example.com/cat.jpg",
                                shelterAddress: "臺北市信義區",
                                shelterTel: "02-12345678",
                                animalVariety: "混種貓",
                                areaPkid: 2,
                                animalSterilization: "F",
                                title: "",
                                cDate: "2026-07-11",
                                albumUpdate: "2026-07-11")

        let message = AnimalShareContentBuilder.message(for: animal)

        XCTAssertTrue(message.contains("我在 Bring A Pet Home 看到一隻正在等待認養的貓"))
        XCTAssertTrue(message.contains("性別：女"))
        XCTAssertTrue(message.contains("年齡：幼年"))
        XCTAssertTrue(message.contains("體型/品種：小型混種貓"))
        XCTAssertTrue(message.contains("毛色：三花"))
        XCTAssertTrue(message.contains("收容所：臺北市動物之家"))
        XCTAssertTrue(message.contains("電話：02-12345678"))
        XCTAssertTrue(message.contains("地址：臺北市信義區"))
        XCTAssertTrue(message.contains("開放認養：2026-07-12"))
        XCTAssertTrue(message.contains("bringapethome://animal/12345"))
    }

    func testAnimalDeepLinkParsesAnimalId() {
        let url = URL(string: "bringapethome://animal/12345")!

        XCTAssertEqual(AnimalDeepLink.animalId(from: url), 12345)
    }

    func testAnimalDeepLinkRejectsNonAnimalUrl() {
        let url = URL(string: "bringapethome://share/12345")!

        XCTAssertNil(AnimalDeepLink.animalId(from: url))
    }

    func testAnimalDeepLinkCarriesAnimalSnapshot() throws {
        let animal = AnimalData(animalId: 443673,
                                place: "新北市",
                                kind: "狗",
                                sex: "M",
                                bodytype: "MEDIUM",
                                colour: "黑色",
                                age: "ADULT",
                                status: "OPEN",
                                remark: "親人",
                                opendate: "2026-07-12",
                                shelterName: "新北市動物之家",
                                albumFile: "https://example.com/dog.jpg",
                                shelterAddress: "新北市板橋區",
                                shelterTel: "02-12345678",
                                animalVariety: "混種犬",
                                areaPkid: 3,
                                animalSterilization: "T",
                                title: "等待認養",
                                cDate: "2026-07-11",
                                albumUpdate: "2026-07-11")

        let url = try XCTUnwrap(AnimalDeepLink.url(for: animal))
        let route = try XCTUnwrap(AnimalDeepLink.route(from: url))

        XCTAssertEqual(route.animalId, 443673)
        XCTAssertEqual(route.animal?.shelterName, "新北市動物之家")
        XCTAssertEqual(route.animal?.remark, "親人")
        XCTAssertEqual(route.animal?.albumFile, "https://example.com/dog.jpg")
    }

    func testLegacyAnimalDeepLinkFallsBackToAnimalId() throws {
        let url = URL(string: "bringapethome://animal/443673")!

        let route = try XCTUnwrap(AnimalDeepLink.route(from: url))

        XCTAssertEqual(route.animalId, 443673)
        XCTAssertNil(route.animal)
    }

    func testShareActivityItemsExposeDeepLinkAsURL() {
        let animal = AnimalData(animalId: 12345,
                                place: "臺北市",
                                kind: "貓",
                                sex: "F",
                                bodytype: "SMALL",
                                colour: "三花",
                                age: "CHILD",
                                status: "OPEN",
                                remark: "親人",
                                opendate: "2026-07-12",
                                shelterName: "臺北市動物之家",
                                albumFile: "https://example.com/cat.jpg",
                                shelterAddress: "臺北市信義區",
                                shelterTel: "02-12345678",
                                animalVariety: "混種貓",
                                areaPkid: 2,
                                animalSterilization: "F",
                                title: "",
                                cDate: "2026-07-11",
                                albumUpdate: "2026-07-11")

        let items = AnimalShareContentBuilder.activityItems(for: animal)

        XCTAssertEqual(items.count, 2)
        XCTAssertNotNil(items[0] as? String)
        guard let deepLink = items[1] as? URL else {
            XCTFail("Share activity should expose the deep link as URL")
            return
        }
        XCTAssertEqual(AnimalDeepLink.route(from: deepLink)?.animalId, 12345)
        XCTAssertEqual(AnimalDeepLink.route(from: deepLink)?.animal?.shelterName, "臺北市動物之家")
    }

    func testDeepLinkPresentationStateKeepsAnimalUntilNavigationIsReady() {
        let animal = AnimalData(animalId: 12345,
                                place: "臺北市",
                                kind: "貓",
                                sex: "F",
                                bodytype: "SMALL",
                                colour: "三花",
                                age: "CHILD",
                                status: "OPEN",
                                remark: "親人",
                                opendate: "2026-07-12",
                                shelterName: "臺北市動物之家",
                                albumFile: "https://example.com/cat.jpg",
                                shelterAddress: "臺北市信義區",
                                shelterTel: "02-12345678",
                                animalVariety: "混種貓",
                                areaPkid: 2,
                                animalSterilization: "F",
                                title: "",
                                cDate: "2026-07-11",
                                albumUpdate: "2026-07-11")
        var state = DeepLinkPresentationState()

        XCTAssertNil(state.animalToPresent(animal, canPresent: false))
        XCTAssertTrue(state.hasPendingAnimal)
        XCTAssertEqual(state.pendingAnimalToPresent(canPresent: true)?.animalId, 12345)
        XCTAssertFalse(state.hasPendingAnimal)
    }
}

private final class FavoriteTestContext: NSManagedObjectContext, @unchecked Sendable {
    var failSaves = false

    override func save() throws {
        if failSaves {
            throw NSError(domain: NSCocoaErrorDomain, code: NSPersistentStoreSaveError)
        }
        try super.save()
    }
}
