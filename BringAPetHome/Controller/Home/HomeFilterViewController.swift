//
//  HomeFilterViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/17.
//

import UIKit

struct Filter {
    var kind: String?
    var sex: String?
    var bodytype: String?
}

protocol HomeFilterViewControllerDelegate: AnyObject {
    func selectFilterViewController(_ controller: HomeFilterViewController, didSelect filter: Filter)
}

var orginalanimalResults = [AnimalData]()
var animalResults = [AnimalData]()

class HomeFilterViewController: UIViewController {
    
    var filter = Filter()
    var delegate: HomeFilterViewControllerDelegate?
    
    @IBOutlet weak var dogButton: UIButton!
    @IBOutlet weak var catButton: UIButton!
    
    @IBOutlet weak var boyButton: UIButton!
    @IBOutlet weak var girlButton: UIButton!
    
    @IBOutlet weak var smallButton: UIButton!
    @IBOutlet weak var mediumButton: UIButton!
    @IBOutlet weak var bigButton: UIButton!
    
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var colorButton: UIButton!
    
    let transparentView = UIView()
    let tableView = UITableView()
    var selectedButton = UIButton()
    var dataSource = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        view.backgroundColor = .white
        self.navigationItem.title = "搜尋條件"
//        self.tabBarController?.tabBar.isHidden = true
        layoutButton()
    }
    
    @IBAction func selectDog(_ sender: Any) {
        filter.kind = "狗"
        self.dogButton.backgroundColor = UIColor(named: "HoneyYellow")
        self.dogButton.tintColor = .white
//        self.dogButton.imageView?.contentMode = .scaleAspectFit
        self.catButton.backgroundColor = .clear
        self.catButton.tintColor = .darkGray
    }
    
    @IBAction func selectCat(_ sender: Any) {
        filter.kind = "貓"
        self.catButton.backgroundColor = UIColor(named: "HoneyYellow")
        self.catButton.tintColor = .white
        self.dogButton.backgroundColor = .clear
        self.dogButton.tintColor = .darkGray
    }
    
    @IBAction func selectBoy(_ sender: Any) {
        filter.sex = "M"
        self.boyButton.backgroundColor = UIColor(named: "HoneyYellow")
        self.boyButton.tintColor = .white
        self.girlButton.backgroundColor = .clear
        self.girlButton.tintColor = .darkGray
    }
    
    @IBAction func selectGirl(_ sender: Any) {
        filter.sex = "F"
        self.girlButton.backgroundColor = UIColor(named: "HoneyYellow")
        self.girlButton.tintColor = .white
        self.boyButton.backgroundColor = .clear
        self.boyButton.tintColor = .darkGray
    }
    
    @IBAction func selectSmall(_ sender: Any) {
        filter.bodytype = "SMALL"
        self.smallButton.backgroundColor = UIColor(named: "HoneyYellow")
        self.smallButton.tintColor = .white
        self.mediumButton.backgroundColor = .clear
        self.mediumButton.tintColor = .darkGray
        self.bigButton.backgroundColor = .clear
        self.bigButton.tintColor = .darkGray
    }
    
    @IBAction func selectMedium(_ sender: Any) {
        filter.bodytype = "MEDIUM"
        self.mediumButton.backgroundColor = UIColor(named: "HoneyYellow")
        self.mediumButton.tintColor = .white
        self.smallButton.backgroundColor = .clear
        self.smallButton.tintColor = .darkGray
        self.bigButton.backgroundColor = .clear
        self.bigButton.tintColor = .darkGray
    }
    
    @IBAction func selectBig(_ sender: Any) {
        filter.bodytype = "BIG"
        self.bigButton.backgroundColor = UIColor(named: "HoneyYellow")
        self.bigButton.tintColor = .white
        self.mediumButton.backgroundColor = .clear
        self.mediumButton.tintColor = .darkGray
        self.smallButton.backgroundColor = .clear
        self.smallButton.tintColor = .darkGray
    }
    
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
        UIView.animate(withDuration: 0.4,
                       delay: 0.0, usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
            self.transparentView.alpha = 0.5
            self.tableView.frame = CGRect(x: frames.origin.x,
                                          y: frames.origin.y + frames.height + 5, width: frames.width,
                                          height: CGFloat(self.dataSource.count * 50))
        }, completion: nil)
    }
    
    @objc func removeTransparentView() {
        let frames = selectedButton.frame
        UIView.animate(withDuration: 0.4,
                       delay: 0.0, usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0
            self.tableView.frame = CGRect(x: frames.origin.x,
                                          y: frames.origin.y + frames.height,
                                          width: frames.width, height: 0)
        }, completion: nil)
    }
    
    @IBAction func sendFilterButton(_ sender: UIButton) {
        delegate?.selectFilterViewController(self, didSelect: filter)
        self.navigationController?.popViewController(animated: true)
    }
    
    func layoutButton() {
        dogButton.layer.cornerRadius = 15
        dogButton.layer.borderColor = UIColor.lightGray.cgColor
        dogButton.layer.borderWidth = 0.3
        catButton.layer.cornerRadius = 15
        catButton.layer.borderColor = UIColor.lightGray.cgColor
        catButton.layer.borderWidth = 0.3
        boyButton.layer.cornerRadius = 15
        boyButton.layer.borderColor = UIColor.lightGray.cgColor
        boyButton.layer.borderWidth = 0.3
        girlButton.layer.cornerRadius = 15
        girlButton.layer.borderColor = UIColor.lightGray.cgColor
        girlButton.layer.borderWidth = 0.3
        girlButton.layer.cornerRadius = 15
        girlButton.layer.borderColor = UIColor.lightGray.cgColor
        girlButton.layer.borderWidth = 0.3
        smallButton.layer.cornerRadius = 15
        smallButton.layer.borderColor = UIColor.lightGray.cgColor
        smallButton.layer.borderWidth = 0.3
        mediumButton.layer.cornerRadius = 15
        mediumButton.layer.borderColor = UIColor.lightGray.cgColor
        mediumButton.layer.borderWidth = 0.3
        bigButton.layer.cornerRadius = 15
        bigButton.layer.borderColor = UIColor.lightGray.cgColor
        bigButton.layer.borderWidth = 0.3
    }
}

extension HomeFilterViewController: UITableViewDelegate, UITableViewDataSource {
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
        selectedButton.setTitle(dataSource[indexPath.row], for: .normal)
        removeTransparentView()
    }
}
