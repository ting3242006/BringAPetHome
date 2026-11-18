//
//  SceneDelegate.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/14.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var deepLinkPresentationState = DeepLinkPresentationState()
    private var deepLinkRequestID = UUID()
    private weak var deepLinkFailureAlert: UIAlertController?
    private(set) var failureRetryState = DeepLinkFailureRetryState()
    private var failureRetryWorkItem: DispatchWorkItem?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        let universalLink = connectionOptions.userActivities.compactMap(AnimalDeepLink.url(from:)).first
        guard let url = universalLink ?? connectionOptions.urlContexts.first?.url else { return }
        DispatchQueue.main.async { [weak self] in
            self?.handleDeepLink(url: url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        guard let url = urlContexts.first?.url else { return }
        handleDeepLink(url: url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = AnimalDeepLink.url(from: userActivity) else { return }
        handleDeepLink(url: url)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        retryPendingDeepLinkPresentation()
        presentPendingDeepLinkFailure()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    private func handleDeepLink(url: URL) {
        guard let route = AnimalDeepLink.route(from: url) else { return }
        let requestID = UUID()
        deepLinkRequestID = requestID
        cancelFailureRetry()
        failureRetryState = DeepLinkFailureRetryState()
        deepLinkPresentationState = DeepLinkPresentationState()
        deepLinkFailureAlert?.dismiss(animated: false)
        if let animal = route.animal {
            showAnimalDetail(animal)
            return
        }
        if let animal = loadedAnimal(id: route.animalId) {
            showAnimalDetail(animal)
            return
        }

        ShelterManager.shared.fetchAnimal(id: route.animalId) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.deepLinkRequestID == requestID else { return }
                switch result {
                case .success(let animal):
                    self.showAnimalDetail(animal)
                case .failure(let error):
                    print("Deep link animal fetch failed:", error)
                    self.deepLinkPresentationState.hasPendingFailure = true
                    self.presentPendingDeepLinkFailure()
                }
            }
        }
    }

    private func loadedAnimal(id animalId: Int) -> AnimalData? {
        navigationControllerForDeepLink()?
            .viewControllers
            .compactMap { $0 as? HomeViewController }
            .first?
            .animalDatas
            .first(where: { $0.animalId == animalId })
    }

    private func showAnimalDetail(_ animal: AnimalData) {
        guard let navigationController = navigationControllerForDeepLink() else {
            _ = deepLinkPresentationState.animalToPresent(animal, canPresent: false)
            retryPendingDeepLinkPresentation()
            return
        }

        _ = deepLinkPresentationState.animalToPresent(animal, canPresent: true)
        pushAnimalDetail(animal, on: navigationController)
    }

    private func retryPendingDeepLinkPresentation() {
        guard deepLinkPresentationState.hasPendingAnimal else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            if let navigationController = self.navigationControllerForDeepLink(),
               let animal = self.deepLinkPresentationState.pendingAnimalToPresent(canPresent: true) {
                self.pushAnimalDetail(animal, on: navigationController)
            }
        }
    }

    private func scheduleFailureRetry() {
        guard deepLinkPresentationState.hasPendingFailure,
              let token = failureRetryState.scheduleRetry() else { return }
        let requestID = deepLinkRequestID
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self,
                  self.deepLinkRequestID == requestID,
                  self.failureRetryState.beginRetry(token: token) else { return }
            self.failureRetryWorkItem = nil
            self.presentPendingDeepLinkFailure()
        }
        failureRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func cancelFailureRetry() {
        failureRetryWorkItem?.cancel()
        failureRetryWorkItem = nil
        failureRetryState.cancelScheduledRetry()
    }

    private func presentPendingDeepLinkFailure() {
        guard deepLinkPresentationState.hasPendingFailure else { return }
        guard let navigationController = navigationControllerForDeepLink(),
              navigationController.viewIfLoaded?.window != nil else {
            scheduleFailureRetry()
            return
        }
        var presenter: UIViewController = navigationController
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        guard !presenter.isBeingDismissed, !presenter.isBeingPresented else {
            scheduleFailureRetry()
            return
        }
        deepLinkPresentationState.hasPendingFailure = false
        cancelFailureRetry()
        let alert = UIAlertController(
            title: "無法開啟動物資料",
            message: "請確認網路連線後再試一次；這隻動物的資料也可能已下架。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        deepLinkFailureAlert = alert
        presenter.present(alert, animated: true)
    }

    private func pushAnimalDetail(_ animal: AnimalData, on navigationController: UINavigationController) {
        if let detailVC = navigationController.topViewController as? HomeDetailViewController,
           detailVC.pet?.animalId == animal.animalId {
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailVC = storyboard.instantiateViewController(
            withIdentifier: "HomeDetailViewController"
        ) as? HomeDetailViewController else { return }

        detailVC.pet = animal
        navigationController.pushViewController(detailVC, animated: true)
    }

    private func navigationControllerForDeepLink() -> UINavigationController? {
        if let tabBarController = window?.rootViewController as? UITabBarController {
            tabBarController.loadViewIfNeeded()
            let homeNavigationController = tabBarController.viewControllers?
                .compactMap { $0 as? UINavigationController }
                .first { $0.viewControllers.first is HomeViewController }
            if let homeNavigationController = homeNavigationController {
                homeNavigationController.loadViewIfNeeded()
                tabBarController.selectedViewController = homeNavigationController
                return homeNavigationController
            }
            return tabBarController.selectedViewController as? UINavigationController
        }
        return window?.rootViewController as? UINavigationController
    }
}

struct DeepLinkPresentationState {
    private var pendingAnimal: AnimalData?
    var hasPendingFailure = false

    var hasPendingAnimal: Bool {
        pendingAnimal != nil
    }

    mutating func animalToPresent(_ animal: AnimalData, canPresent: Bool) -> AnimalData? {
        guard canPresent else {
            pendingAnimal = animal
            return nil
        }

        pendingAnimal = nil
        return animal
    }

    mutating func pendingAnimalToPresent(canPresent: Bool) -> AnimalData? {
        guard canPresent, let pendingAnimal = pendingAnimal else { return nil }

        self.pendingAnimal = nil
        return pendingAnimal
    }
}

struct DeepLinkFailureRetryState {
    private(set) var attempts = 0
    private(set) var scheduledToken: UUID?

    var hasScheduledRetry: Bool {
        scheduledToken != nil
    }

    mutating func scheduleRetry() -> UUID? {
        guard attempts < 10, scheduledToken == nil else { return nil }
        attempts += 1
        let token = UUID()
        scheduledToken = token
        return token
    }

    mutating func beginRetry(token: UUID) -> Bool {
        guard scheduledToken == token else { return false }
        scheduledToken = nil
        return true
    }

    mutating func cancelScheduledRetry() {
        scheduledToken = nil
    }
}
