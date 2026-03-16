//
//  HomeFilterViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/17.
//

import UIKit

struct Filter: Equatable {
    var kind: String?
    var sex: String?
    var bodytype: String?
    var areaPkid: Int?
}

protocol HomeFilterViewControllerDelegate: AnyObject {
    func selectFilterViewController(_ controller: HomeFilterViewController, didSelect filter: Filter)
}

class HomeFilterViewController: UIViewController {
    
    var filter = Filter()
    weak var delegate: HomeFilterViewControllerDelegate?
    private var selectedAreaPkid: Int? = nil
    
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var dogButton: UIButton!
    @IBOutlet weak var catButton: UIButton!
    
    @IBOutlet weak var boyButton: UIButton!
    @IBOutlet weak var girlButton: UIButton!
    
    @IBOutlet weak var smallButton: UIButton!
    @IBOutlet weak var mediumButton: UIButton!
    @IBOutlet weak var bigButton: UIButton!
    
    private var locationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutButton()
        view.backgroundColor = .white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false // 下一頁出現 TabBar
    }
        
    @IBAction func selectDog(_ sender: Any) {
        filter.kind = "狗"
        self.dogButton.layer.borderColor = UIColor(named: "HoneyYellow")?.cgColor
        self.catButton.layer.borderColor = UIColor.lightGray.cgColor
        self.catButton.tintColor = .lightGray
    }
    
    @IBAction func selectCat(_ sender: Any) {
        filter.kind = "貓"
        self.catButton.layer.borderColor = UIColor(named: "HoneyYellow")?.cgColor
        self.dogButton.layer.borderColor = UIColor.lightGray.cgColor
        self.dogButton.tintColor = .lightGray
    }
    
    @IBAction func selectBoy(_ sender: Any) {
        filter.sex = "M"
        self.boyButton.layer.borderColor = UIColor(named: "HoneyYellow")?.cgColor
        self.boyButton.tintColor = UIColor(named: "DarkGreen")
        self.girlButton.layer.borderColor = UIColor.lightGray.cgColor
        self.girlButton.tintColor = .lightGray
    }
    
    @IBAction func selectGirl(_ sender: Any) {
        filter.sex = "F"
        self.girlButton.layer.borderColor = UIColor(named: "HoneyYellow")?.cgColor
        self.girlButton.tintColor = UIColor(named: "DarkGreen")
        self.boyButton.layer.borderColor = UIColor.lightGray.cgColor
        self.boyButton.tintColor = .lightGray
    }
    
    @IBAction func selectSmall(_ sender: Any) {
        filter.bodytype = "SMALL"
        self.smallButton.layer.borderColor = UIColor(named: "HoneyYellow")?.cgColor
        self.smallButton.tintColor = UIColor(named: "DarkGreen")
        self.mediumButton.layer.borderColor = UIColor.lightGray.cgColor
        self.mediumButton.tintColor = .lightGray
        self.bigButton.layer.borderColor = UIColor.lightGray.cgColor
        self.bigButton.tintColor = .lightGray
    }
    
    @IBAction func selectMedium(_ sender: Any) {
        filter.bodytype = "MEDIUM"
        self.mediumButton.layer.borderColor = UIColor(named: "HoneyYellow")?.cgColor
        self.mediumButton.tintColor = UIColor(named: "DarkGreen")
        self.smallButton.layer.borderColor = UIColor.lightGray.cgColor
        self.smallButton.tintColor = .lightGray
        self.bigButton.layer.borderColor = UIColor.lightGray.cgColor
        self.bigButton.tintColor = .lightGray
    }
    
    @IBAction func selectBig(_ sender: Any) {
        filter.bodytype = "BIG"
        self.bigButton.layer.borderColor = UIColor(named: "HoneyYellow")?.cgColor
        self.bigButton.tintColor = UIColor(named: "RichBlack")
        self.smallButton.layer.borderColor = UIColor.lightGray.cgColor
        self.smallButton.tintColor = .lightGray
        self.mediumButton.layer.borderColor = UIColor.lightGray.cgColor
        self.mediumButton.tintColor = .lightGray
    }
    
    @objc private func didTapClose() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func cleanFilter() {
        filter.kind = ""
        filter.bodytype = ""
        filter.sex = ""
        filter.areaPkid = nil
        selectedAreaPkid = nil
        locationButton.setTitle("地區", for: .normal)
        locationButton.layer.borderColor = UIColor.lightGray.cgColor
        locationButton.tintColor = UIColor(named: "DarkGreen")
        delegate?.selectFilterViewController(self, didSelect: filter)
        self.navigationController?.popViewController(animated: true)
    }

    @objc private func selectLocation() {
        let alert = UIAlertController(title: "選擇地區", message: nil, preferredStyle: .actionSheet)
        for pkid in 2...23 {
            let name = ShelterManager.shared.areaName(pkid: pkid)
            let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.selectedAreaPkid = pkid
                self.filter.areaPkid = pkid
                self.locationButton.setTitle(name, for: .normal)
                self.locationButton.layer.borderColor = UIColor(named: "HoneyYellow")?.cgColor
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    @IBAction func sendFilterButton(_ sender: UIButton) {
        delegate?.selectFilterViewController(self, didSelect: filter)
        self.navigationController?.popViewController(animated: true)
    }
    
    private func layoutButton() {
        let areaLabel = UILabel()
        areaLabel.text = "地區"
        areaLabel.font = UIFont.systemFont(ofSize: 17)
        areaLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(areaLabel)

        locationButton = UIButton(type: .system)
        locationButton.setTitle("選擇", for: .normal)
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationButton)

        let bodyTypeStack = smallButton.superview ?? view!
        NSLayoutConstraint.activate([
            areaLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            areaLabel.topAnchor.constraint(equalTo: bodyTypeStack.bottomAnchor, constant: 20),
            locationButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            locationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            locationButton.topAnchor.constraint(equalTo: areaLabel.bottomAnchor, constant: 20),
            locationButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        dogButton.layer.cornerRadius = 15
        dogButton.layer.borderColor = UIColor.lightGray.cgColor
        dogButton.layer.borderWidth = 1
        dogButton.tintColor = UIColor(named: "DarkGreen")
        catButton.layer.cornerRadius = 15
        catButton.layer.borderColor = UIColor.lightGray.cgColor
        catButton.layer.borderWidth = 1
        catButton.tintColor = UIColor(named: "DarkGreen")
        boyButton.layer.cornerRadius = 15
        boyButton.layer.borderColor = UIColor.lightGray.cgColor
        boyButton.layer.borderWidth = 1
        girlButton.layer.cornerRadius = 15
        girlButton.layer.borderColor = UIColor.lightGray.cgColor
        girlButton.layer.borderWidth = 1
        girlButton.layer.cornerRadius = 15
        girlButton.layer.borderColor = UIColor.lightGray.cgColor
        girlButton.layer.borderWidth = 1
        smallButton.layer.cornerRadius = 15
        smallButton.layer.borderColor = UIColor.lightGray.cgColor
        smallButton.layer.borderWidth = 1
        mediumButton.layer.cornerRadius = 15
        mediumButton.layer.borderColor = UIColor.lightGray.cgColor
        mediumButton.layer.borderWidth = 1
        bigButton.layer.cornerRadius = 15
        bigButton.layer.borderColor = UIColor.lightGray.cgColor
        bigButton.layer.borderWidth = 1
        locationButton.layer.cornerRadius = 15
        locationButton.layer.borderColor = UIColor.lightGray.cgColor
        locationButton.layer.borderWidth = 1
        locationButton.tintColor = UIColor(named: "DarkGreen")
        locationButton.addTarget(self, action: #selector(selectLocation), for: .touchUpInside)
        filterButton.layer.cornerRadius = 15
        filterButton.clipsToBounds = true
        self.navigationItem.title = "篩選"
        self.tabBarController?.tabBar.isHidden = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left")?
                .withTintColor(UIColor.darkGray)
                .withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(didTapClose))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "fluent_filter-dismiss")?
                .withTintColor(UIColor.darkGray)
                .withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(cleanFilter))
    }
}
