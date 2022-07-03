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


class SignInWithAppleVC: UIViewController {
    
    @IBOutlet var bgView: UIView!
    var appleUserID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bgView.layer.cornerRadius = 25
        self.setSignInWithAppleBtn()
        self.observeAppleIDState()
        self.checkAppleIDCredentialState(userID: appleUserID ?? "")
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                print("\(user.uid) login")
            } else {
                print("not login")
            }
        }
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        //        changeRequest?.photoURL = URL(string: "https://images.pexels.com/photos/1170986/pexels-photo-1170986.jpeg")
        //        changeRequest?.displayName = "帥哥"
        changeRequest?.commitChanges(completion: { error in
            guard error == nil else {
                print(error?.localizedDescription)
                return
            }
            
        })
        //        if let user = Auth.auth().currentUser {
        //           print(user.uid, user.email, user.displayName, user.photoURL)
        //        }
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
    }
    
    @IBAction func closeButton(_ sender: Any) {
        dismiss(animated: true)
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
                //            case .notFound:
                //                CustomFunc.customAlert(title: "", message: "使用者尚未使用過 Apple ID 登入！", vc: self, actionHandler: nil)
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
    //    @IBAction func closeLogin(_ sender: Any) {
    //        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    //        guard let homeVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
    //        self.navigationController?.pushViewController(homeVC, animated: true)
    //    }
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
            let tabController =  self.view.window?.rootViewController as? UITabBarController
            self.dismiss(animated: false) {
                tabController?.selectedIndex = 0
            }
            
//            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            guard let homeVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
//            self.navigationController?.pushViewController(homeVC, animated: true)
        }
    }
    
    // MARK: - Firebase 取得登入使用者的資訊
    func getFirebaseUserInfo() {
        let currentUser = Auth.auth().currentUser
        guard let user = currentUser else {
            CustomFunc.customAlert(title: "無法取得使用者資料！", message: "", vc: self, actionHandler: nil)
            return
        }
        //        let name = user.displayName
        let uid = user.uid
        let email = user.email
        //        let image = user.
        //        CustomFunc.customAlert(title: "使用者資訊", message: "UID：\(uid)\nEmail：\(email!)", vc: self, actionHandler: nil)
//        UserFirebaseManager.shared.addUser(name: "", uid: uid, email: email ?? "", image: "")
        UserFirebaseManager.shared.checkUserEmail(userId: Auth.auth().currentUser?.uid ?? "") { result in
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
