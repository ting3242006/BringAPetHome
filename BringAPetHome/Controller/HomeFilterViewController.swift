//
//  HomeFilterViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/17.
//

import UIKit
import DropDown

protocol SearchVCDelegate: AnyObject {
    func doSomething(city: String, sex: String, color: String, body: String, kind: String)
}

struct SelectItem {
    var title: String
    var select: String
}

var dataList: [SelectItem] =
    [SelectItem(title: "城市", select: "") ,
     SelectItem(title: "性別", select: ""),
     SelectItem(title: "地點", select: ""),
     SelectItem(title: "體型", select: ""),
     SelectItem(title: "種類", select: "")]

//let cityDict: [String: String] = ["2": "臺北市", "3": "新北市", "4": "基隆市",
//                                   "5": "宜蘭縣", "6": "桃園縣", "7": "新竹縣",
//                                   "8": "新竹市", "9": "苗栗縣", "10": "臺中市",
//                                   "11": "彰化縣", "12": "南投縣", "13": "雲林縣",
//                                   "14": "嘉義縣", "15": "嘉義市", "16": "臺南市",
//                                   "17": "高雄市", "18": "屏東縣", "19": "花蓮縣",
//                                   "20": "臺東縣", "21": "澎湖縣", "22": "金門縣",
//                                   "23": "連江縣"]
//let pickercity: [String: Int] = ["臺北市": 2, "新北市": 3, "基隆市": 4,
//                                  "宜蘭縣": 5, "桃園縣": 6, "新竹縣": 7,
//                                  "新竹市": 8, "苗栗縣": 9, "臺中市": 10,
//                                  "彰化縣": 11, "南投縣": 12, "雲林縣": 13,
//                                  "嘉義縣": 14, "嘉義市": 15, "臺南市": 16,
//                                  "高雄市": 17, "屏東縣": 18, "花蓮縣": 19,
//                                  "臺東縣": 20, "澎湖縣": 21, "金門縣": 22,
//                                  "連江縣": 23]
let ageDict: [String: String] = ["幼年": "CHILD", "成年": "ADULT"]
let bodyTypeDict: [String: String] = ["小型": "SMALL",
                                      "中型": "MEDIUM", "大型": "BIG"]
let sexDict: [String: String] = ["公": "M", "母": "F"]
let kindDict: [String: String] = ["貓 ": "貓", "狗": "狗"]
let shelter: [String: String] = ["48": "基隆市寵物銀行",
                                 "49": "臺北市動物之家",
                                 "50": "新北市板橋區公立動物之家",
                                 "51": "新北市新店區公立動物之家",
                                 "53": "新北市中和區公立動物之家",
                                 "55": "新北市淡水區公立動物之家",
                                 "56": "新北市瑞芳區公立動物之家",
                                 "58": "新北市五股區公立動物之家",
                                 "59": "新北市八里區公立動物之家",
                                 "60": "新北市三芝區公立動物之家",
                                 "61": "桃園市動物保護教育園區",
                                 "62": "新竹市動物收容所",
                                 "63": "新竹縣動物收容所",
                                 "67": "臺中市動物之家南屯園區",
                                 "68": "臺中市動物之家后里園區",
                                 "69": "彰化縣流浪狗中途之家",
                                 "70": "南投縣公立動物收容所",
                                 "71": "嘉義市流浪犬收容中心",
                                 "72": "嘉義縣流浪犬中途之家",
                                 "73": "臺南市動物之家灣裡站",
                                 "74": "臺南市動物之家善化站",
                                 "75": "高雄市壽山動物保護教育園區",
                                 "76": "高雄市燕巢動物保護關愛園區",
                                 "77": "屏東縣流浪動物收容所",
                                 "78": "宜蘭縣流浪動物中途之家",
                                 "79": "花蓮縣流浪犬中途之家",
                                 "80": "臺東縣動物收容中心",
                                 "81": "連江縣流浪犬收容中心",
                                 "82": "金門縣動物收容中心",
                                 "83": "澎湖縣流浪動物收容中心",
                                 "89": "雲林縣流浪動物收容所",
                                 "92": "新北市政府動物保護防疫處",
                                 "96": "苗栗縣生態保育教育中心"]
let sex: [String: String] = ["M": "公", "F": "母", "N": "未知"]
let bodytype: [String: String] = ["SMALL": "小型", "MEDIUM": "中型", "BIG": "大型"]
let sterilization: [String: String] = ["T": "已絕育", "F": "未絕育", "N": "未輸入"]

class CellClass: UITableViewCell {
}

class HomeFilterViewController: UIViewController {
    
//    let cityDropDown = DropDown()
//    let colorDropDown = DropDown()
//
//    lazy var dropDowns: [DropDown] = {
//        return [
//            self.colorDropDown,
//            self.cityDropDown
//        ]
//    }()
    
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
        tableView.register(CellClass.self, forCellReuseIdentifier: "Cell")
        view.backgroundColor = .white
        self.navigationItem.title = "搜尋條件"
        self.tabBarController?.tabBar.isHidden = true
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
                                          y: frames.origin.y + frames.height + 5, width: frames.width, height: CGFloat(self.dataSource.count * 50))
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
    
    @IBAction func selectLocation(_ sender: Any) {
        dataSource = ["臺北市", "新北市", "基隆市",
                      "宜蘭縣", "桃園縣", "新竹縣",
                      "新竹市", "苗栗縣", "臺中市",
                      "彰化縣", "南投縣", "雲林縣",
                      "嘉義縣", "嘉義市", "臺南市",
                      "高雄市", "屏東縣", "花蓮縣",
                      "臺東縣", "澎湖縣", "金門縣",
                      "連江縣"]
        selectedButton = locationButton
        addTransparentView(frames: locationButton.frame)
    }
    
    @IBAction func selectColor(_ sender: Any) {
        dataSource = ["Male", "Female"]
        selectedButton = colorButton
        addTransparentView(frames: colorButton.frame)
    }
    
    @IBAction func sendFilterButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
