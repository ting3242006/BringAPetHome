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
    
    static var identifier: String {
        return String(describing: self)
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var pet: AnimalData?
    //    var animalDatas = [AnimalData]()
    var skip: Int = 100
    var cllocation = CLLocationCoordinate2D()
    let selectedBackgroundView = UIView()
    let getFile = MapViewController()
    var latitude = 0.0
    var longitude = 0.0
    func someMethodIWantToCall(cell: UITableViewCell) {
        let indexPathTapped = tableView.indexPath(for: cell)
//        let photo = pet[indexPathTapped!.item]
    }
    var saveAnimal: Animal?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedBackgroundView.backgroundColor = UIColor.clear
        self.tabBarController?.tabBar.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.anchor(top: view.topAnchor,
                         leading: view.leadingAnchor,
                         bottom: view.bottomAnchor,
                         trailing: view.trailingAnchor,
                         padding: .init(top: 0, left: 0, bottom: 0, right: 0))
//        getFile.geocode(address:pet.shelterAddress) { (data, error) in
//            self.cllocation = data
//            print(self.cllocation)
//        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let context = appDelegate?.persistentContainer.viewContext else { return }
        let predicate = NSPredicate(format: "id == %d AND openDate == %@ AND sex == %@ AND steriization == %@ AND place == %@",
                                    pet?.animalId ?? 0, pet?.opendate ?? "",
                                    pet?.sex ?? "", pet?.animalSterilization ?? "",
                                    pet?.place ?? "")
        let request: NSFetchRequest<Animal> = Animal.fetchRequest()
        request.predicate = predicate
        do {
            saveAnimal = try context.fetch(request).first
        } catch {
            print("error")
        }
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left")?
                .withTintColor(UIColor.darkGray)
                .withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(didTapClose))
//        tableView.automaticallyAdjustsScrollIndicatorInsets =
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
        
        tableView.contentInsetAdjustmentBehavior = .never
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false // 下一頁出現 TabBar
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func clickMapButton(_ sender: Any) {
        guard let mapVC = storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
        mapVC.address = pet?.shelterAddress 
//        mapVC.cllocation = self.cllocation
//        mapVC.titlename = (pet?.shelterName != nil)
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
        let activity = UIActivityViewController(activityItems: [pet?.albumFile, pet?.sex, pet?.kind, pet?.shelterAddress], applicationActivities: nil)
        present(activity, animated: true)
    }
    
    @objc private func didTapClose() {
        self.navigationController?.popViewController(animated: true)
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
        cell.areaPkidLabel.text = ShelterManager.shared.areaName(pkid: pet?.areaPkid ?? 0)
        cell.sexLabel.text = ShelterManager.shared.sexCh(sex: pet?.sex ?? "")
        cell.statusLabel.text = ShelterManager.shared.status(status: pet?.status ?? "")
        cell.ageLabel.text = ShelterManager.shared.ageCh(age: pet?.age ?? "")
        cell.animalIdLabel.text = " \(pet?.animalId ?? 0)"
        cell.animalVarietyLabel.text = "\(pet?.animalVariety ?? "")"
        cell.bodytypeLabel.text = ShelterManager.shared.bodytypeCh(bodytype: pet?.bodytype ?? "")
        cell.cDateLabel.text = "\(String(describing: pet?.cDate ?? ""))"
        cell.colourLabel.text = " \(String(describing: pet?.colour ?? ""))"
        cell.ageLabel.text = ShelterManager.shared.ageCh(age: pet?.age ?? "")
        cell.kindLabel.text = "\(String(describing: pet?.kind ?? ""))"
        cell.remarkLabel.text = " \(String(describing: pet?.remark ?? ""))"
        cell.opendateLabel.text = " \(String(describing: pet?.opendate ?? ""))"
        cell.shelterNameLabel.text = "\(String(describing: pet?.shelterName ?? ""))"
        cell.shelterTel.text = "\(String(describing: pet?.shelterTel ?? ""))"
        cell.shelterAddressLabel.text = "\(String(describing: pet?.shelterAddress ?? ""))"
        cell.animalSterilizationLabel.text = ShelterManager.shared.sterilization(sterilization: pet?.animalSterilization ?? "")
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
