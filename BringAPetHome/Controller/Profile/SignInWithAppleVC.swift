//
//  SignInViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/27.
//

import UIKit
import FirebaseAuth // 用來與 Firebase Auth 進行串接用的
import AuthenticationServices // Sign in with Apple 的主體框架
import CryptoKit // 用來產生隨機字串 (Nonce) 的
import AVFoundation
import Firebase

class SignInWithAppleVC: UIViewController {
    
    @IBOutlet var bgView: UIView!
    @IBOutlet weak var animatedIconImage: UIImageView!
    @IBOutlet weak var eulaButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    
    var appleUserID: String?
    var avPlayer: AVPlayer!
    var avPlayerLayer: AVPlayerLayer!
    var videoPlayer: AVPlayerLooper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setSignInWithAppleBtn()
        self.observeAppleIDState()
        self.checkAppleIDCredentialState(userID: appleUserID ?? "")
        
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.commitChanges(completion: { error in
            guard error == nil else {
                print(error?.localizedDescription)
                return
            }
        })
        
        // Do any additional setup after loading the view.
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                guard let vc = self.storyboard?.instantiateViewController(
                    withIdentifier: "HomeViewController") as? HomeViewController else {
                    fatalError("can't find HomeViewController")
                }
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                return
            }
        }
        playVideo()
    }
    
    deinit {
        videoPlayer = nil
    }
    
    override func viewDidLayoutSubviews() {
        bgView.layer.cornerRadius = 25
        let animatedImage = UIImage.animatedImageNamed("logo_1-", duration: 3.5)
        animatedIconImage.image = animatedImage
        animatedIconImage.layer.cornerRadius = 30
    }
    
    @IBAction func goPrivacyWeb(_ sender: Any) {
        let privacyVC = UINavigationController(rootViewController: PrivacyPolicyViewController())
        privacyVC.modalPresentationStyle = .fullScreen
        present(privacyVC, animated: true)
    }
    
    @IBAction func goEULAweb(_ sender: Any) {
        let eulaVC = UINavigationController(rootViewController: EULAViewController())
        eulaVC.modalPresentationStyle = .fullScreen
        present(eulaVC, animated: true)
    }
    
    @IBAction func closeButton(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func playVideo() {
        guard let path = Bundle.main.path(forResource: "pexels-cottonbro-6853336", ofType: "mp4") else { return }
        
        let player = AVQueuePlayer()
        let item = AVPlayerItem(url: URL(fileURLWithPath: path))
        videoPlayer = AVPlayerLooper(player: player, templateItem: item)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resize
        playerLayer.frame = bgView.layer.bounds
        bgView.layer.insertSublayer(playerLayer, at: 0)
        
        player.play()
    }
    
    // MARK: - 監聽目前的 Apple ID 的登入狀況
    // 主動監聽
    func checkAppleIDCredentialState(userID: String) {
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { credentialState, _ in
            switch credentialState {
            case .authorized:
                CustomFunc.customAlert(title: "使用者已授權！", message: "", vc: self, actionHandler: nil)
            case .revoked:
                CustomFunc.customAlert(title: "使用者憑證已被註銷！",
                                       message: "請到\n「設定 → Apple ID → 密碼與安全性 → 使用 Apple ID 的 App」\n將此 App 停止使用 Apple ID\n並再次使用 Apple ID 登入本 App！",
                                       vc: self, actionHandler: nil)
            case .transferred:
                CustomFunc.customAlert(title: "請與開發者團隊進行聯繫，以利進行使用者遷移！", message: "", vc: self, actionHandler: nil)
            default:
                break
            }
        }
    }
    
    // 被動監聽 (使用 Apple ID 登入或登出都會觸發)
    func observeAppleIDState() {
        NotificationCenter.default.addObserver(forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
                                               object: nil, queue: nil) { (notification: Notification) in
            CustomFunc.customAlert(title: "使用者登入或登出", message: "", vc: self, actionHandler: nil)
        }
    }
    
    // MARK: - 在畫面上產生 Sign in with Apple 按鈕
    func setSignInWithAppleBtn() {
        let signInWithAppleBtn = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn,
                                                              authorizationButtonStyle: chooseAppleButtonStyle())
        bgView.addSubview(signInWithAppleBtn)
        signInWithAppleBtn.cornerRadius = 25
        signInWithAppleBtn.addTarget(self, action: #selector(signInWithApple), for: .touchUpInside)
        signInWithAppleBtn.translatesAutoresizingMaskIntoConstraints = false
        signInWithAppleBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signInWithAppleBtn.widthAnchor.constraint(equalToConstant: 280).isActive = true
        signInWithAppleBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInWithAppleBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200).isActive = true
    }
    
    func chooseAppleButtonStyle() -> ASAuthorizationAppleIDButton.Style {
        return (UITraitCollection.current.userInterfaceStyle == .light) ? .black : .white // 淺色模式就顯示黑色的按鈕，深色模式就顯示白色的按鈕
    }
    
    // MARK: - Sign in with Apple 登入
    fileprivate var currentNonce: String?
    
    @objc func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while(remainingLength > 0) {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if (errorCode != errSecSuccess) {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if (remainingLength == 0) {
                    return
                }
                if (random < charset.count) {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

extension SignInWithAppleVC {
    // MARK: - 透過 Credential 與 Firebase Auth 串接
    func firebaseSignInWithApple(credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { authResult, error in
            guard error == nil else {
                CustomFunc.customAlert(title: "",
                                       message: "\(String(describing: error!.localizedDescription))",
                                       vc: self, actionHandler: nil)
                
                return
            }
            CustomFunc.customAlert(title: "登入成功！", message: "", vc: self, actionHandler: self.getFirebaseUserInfo)
        }
    }
    
    // MARK: - Firebase 取得登入使用者的資訊
    func getFirebaseUserInfo() {
        let currentUser = Auth.auth().currentUser
        guard let user = currentUser else {
            CustomFunc.customAlert(title: "無法取得使用者資料！", message: "", vc: self, actionHandler: nil)
            return
        }
        checkUserEmail(userId: Auth.auth().currentUser?.uid ?? "")

        self.dismiss(animated: true)
        presentingViewController?.viewWillAppear(true)
    }
        
    func checkUserEmail(userId: String) {
        print("checkUserEmail")
        let dataBase = Firestore.firestore()
        dataBase.collection("User").whereField("id", isEqualTo: userId).getDocuments { (querySnapshot, _) in
            
            if let querySnapshot = querySnapshot {
                if let document = querySnapshot.documents.first {
                    for data in querySnapshot.documents {
                    }
                    print("Account is exist")
                } else {
                    UserFirebaseManager.shared.addUser(name: "name",
                                                       uid: Auth.auth().currentUser?.uid ?? "",
                                                       email: Auth.auth().currentUser?.email ?? "",
                                                       image: "image", blockedUser: [""])
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
// 用來處理授權登入成功或是失敗
extension SignInWithAppleVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        // 登入成功
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                CustomFunc.customAlert(title: "",
                                       message: "Unable to fetch identity token",
                                       vc: self, actionHandler: nil)
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                CustomFunc.customAlert(title: "",
                                       message: "Unable to serialize token string from data\n\(appleIDToken.debugDescription)",
                                       vc: self, actionHandler: nil)
                return
            }
            // 產生 Apple ID 登入的 Credential
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString, rawNonce: nonce)
            // 與 Firebase Auth 進行串接
            firebaseSignInWithApple(credential: credential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // 登入失敗，處理 Error
        switch error {
        case ASAuthorizationError.canceled:
            CustomFunc.customAlert(title: "使用者取消登入", message: "", vc: self, actionHandler: nil)
            break
        case ASAuthorizationError.failed:
            CustomFunc.customAlert(title: "授權請求失敗", message: "", vc: self, actionHandler: nil)
            break
        case ASAuthorizationError.invalidResponse:
            CustomFunc.customAlert(title: "授權請求無回應", message: "", vc: self, actionHandler: nil)
            break
        case ASAuthorizationError.notHandled:
            CustomFunc.customAlert(title: "授權請求未處理", message: "", vc: self, actionHandler: nil)
            break
        case ASAuthorizationError.unknown:
            CustomFunc.customAlert(title: "授權失敗，原因不知", message: "", vc: self, actionHandler: nil)
            break
        default:
            break
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
// 在畫面上顯示授權畫面
extension SignInWithAppleVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
