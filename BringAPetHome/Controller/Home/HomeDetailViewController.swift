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
        //self.tabBarController?.tabBar.isHidden = true
        tableView.backgroundColor = .orange
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
        
    }
    
    @IBAction func clickMapButton(_ sender: Any) {
        guard let mapVC = storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
        mapVC.cllocation = self.cllocation
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
}

extension HomeDetailViewController: UITableViewDataSource, UITableViewDelegate  {
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
        cell.albumFileImageView.kf.setImage(with: URL(string: urls!), placeholder: UIImage(named: "cat_ref"))
        cell.albumFileImageView.contentMode = .scaleAspectFill
        cell.placeLabel.text = "動物實際所在地： \(String(describing: pet?.place ?? ""))"
        cell.sexLabel.text = "性別： \(String(describing: pet?.sex ?? ""))"
        cell.statusLabel.text = "動物狀態: \(String(describing: pet?.status ?? ""))"
        cell.ageLabel.text = "年紀: \(String(describing: pet?.age ?? ""))"
        cell.animalIdLabel.text = "流水編號: \(pet?.animalId ?? 0)"
        cell.animalVarietyLabel.text = "品種: \(pet?.animalVariety ?? "")"
        cell.areaPkidLabel.text = "所屬縣市代碼: \(pet?.areaPkid ?? 0)"
        cell.bodytypeLabel.text = "體型: \(String(describing: pet?.bodytype ?? ""))"
        cell.cDateLabel.text = "資料更新時間: \(String(describing: pet?.cDate ?? ""))"
        cell.colourLabel.text = "毛色: \(String(describing: pet?.colour ?? ""))"
        cell.ageLabel.text = "年紀: \(String(describing: pet?.age ?? ""))"
        cell.kindLabel.text = "動物類型: \(String(describing: pet?.kind ?? ""))"
        cell.remarkLabel.text = "資料備註: \(String(describing: pet?.remark ?? ""))"
        cell.opendateLabel.text = "開放認養時間: \(String(describing: pet?.opendate ?? ""))"
        cell.shelterNameLabel.text = "動物所屬收容所名稱: \(String(describing: pet?.shelterName ?? ""))"
        cell.shelterTel.text = "連絡電話: \(String(describing: pet?.shelterTel ?? ""))"
        cell.shelterAddressLabel.text = "地址: \(String(describing: pet?.shelterAddress ?? ""))"
        cell.animalSterilizationLabel.text = "是否絕育: \(pet?.animalSterilization ?? "")"
        
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
            saveAnimal?.id = Int64(id)
            saveAnimal?.sex = sex
            saveAnimal?.steriization = sterilization
            saveAnimal?.openDate = openDate
            saveAnimal?.place = place
            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? HomeDetailTableViewCell
            let imageData = cell?.albumFileImageView.image?.jpegData(compressionQuality: 0.9)
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let imageUrl = documentsDirectory.appendingPathComponent("\(id)").appendingPathExtension("jpg")
            try? imageData?.write(to: imageUrl)
            appDelegate?.saveContext()
        }
    }
}
