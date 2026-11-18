import UIKit
import XCTest
@testable import BringAPetHome

final class UniversalLinkTests: XCTestCase {
    func testUniversalLinkParsesAnimalId() throws {
        let url = try XCTUnwrap(URL(string: "https://bringapethome.web.app/animal/443673"))
        XCTAssertEqual(AnimalDeepLink.animalId(from: url), 443673)
    }

    func testUniversalLinkAcceptsMixedCaseHost() throws {
        let url = try XCTUnwrap(URL(string: "https://BringAPetHome.web.app/animal/443673"))
        XCTAssertEqual(AnimalDeepLink.animalId(from: url), 443673)
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = url
        XCTAssertEqual(AnimalDeepLink.url(from: activity), url)
        let legacy = try XCTUnwrap(URL(string: "bringapethome://Animal/443673"))
        XCTAssertEqual(AnimalDeepLink.animalId(from: legacy), 443673)
    }

    func testUniversalLinkRejectsUntrustedOrMalformedURLs() throws {
        let invalidURLs = [
            "http://bringapethome.web.app/animal/123",
            "https://bringapethome.web.app.evil.example/animal/123",
            "https://evil.example/animal/123",
            "https://BringAPetHome.web.app.evil.example/animal/123",
            "https://BringAPetHome.web.app/Animal/123",
            "https://bringapethome.web.app@evil.example/animal/123",
            "https://someone@bringapethome.web.app/animal/123",
            "https://bringapethome.web.app:8443/animal/123",
            "https://bringapethome.web.app/animal/123/extra",
            "https://bringapethome.web.app/animal/0",
            "https://bringapethome.web.app/animal/-123",
            "https://bringapethome.web.app/animal/+123",
            "https://bringapethome.web.app/animal/999999999999999999999999999",
            "https://bringapethome.web.app/animal/not-a-number",
            "https://bringapethome.web.app/animal/%31%32%33",
            "https://bringapethome.web.app/animal/123/",
            "bringapethome://animal/123/extra"
        ]
        for invalidURL in invalidURLs {
            let url = try XCTUnwrap(URL(string: invalidURL))
            XCTAssertNil(AnimalDeepLink.route(from: url), invalidURL)
        }
    }

    func testBrowsingActivityRejectsOtherTypesAndUntrustedURLs() {
        let activity = NSUserActivity(activityType: "unrelated.activity")
        activity.webpageURL = URL(string: "https://bringapethome.web.app/animal/12345")
        XCTAssertNil(AnimalDeepLink.url(from: activity))
        let browsing = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        browsing.webpageURL = URL(string: "https://evil.example/animal/12345")
        XCTAssertNil(AnimalDeepLink.url(from: browsing))
        browsing.webpageURL = URL(string: "https://bringapethome.web.app/animal/12345")
        XCTAssertEqual(AnimalDeepLink.url(from: browsing), browsing.webpageURL)
    }

    @MainActor
    func testSceneReceivesBrowsingWebActivity() throws {
        let delegate = SceneDelegate()
        let window = UIWindow()
        let navigation = UINavigationController(rootViewController: UIViewController())
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        delegate.window = window
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first)
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://bringapethome.web.app/animal/12345")
        DeepLinkURLProtocol.responseData = try JSONEncoder().encode([makeLinkAnimal()])
        URLProtocol.registerClass(DeepLinkURLProtocol.self)
        defer { URLProtocol.unregisterClass(DeepLinkURLProtocol.self) }
        (delegate as UIWindowSceneDelegate).scene?(scene, continue: activity)
        let opened = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (navigation.topViewController as? HomeDetailViewController)?.pet?.animalId == 12345
        }, object: nil)
        wait(for: [opened], timeout: 3)
        window.isHidden = true
    }

    @MainActor
    func testSceneShowsLookupFailure() throws {
        let delegate = SceneDelegate()
        let window = UIWindow()
        let navigation = UINavigationController(rootViewController: UIViewController())
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        delegate.window = window
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first)
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://bringapethome.web.app/animal/12345")
        DeepLinkURLProtocol.responseData = Data("[]".utf8)
        URLProtocol.registerClass(DeepLinkURLProtocol.self)
        defer { URLProtocol.unregisterClass(DeepLinkURLProtocol.self) }
        (delegate as UIWindowSceneDelegate).scene?(scene, continue: activity)
        let failure = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (navigation.presentedViewController as? UIAlertController)?.title == "無法開啟動物資料"
        }, object: nil)
        wait(for: [failure], timeout: 3)
        navigation.dismiss(animated: false)
        window.isHidden = true
    }

    @MainActor
    func testSceneRetriesFailureAfterWindowAttaches() throws {
        let delegate = SceneDelegate()
        let window = UIWindow()
        let navigation = UINavigationController(rootViewController: UIViewController())
        window.rootViewController = navigation
        navigation.loadViewIfNeeded()
        delegate.window = window
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first)
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://bringapethome.web.app/animal/12345")
        DeepLinkURLProtocol.responseData = Data("[]".utf8)
        URLProtocol.registerClass(DeepLinkURLProtocol.self)
        defer { URLProtocol.unregisterClass(DeepLinkURLProtocol.self) }
        (delegate as UIWindowSceneDelegate).scene?(scene, continue: activity)
        let pending = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            delegate.failureRetryState.hasScheduledRetry
        }, object: nil)
        wait(for: [pending], timeout: 2)
        XCTAssertNil(navigation.viewIfLoaded?.window)
        for _ in 0..<3 { delegate.sceneDidBecomeActive(scene) }
        XCTAssertTrue(delegate.failureRetryState.hasScheduledRetry)
        window.makeKeyAndVisible()
        let failure = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (navigation.presentedViewController as? UIAlertController)?.title == "無法開啟動物資料"
        }, object: nil)
        wait(for: [failure], timeout: 3)
        XCTAssertFalse(delegate.failureRetryState.hasScheduledRetry)
        let alert = navigation.presentedViewController
        delegate.sceneDidBecomeActive(scene)
        XCTAssertTrue(navigation.presentedViewController === alert)
        navigation.dismiss(animated: false)
        window.isHidden = true
    }

    @MainActor
    func testNewLinkCancelsPendingFailureRetry() throws {
        let delegate = SceneDelegate()
        let window = UIWindow()
        let navigation = UINavigationController(rootViewController: UIViewController())
        window.rootViewController = navigation
        navigation.loadViewIfNeeded()
        delegate.window = window
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first)
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://bringapethome.web.app/animal/12345")
        DeepLinkURLProtocol.responseData = Data("[]".utf8)
        URLProtocol.registerClass(DeepLinkURLProtocol.self)
        defer { URLProtocol.unregisterClass(DeepLinkURLProtocol.self) }
        (delegate as UIWindowSceneDelegate).scene?(scene, continue: activity)
        let pending = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            delegate.failureRetryState.hasScheduledRetry
        }, object: nil)
        wait(for: [pending], timeout: 2)
        let oldToken = try XCTUnwrap(delegate.failureRetryState.scheduledToken)
        DeepLinkURLProtocol.responseData = try JSONEncoder().encode([makeLinkAnimal()])
        (delegate as UIWindowSceneDelegate).scene?(scene, continue: activity)
        XCTAssertFalse(delegate.failureRetryState.hasScheduledRetry)
        XCTAssertEqual(delegate.failureRetryState.attempts, 0)
        XCTAssertNotEqual(delegate.failureRetryState.scheduledToken, oldToken)
        window.makeKeyAndVisible()
        let opened = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            navigation.topViewController is HomeDetailViewController
        }, object: nil)
        wait(for: [opened], timeout: 3)
        XCTAssertNil(navigation.presentedViewController)
        window.isHidden = true
    }

    @MainActor
    func testSceneRetriesFailureAfterNavigationBecomesAvailable() throws {
        let delegate = SceneDelegate()
        let window = UIWindow()
        delegate.window = window
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first)
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://bringapethome.web.app/animal/12345")
        DeepLinkURLProtocol.responseData = Data("[]".utf8)
        URLProtocol.registerClass(DeepLinkURLProtocol.self)
        defer { URLProtocol.unregisterClass(DeepLinkURLProtocol.self) }
        (delegate as UIWindowSceneDelegate).scene?(scene, continue: activity)
        let pending = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            delegate.failureRetryState.hasScheduledRetry
        }, object: nil)
        wait(for: [pending], timeout: 2)
        let navigation = UINavigationController(rootViewController: UIViewController())
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        let failure = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            navigation.presentedViewController is UIAlertController
        }, object: nil)
        wait(for: [failure], timeout: 3)
        XCTAssertFalse(delegate.failureRetryState.hasScheduledRetry)
        navigation.dismiss(animated: false)
        window.isHidden = true
    }

    func testFailureRetryBudgetStopsAtTenScheduledAttempts() throws {
        var state = DeepLinkFailureRetryState()
        for attempt in 1...10 {
            let token = try XCTUnwrap(state.scheduleRetry())
            XCTAssertEqual(state.attempts, attempt)
            XCTAssertTrue(state.beginRetry(token: token))
        }
        XCTAssertNil(state.scheduleRetry())
        XCTAssertFalse(state.hasScheduledRetry)
        XCTAssertEqual(state.attempts, 10)
    }

    func testFailureRetryHasOnlyOneScheduledToken() throws {
        var state = DeepLinkFailureRetryState()
        let token = try XCTUnwrap(state.scheduleRetry())
        XCTAssertNil(state.scheduleRetry())
        XCTAssertEqual(state.attempts, 1)
        XCTAssertFalse(state.beginRetry(token: UUID()))
        XCTAssertEqual(state.scheduledToken, token)
        XCTAssertTrue(state.beginRetry(token: token))
        XCTAssertFalse(state.hasScheduledRetry)
    }

    func testOldRetryCannotClearNewRequestScheduledState() throws {
        var state = DeepLinkFailureRetryState()
        let oldToken = try XCTUnwrap(state.scheduleRetry())
        state.cancelScheduledRetry()
        state = DeepLinkFailureRetryState()
        let newToken = try XCTUnwrap(state.scheduleRetry())
        XCTAssertFalse(state.beginRetry(token: oldToken))
        XCTAssertEqual(state.scheduledToken, newToken)
        XCTAssertEqual(state.attempts, 1)
        XCTAssertTrue(state.beginRetry(token: newToken))
    }

    func testCancellingRetryDoesNotRefillExhaustedBudget() throws {
        var state = DeepLinkFailureRetryState()
        for _ in 0..<10 {
            _ = try XCTUnwrap(state.scheduleRetry())
            state.cancelScheduledRetry()
        }
        XCTAssertNil(state.scheduleRetry())
        XCTAssertEqual(state.attempts, 10)
    }

    private func makeLinkAnimal() -> AnimalData {
        AnimalData(animalId: 12345, place: "臺北市", kind: "貓", sex: "F", bodytype: "SMALL",
                   colour: "三花", age: "CHILD", status: "OPEN", remark: "親人", opendate: "2026-07-12",
                   shelterName: "臺北市動物之家", albumFile: "", shelterAddress: "臺北市信義區",
                   shelterTel: "02-12345678", animalVariety: "混種貓", areaPkid: 2,
                   animalSterilization: "F", title: "", cDate: "2026-07-11", albumUpdate: "2026-07-11")
    }
}

private class DeepLinkURLProtocol: URLProtocol {
    static var responseData = Data()

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "data.moa.gov.tw" && request.url?.query?.contains("animal_id=") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}
