//
//  PostSharingViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/25.
//

import UIKit
import Firebase
import FirebaseStorage
import simd

class PostSharingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var shareManager = ShareManager()
    //    var dataBase = Firestore.firestore() // 初始化 Firestore
    //    var docRef: DocumentReference? = nil // 建立資料庫參考
    //    var shareList = [ShareModel]() // 取得 Struct 內容
    
    @IBOutlet weak var addSharIngImageButton: UIButton!
    @IBOutlet weak var shareTextView: UITextView!
    @IBOutlet weak var shareImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLayout()
        addSharIngImageButton.layer.cornerRadius = 15
        self.tabBarController?.tabBar.isHidden = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left")?
                .withTintColor(UIColor.darkGray)
                .withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(didTapClose))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false // 下一頁出現 TabBar
    }
        
    @IBAction func sentSharingPost(_ sender: Any) {
        guard let imageData = self.shareImageView.image?.jpegData(compressionQuality: 0.5) else { return }
        let fileReference = Storage.storage().reference().child(UUID().uuidString + ".jpg")
        
        fileReference.putData(imageData, metadata: nil) { result in
            switch result {
            case .success:
                fileReference.downloadURL { [self] result in
                    switch result {
                    case .success(let url):
                        let userUid = Auth.auth().currentUser?.uid ?? ""
                        shareManager.addSharing(uid: userUid, shareContent: shareTextView.text, image: "\(url)")
                    case .failure:
                        break
                    }
                    navigationController?.popToRootViewController(animated: true)
                }
            case .failure:
                break
            }
        }
    }
    
    @IBAction func addImageButton(_ sender: Any) {
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
    
    @objc private func didTapClose() {
        self.navigationController?.popViewController(animated: true)
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
            self.shareImageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
    
    func setLayout() {
        shareTextView.layer.borderColor = UIColor.systemGray3.cgColor
        shareTextView.layer.borderWidth = 0.5
    }
}
