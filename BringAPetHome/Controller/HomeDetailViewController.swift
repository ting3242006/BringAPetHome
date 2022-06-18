//
//  HomeDetailViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import UIKit
import Kingfisher
import CoreLocation

class HomeDetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var pet: AnimalData?
    //    var animalDatas = [AnimalData]()
    var skip: Int = 100
    var cllocation = CLLocationCoordinate2D()
    let selectedBackgroundView = UIView()
    
    func someMethodIWantToCall(cell: UITableViewCell) {
        let indexPathTapped = tableView.indexPath(for: cell)
        print(indexPathTapped)
//        let photo = pet[indexPathTapped!.item]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedBackgroundView.backgroundColor = UIColor.clear
        self.tabBarController?.tabBar.isHidden = true
        tableView.backgroundColor = .orange
        tableView.dataSource = self
        tableView.delegate = self
        tableView.anchor(top: view.topAnchor,
                         leading: view.leadingAnchor,
                         bottom: view.bottomAnchor,
                         trailing: view.trailingAnchor,
                         padding: .init(top: 0, left: 0, bottom: 0, right: 0))
    }
    
    @IBAction func clickMapButton(_ sender: Any) {
        guard let mapVC = storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
        mapVC.cllocation = self.cllocation
//        mapVC.titlename = (pet?.shelterName != nil)
            self.navigationController?.pushViewController(mapVC, animated: true)
    }
    
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
    
    @IBAction func shareInfoButton(_ sender: Any) {
//        guard let image = self.albumFileImageView.image else { return }
//        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
//        present(activity , animated: true)
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
        
        cell.selectedBackgroundView = selectedBackgroundView
        let urls = pet?.albumFile
        cell.albumFileImageView.kf.setImage(with: URL(string: urls!), placeholder: UIImage(named: "cat_ref"))
        cell.albumFileImageView.contentMode = .scaleAspectFill
        cell.placeLabel.text = "收容所： \(String(describing: pet!.place))"
//        cell.placeLabel.backgroundColor = .blue
        cell.sexLabel.text = "性別： \(String(describing: pet!.sex))"
        cell.statusLabel.text = pet?.status
        cell.placeLabel.text = pet?.place
        cell.ageLabel.text = pet?.age
        cell.animalIdLabel.text = "\(pet?.animalId ?? 0)"
        cell.animalSterilizationLabel.text = pet?.animalSterilization
        cell.animalVarietyLabel.text = pet?.animalVariety
        cell.areaPkidLabel.text = "\(pet?.areaPkid ?? 0)"
        cell.bodytypeLabel.text = pet?.bodytype
        cell.cDateLabel.text = pet?.cDate
        cell.colourLabel.text = pet?.colour
        cell.ageLabel.text = pet?.age
        cell.kindLabel.text = pet?.kind
        cell.remarkLabel.text = pet?.remark ?? "No data"
        cell.opendateLabel.text = pet?.opendate
        cell.shelterNameLabel.text = pet?.shelterName
        cell.shelterTel.text = pet?.shelterTel
        cell.shelterAddressLabel.text = pet?.shelterAddress
        cell.animalSterilizationLabel.text = pet?.animalSterilization
        cell.titleLabel.text = pet?.title
        
        return cell
    }
}
