//
//  PublishAdoptionViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/20.
//

import UIKit
import Firebase
import FirebaseStorage

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
    
    @IBAction func selectSexButton(_ sender: Any) {
        dataSource = ["Boy", "Girl"]
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
    
    @IBAction func openAlbum(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    @IBAction func openCameraButton(_ sender: Any) {
        // 檢查是否具有照相功能
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            // 設置相片來源為相機
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            // 開啟相機
            present(imagePicker, animated: true)
        }
    }
    
    @objc private func didTapClose() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // 取得相片
        if let image = info[.originalImage] as? UIImage {
            self.imageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController,
                               didFinishPickingImage image: UIImage,
                               editingInfo: [String: AnyObject]?) {
        print("didFinishPickingImage")
        //    self.imageView.image = image // 儲存拍攝（編輯）後的圖片到我們的imageView展示
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil) // 將圖片儲存到相簿
        picker.dismiss(animated: true, completion: nil) // 退出相機介面
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("imagePickerControllerDidCancel")
        picker.dismiss(animated: true, completion: nil) // 退出相機介面
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
        
        guard let selectedSex = selectedSex,
              let selectedAge = selectedAge,
              let commentId = comment["commentId"],
//              let postId = postId,
              let selectedPetable = selectedPetable else { return }
        
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
                            let age = selectedAge
                            let sex = selectedSex
                            let petable = selectedPetable
                            let postId = postId
//                            let commentId = commentId
                            let content = self.inputContentTextField.text ?? ""
                            let location = self.locationTextField.text ?? ""
                            self.adoptionManager.addAdoption(age: age.rawValue, content: content,
                                                             imageFileUrl: "\(url)", location: location,
                                                             sex: sex.rawValue, petable: petable.rawValue,
                                                             commentId: commentId as? String ?? "", postId: postId as? String ?? "")
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
        petableButton.backgroundColor = UIColor(named: "CulturedWhite")
        petableButton.layer.cornerRadius = 5
//        petableButton.tintColor = .white
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
