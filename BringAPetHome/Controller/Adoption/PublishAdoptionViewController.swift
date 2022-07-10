//
//  PublishAdoptionViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/20.
//

import UIKit
import Firebase
import FirebaseStorage
import Lottie
import CoreML
import Vision

class CellClass: UITableViewCell {
}

class PublishAdoptionViewController: UIViewController, UIImagePickerControllerDelegate,
                                     UINavigationControllerDelegate {
    
    //    var dataBase = Firestore.firestore()
    var docRef: DocumentReference? = nil // 建立資料庫參考
    let adoptionFirebaseModel = AdoptionModel()
    let transparentView = UIView()
    let tableView = UITableView()
    var selectedButton = UIButton()
    var dataSource = [String]()
    var adoptionManager = AdoptionManager()
    
    enum Adoption: String {
        case age = "age"
        case comment = "comment"
        case content = "content"
        case userId = "userId"
        case createdTime = "createdTime"
        case sendId = "sendId"
        case imageFileUrl = "imageFileUrl"
        case location = "location"
        case petable = "petable"
        case sex = "sex"
        case postId = "postId"
    }
    
    var comment: [String: Any] = [
        "commentContent": "",
        "commentId": "",
        "time": 0,
        "userId": ""
    ]
    
    var selectedSex: Sex?
    var selectedAge: Age?
    var selectedPetable: Petable?
    var commentId: String?
    var postId: String?
    
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var petableButton: UIButton!
    @IBOutlet weak var ageButton: UIButton!
    @IBOutlet weak var sexButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var inputContentTextField: UITextView!
    @IBOutlet weak var camaraButton: UIButton!
    @IBOutlet weak var postBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CellClass.self, forCellReuseIdentifier: "Cell")
        setupButton()
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
    
    override func viewDidLayoutSubviews() {
        camaraButton.layer.cornerRadius = 20
    }
    
    @IBAction func selectSexButton(_ sender: Any) {
        dataSource = ["男", "女"]
        selectedButton = sexButton
        selectedButton.tag = 0
        addTransparentView(frames: sexButton.frame)
    }
    
    @IBAction func selectAge(_ sender: Any) {
        dataSource = ["三個月內", "三個月到六個月", "六個月到一歲", "一歲以上"]
        selectedButton = ageButton
        selectedButton.tag = 1
        addTransparentView(frames: ageButton.frame)
    }
    
    @IBAction func selectPetable(_ sender: Any) {
        dataSource = ["送養", "已領養"]
        selectedButton = petableButton
        selectedButton.tag = 2
        addTransparentView(frames: petableButton.frame)
    }
    
    @IBAction func inputLocationText(_ sender: Any) {
    }
    
    @IBAction func openCameraButton(_ sender: Any) {
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
    func selectPhoto(sourceType: UIImagePickerController.SourceType) {
        let controller = UIImagePickerController()
        controller.sourceType = sourceType
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // 取得相片
        if let userPickedImage = info[.originalImage] as? UIImage {
            imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            detect(image: ciimage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    // swiftlint:disable all
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Loading CoreML Model failed")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }

            let animals = ["cat", "Border collie", "bird"]

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
                    self.postBarButton.isEnabled = false
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
    
    // MARK: - DropDown Menu
    func addTransparentView(frames: CGRect) {
        let window = UIApplication.shared.keyWindow
        transparentView.frame = window?.frame ?? self.view.frame
        self.view.addSubview(transparentView)
        
        tableView.frame = CGRect(x: frames.origin.x, y: frames.origin.y + frames.height, width: frames.width, height: 0)
        self.view.addSubview(tableView)
        tableView.layer.cornerRadius = 5
        
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        tableView.reloadData()
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(removeTransparentView))
        transparentView.addGestureRecognizer(tapgesture)
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0.5
            self.tableView.frame = CGRect(x: frames.origin.x, y: frames.origin.y + frames.height + 5,
                                          width: frames.width, height: CGFloat(self.dataSource.count * 50))
        }, completion: nil)
    }
    
    @objc func removeTransparentView() {
        let frames = selectedButton.frame
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0
            self.tableView.frame = CGRect(x: frames.origin.x, y: frames.origin.y + frames.height,
                                          width: frames.width, height: 0)
        }, completion: nil)
    }
    
    // MARK: - add data to Firebase
    @IBAction func publishButton(_ sender: Any) {
        print("publishButton")
        postBarButton.isEnabled = false
        setupLottie()
        guard let selectedSex = selectedSex,
              let selectedAge = selectedAge,
              let commentId = comment["commentId"]
            else { return }
        guard let imageData = self.imageView.image?.jpegData(compressionQuality: 0.5) else { return }
        

        
        let fileReference = Storage.storage().reference().child(UUID().uuidString + ".jpg")
        
        fileReference.putData(imageData, metadata: nil) { result in
            switch result {
                
            case .success(_):
                fileReference.downloadURL { [self] result in
                    switch result {
                    case .success(let url):
                        if inputContentTextField.text == "" || locationTextField.text == "" || imageView.image == nil {
                            let alert = UIAlertController(title: "錯誤", message: "請輸入內容", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "確認", style: .default))
                            self.present(alert, animated: true)
                        } else {
                            let userUid = Auth.auth().currentUser?.uid ?? ""
                            let age = selectedAge
                            let sex = selectedSex
                            let petable = selectedPetable
                            let postId = postId
//                            let commentId = commentId
                            let content = self.inputContentTextField.text ?? ""
                            let location = self.locationTextField.text ?? ""
                            self.adoptionManager.addAdoption(age: age.rawValue, content: content,
                                                             imageFileUrl: "\(url)",
                                                             location: location,
                                                             sex: sex.rawValue,
                                                             commentId: commentId as? String ?? "",
                                                             postId: postId ?? "",
                                                             userId: userUid)
                            postBarButton.isEnabled = false
                            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            guard let adoptionViewController = mainStoryboard.instantiateViewController(withIdentifier: "AdoptionViewController") as? AdoptionViewController else { return }
                            self.navigationController?.pushViewController(adoptionViewController, animated: true)
//                            dismiss(animated: true, completion: nil)
                        }
                    case .failure(_):
                        let age = Age(rawValue: 0)
                        let sex = Sex(rawValue: 0)
                        let petable = Petable(rawValue: 0)
                        break
                    }
                }
            case .failure(_):
                print("失敗！")
                break
            }
        }
    }
    
    func setupButton() {
        inputContentTextField.layer.borderWidth = 0.5
        inputContentTextField.layer.borderColor = UIColor.systemGray5.cgColor
        inputContentTextField.layer.cornerRadius = 5
        sexButton.backgroundColor = UIColor(named: "CulturedWhite")
//        sexButton.layer.borderColor = UIColor.systemGray5.cgColor
//        sexButton.layer.borderWidth = 0.5
        sexButton.layer.cornerRadius = 5
//        sexButton.tintColor = .white
//        ageButton.layer.borderColor = UIColor.systemGray5.cgColor
//        ageButton.layer.borderWidth = 0.5
        ageButton.backgroundColor = UIColor(named: "CulturedWhite")
        ageButton.layer.cornerRadius = 5
//        ageButton.tintColor = .white
//        petableButton.layer.borderColor = UIColor.systemGray5.cgColor
//        petableButton.layer.borderWidth = 0.5
//        petableButton.backgroundColor = UIColor(named: "CulturedWhite")
//        petableButton.layer.cornerRadius = 5
//        petableButton.tintColor = .white
    }
    
    func setupLottie() {
        let animationView = AnimationView(name: "lf20_x0zdphwq")
        animationView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        animationView.center = self.view.center
        animationView.contentMode = .scaleAspectFill
        
        view.addSubview(animationView)
        animationView.play()
    }
    
    func correctAnimation() {
        let animationView = AnimationView(name: "lf20_nq4j1vj5")
        animationView.frame = CGRect(x: 0, y: 0, width: 400, height: 400)
        animationView.center = self.view.center
        animationView.contentMode = .scaleAspectFill
        
        view.addSubview(animationView)
        animationView.play(completion: { (finished) in
            animationView.isHidden = true
        })
    }
}

extension PublishAdoptionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedButton.tag == 0 {
            self.selectedSex = Sex(rawValue: indexPath.row)
        } else if selectedButton.tag == 1 {
            self.selectedAge = Age(rawValue: indexPath.row)
        } else {
            self.selectedPetable = Petable(rawValue: indexPath.row)
        }
        selectedButton.setTitle(dataSource[indexPath.row], for: .normal)
        removeTransparentView()
    }
}
