//
//  PostSharingViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/25.
//

import UIKit
import Firebase
import FirebaseStorage
import CoreML
import Vision
import Lottie

class PostSharingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var shareManager = ShareManager.shared
    
    @IBOutlet weak var addSharIngImageButton: UIButton!
    @IBOutlet weak var shareTextView: UITextView!
    @IBOutlet weak var shareImageView: UIImageView!
    @IBOutlet weak var postBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLayout()
        addSharIngImageButton.layer.cornerRadius = 15
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false // 下一頁出現 TabBar
    }
    
    override func viewDidLayoutSubviews() {
        addSharIngImageButton.layer.cornerRadius = 20
        addSharIngImageButton.clipsToBounds = true
    }
    
    @IBAction func sentSharingPost(_ sender: Any) {
        if shareImageView.image == nil || shareTextView.text == "" {
            let alert = UIAlertController(title: "錯誤", message: "請輸入內容",   preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確認", style: .default))
            self.present(alert, animated: true)
        } else {
            guard let imageData = self.shareImageView.image?.jpegData(compressionQuality: 0.3) else { return }
            let fileReference = Storage.storage().reference().child(UUID().uuidString + ".jpg")
            
            self.postBarButton.isEnabled = false
            self.setupLottie()
            
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
    }
    
    @IBAction func addImageButton(_ sender: Any) {
        postBarButton.isEnabled = true
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
    private func selectPhoto(sourceType: UIImagePickerController.SourceType) {
        let controller = UIImagePickerController()
        controller.sourceType = sourceType
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                                       didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // 取得相片
        if let userPickedImage = info[.originalImage] as? UIImage {
            shareImageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            detect(image: ciimage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    // swiftlint:disable all
    private func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Loading CoreML Model failed")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }
            if let firstResult = results.first {
                print("firstResult", firstResult.identifier)
                
                if firstResult.identifier.contains("cat") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("Border collie") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("golden retriever") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("dog") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("Rhodesian ridgeback") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("basenji") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("hamster") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("Staffordshire bullterrier") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("kelpie") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("Hungarian pointer") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("beagle") {
                    self.correctAnimation()
                } else if firstResult.identifier.contains("American Staffordshire terrier") {
                    self.correctAnimation()
                } else {
                    CustomFunc.customAlert(title: "照片中沒動物", message: "", vc: self, actionHandler: nil)
                }
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
    
    // swiftlint:ensable all
    private func setLayout() {
        shareTextView.layer.borderColor = UIColor.systemGray3.cgColor
        shareTextView.layer.borderWidth = 0.5
        addSharIngImageButton.layer.cornerRadius = 20
        addSharIngImageButton.clipsToBounds = true
        self.tabBarController?.tabBar.isHidden = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left")?
                .withTintColor(UIColor.darkGray)
                .withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(didTapClose))
    }
    
    private func setupLottie() {
        let animationView = AnimationView(name: "lf30_editor_5phd8cww")
        animationView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        animationView.center = self.view.center
        animationView.contentMode = .scaleAspectFill
        
        view.addSubview(animationView)
        animationView.play()
    }
    
    private func correctAnimation() {
        let animationView = AnimationView(name: "lf30_editor_yqqlpukj")
        animationView.frame = CGRect(x: 0, y: 0, width: 400, height: 400)
        animationView.center = self.view.center
        animationView.contentMode = .scaleAspectFill
        
        view.addSubview(animationView)
        animationView.play(completion: { (finished) in
            animationView.isHidden = true
        })
    }
}
