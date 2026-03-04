//
//  EditProfileViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/29.
//

import UIKit
import Firebase
import FirebaseStorage
import Kingfisher

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var sendInfoButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var uploadImageButton: UIButton!
    @IBOutlet weak var deleteAccountButton: UIButton!
    @IBOutlet weak var privacyPolicyButton: UIButton!

    let dataBase = Firestore.firestore()
    private var originalViewY: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        usernameTextField.delegate = self
        loadUserData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        originalViewY = view.frame.origin.y
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let window = view.window else { return }
        let buttonFrameInWindow = sendInfoButton.convert(sendInfoButton.bounds, to: window)
        let overlap = buttonFrameInWindow.maxY - keyboardFrame.minY + 16
        if overlap > 0 {
            UIView.animate(withDuration: duration) {
                self.view.frame.origin.y = self.originalViewY - overlap
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: duration) {
            self.view.frame.origin.y = self.originalViewY
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func loadUserData() {
        guard let user = UserFirebaseManager.shared.userData else { return }
        usernameTextField.text = user.name
        if let url = URL(string: user.image) {
            userImageView.kf.setImage(with: url)
        }
    }
    
    @IBAction func deleteAccount(_ sender: Any) {
        let alert  = UIAlertController(title: "刪除帳號", message: "確定要刪除嗎? 如要刪除，請先登出再登入一次", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "確認", style: .destructive) { (_) in
            self.dataBase.collection("User").document(Auth.auth().currentUser?.uid ?? "").delete()
            self.deleteAccount()
            
            let vc = ProfileViewController()
            self.present(vc, animated: true)
        }
        let noAction = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(noAction)
        alert.addAction(yesAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func uploadInfo(_ sender: Any) {
        guard let imageData = self.userImageView.image?.jpegData(compressionQuality: 0.5) else { return }
        guard let user = Auth.auth().currentUser else { return }

        sendInfoButton.isEnabled = false

        let fileReference = Storage.storage().reference().child(UUID().uuidString + ".jpg")
        fileReference.putData(imageData, metadata: nil) { result in
            switch result {
            case .success:
                fileReference.downloadURL { [self] result in
                    switch result {
                    case .success(let url):
                        UserFirebaseManager.shared.updateUserInfo(id: user.uid, image: "\(url)",
                                                                  name: self.usernameTextField.text ?? "") { result in
                            switch result {
                            case .success:
                                self.navigationController?.popToRootViewController(animated: true)
                            case .failure:
                                self.sendInfoButton.isEnabled = true
                            }
                        }
                    case .failure:
                        self.sendInfoButton.isEnabled = true
                    }
                }
            case .failure:
                self.sendInfoButton.isEnabled = true
            }
        }
    }
    
    @IBAction func addPicButton(_ sender: Any) {
        let alertController = UIAlertController(title: "Choose photo from", message: nil, preferredStyle: .actionSheet)
        let sources: [(name: String, type: UIImagePickerController.SourceType)] = [
            ("Album", .photoLibrary),
            ("Camera", .camera)
        ]
        for source in sources {
            let action = UIAlertAction(title: source.name, style: .default) { _ in
                self.selectPhoto(sourceType: source.type)
            }
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    //  指定 data source / delegate 選取相簿照片或照相
    func selectPhoto(sourceType: UIImagePickerController.SourceType) {
        let controller = UIImagePickerController()
        controller.sourceType = sourceType
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // 取得相片
        if let image = info[.originalImage] as? UIImage {
            self.userImageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
    
    func layout() {
        userImageView.layer.cornerRadius = 10
        sendInfoButton.layer.cornerRadius = 10
        deleteAccountButton.layer.cornerRadius = 10
        uploadImageButton.layer.cornerRadius = 20
        uploadImageButton.clipsToBounds = true
    }
    
    func deleteAccount() {
        UserFirebaseManager.shared.deleteAccount()
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let homeVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
        self.navigationController?.pushViewController(homeVC, animated: true)
    }
}
