//
//  HomeDetailViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import UIKit
import Kingfisher

class HomeDetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var pet: AnimalData?
    //    var animalDatas = [AnimalData]()
    var skip: Int = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            self.navigationController?.pushViewController(mapVC, animated: true)
    }
    
    @IBAction func clickPhoneButton(_ sender: Any) {
        
    }
    
    @IBAction func shareInfoButton(_ sender: Any) {
        
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
        let urls = pet?.albumFile
        cell.albumFileImageView.kf.setImage(with: URL(string: urls!), placeholder: UIImage(named: "cat_ref"))
        cell.placeLabel.text = pet?.place
        cell.sexLabel.text = pet?.sex
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
