//
//  EditProfileViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/29.
//

import UIKit
import Firebase
import FirebaseStorage

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    @IBOutlet weak var sendInfoButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var uploadImageButton: UIButton!
    @IBOutlet weak var deleteAccountButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
    }
    
    @IBAction func deleteAccount(_ sender: Any) {
        let alert  = UIAlertController(title: "Delete Account", message: "Are you sure?", preferredStyle: .alert)
               let yesAction = UIAlertAction(title: "YES", style: .destructive) { (_) in
                   self.deleteAccount()
               }
               let noAction = UIAlertAction(title: "Cancel", style: .cancel)

               alert.addAction(noAction)
               alert.addAction(yesAction)

               present(alert, animated: true, completion: nil)
    }
    
    func deleteAccount() {
        UserFirebaseManager.shared.deleteAccount()
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let homeVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
        self.navigationController?.pushViewController(homeVC, animated: true)
    }
    
    @IBAction func uploadInfo(_ sender: Any) {
        guard let imageData = self.userImageView.image?.jpegData(compressionQuality: 0.5) else { return }
        let currentUser = Auth.auth().currentUser
        guard let user = currentUser else {
            return
        }
        let fileReference = Storage.storage().reference().child(UUID().uuidString + ".jpg")
        
        fileReference.putData(imageData, metadata: nil) { result in
            switch result {
            case .success:
                fileReference.downloadURL { [self] result in
                    switch result {
                    case .success(let url):
                        
                        //        let name = user.displayName
                        
                        UserFirebaseManager.shared.updateUserInfo(id: user.uid, image: "\(url)",
                                                                  name: usernameTextField.text ?? "") { result in
                            switch result {
                            case .success:
                                print("~~~~~Success")
                            case .failure:
                                print("Error")
                            }
                        }
                        navigationController?.popToRootViewController(animated: true)
                    case .failure:
                        break
                    }
                }
            case .failure:
                break
            }
        }
        //        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        //        guard let profileVC = mainStoryboard.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController else { return }
        //        self.navigationController?.pushViewController(profileVC, animated: true)
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
        uploadImageButton.layer.cornerRadius = 10
        uploadImageButton.clipsToBounds = true
        sendInfoButton.layer.cornerRadius = 10
        deleteAccountButton.layer.cornerRadius = 10
        uploadImageButton.layer.cornerRadius = 20
    }
}
