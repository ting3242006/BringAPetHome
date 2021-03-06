//
//  HomeDetailViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import UIKit
import Kingfisher
import CoreLocation
import CoreData

class HomeDetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var pet: AnimalData?
    let selectedBackgroundView = UIView()
    var saveAnimal: Animal?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        selectedBackgroundView.backgroundColor = UIColor.clear
        tableView.dataSource = self
        tableView.delegate = self
        saveFavorites()
        layout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false // 下一頁出現 TabBar
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func clickMapButton(_ sender: Any) {
        guard let mapVC = storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
        mapVC.address = pet?.shelterAddress
        self.navigationController?.pushViewController(mapVC, animated: true)
    }
    
    // MARK: - 打電話
    @IBAction func clickPhoneButton(_ sender: Any) {
        guard let tel = pet?.shelterTel else {
            fatalError()
        }
        let controller = UIAlertController(title: "聯絡收容所", message: "\(tel)", preferredStyle: .actionSheet)
        let phoneAction = UIAlertAction(title: "打電話給\(tel)", style: .default) {(_) in
            if let url = URL(string: "tel:\(tel)") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    print("無法開啟url")
                }
            } else {
                print("連結錯誤")
            }
        }
        let canceAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(phoneAction)
        controller.addAction(canceAction)
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: - 分享資訊
    @IBAction func shareInfoButton(_ sender: Any) {
        let activity = UIActivityViewController(activityItems: [pet?.albumFile, pet?.kind, pet?.shelterAddress], applicationActivities: nil)
        present(activity, animated: true)
    }
    
    @objc private func didTapClose() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func layout() {
        tableView.anchor(top: view.topAnchor,
                         leading: view.leadingAnchor,
                         bottom: view.bottomAnchor,
                         trailing: view.trailingAnchor,
                         padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left")?
                .withTintColor(UIColor.darkGray)
                .withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(didTapClose))
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
        
        tableView.contentInsetAdjustmentBehavior = .never
    }
    
    private func saveFavorites() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let context = appDelegate?.persistentContainer.viewContext else { return }
        let predicate = NSPredicate(format: "id == %d",
                                    pet?.animalId ?? 0)
        let request: NSFetchRequest<Animal> = Animal.fetchRequest()
        request.predicate = predicate
        do {
            saveAnimal = try context.fetch(request).first
            print("saveAnimal", pet?.animalId, saveAnimal)
        } catch {
            print("error", error)
        }
    }
}

extension HomeDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeDetailTableViewCell.identifier, for: indexPath) as? HomeDetailTableViewCell else { return UITableViewCell() }
        cell.link = self
        cell.heartButton.isSelected = saveAnimal != nil
        cell.delegate = self
        cell.selectedBackgroundView = selectedBackgroundView
        let urls = pet?.albumFile
        cell.albumFileImageView.kf.setImage(with: URL(string: urls!), placeholder: UIImage(named: "dketch-4"))
        cell.albumFileImageView.contentMode = .scaleAspectFill
        cell.sexLabel.text = "性別：\( ShelterManager.shared.sexCh(sex: pet?.sex ?? ""))"
        cell.ageLabel.text = "年齡：\(ShelterManager.shared.ageCh(age: pet?.age ?? ""))"
        cell.animalIdLabel.text = "流水編號：\(pet?.animalId ?? 0)"
        cell.bodytypeLabel.text = "品種：\(ShelterManager.shared.bodytypeCh(bodytype: pet?.bodytype ?? ""))\(pet?.animalVariety ?? "")"
        cell.colourLabel.text = "毛色：\(String(describing: pet?.colour ?? ""))"
        cell.ageLabel.text = "年齡：\(ShelterManager.shared.ageCh(age: pet?.age ?? ""))"
        cell.remarkLabel.text = "備註： \(String(describing: pet?.remark ?? ""))"
        cell.opendateLabel.text = "開放認養時間：\(String(describing: pet?.opendate ?? ""))"
        cell.shelterNameLabel.text = "收容所名稱：\(String(describing: pet?.shelterName ?? ""))"
        cell.shelterTel.text = "電話：\(String(describing: pet?.shelterTel ?? ""))"
        cell.shelterAddressLabel.text = "收容所地址：\(String(describing: pet?.shelterAddress ?? ""))"
        cell.animalSterilizationLabel.text = "是否絕育：\( ShelterManager.shared.sterilization(sterilization: pet?.animalSterilization ?? ""))"
        cell.selectedBackgroundView = selectedBackgroundView
        return cell
    }
}

extension HomeDetailViewController: HomeDetailTableViewCellDelegate {
    
    func heartButtonTapped() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let context = appDelegate?.persistentContainer.viewContext else { return }
        
        if let saveAnimal = saveAnimal {
            context.delete(saveAnimal)
        } else {
            saveAnimal = Animal(context: context)
            let id = pet?.animalId ?? 0
            let sex = pet?.sex ?? ""
            let sterilization = pet?.animalSterilization ?? ""
            let openDate = pet?.opendate ?? ""
            let place = pet?.place ?? ""
            let kind = pet?.kind ?? ""
            let animalVariety = pet?.animalVariety ?? ""
            let bodytype = pet?.bodytype ?? ""
            let shelterTel = pet?.shelterTel
            let areaPkid = pet?.areaPkid ?? 0
            let colour = pet?.colour ?? ""
            let albumFile = pet?.albumFile ?? ""
            let remark = pet?.remark ?? ""
            let cDate = pet?.cDate ?? ""
            let shelterAddress = pet?.shelterAddress ?? ""
            let shelterName = pet?.shelterName
            let age = pet?.age
            let opendate = pet?.opendate
            let like = saveAnimal?.like ?? false
            
            saveAnimal?.id = Int64(id)
            saveAnimal?.sex = sex
            saveAnimal?.steriization = sterilization
            saveAnimal?.openDate = openDate
            saveAnimal?.place = place
            saveAnimal?.bodytype = bodytype
            saveAnimal?.animalVariety = animalVariety
            saveAnimal?.shelterTel = shelterTel
            saveAnimal?.areaPkid = Int64(areaPkid)
            saveAnimal?.kind = kind
            saveAnimal?.colour = colour
            saveAnimal?.albumFile = albumFile
            saveAnimal?.remark = remark
            saveAnimal?.cDate = cDate
            saveAnimal?.shelterAddress = shelterAddress
            saveAnimal?.shelterName = shelterName
            saveAnimal?.age = age
            saveAnimal?.opendate = opendate
            saveAnimal?.like = like
            
            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? HomeDetailTableViewCell
            let imageData = cell?.albumFileImageView.image?.jpegData(compressionQuality: 0.5)
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let imageUrl = documentsDirectory.appendingPathComponent("\(id)").appendingPathExtension("jpg")
            try? imageData?.write(to: imageUrl)
            appDelegate?.saveContext()
            
            do {
                let request = Animal.fetchRequest()
                let animals = try context.fetch(request)
                animals.forEach { animal in
                    print("DEBUG: \(animal.id) \(animal.like)")
                }
            } catch {
                
            }
        }
    }
}
