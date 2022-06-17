//
//  HomeFilterViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/17.
//

import UIKit

let cityDict: [String: String] = ["2": "臺北市", "3": "新北市", "4": "基隆市",
                                   "5": "宜蘭縣", "6": "桃園縣", "7": "新竹縣",
                                   "8": "新竹市", "9": "苗栗縣", "10": "臺中市",
                                   "11": "彰化縣", "12": "南投縣", "13": "雲林縣",
                                   "14": "嘉義縣", "15": "嘉義市", "16": "臺南市",
                                   "17": "高雄市", "18": "屏東縣", "19": "花蓮縣",
                                   "20": "臺東縣", "21": "澎湖縣", "22": "金門縣",
                                   "23": "連江縣"]
let pickercity: [String: Int] = ["臺北市": 2, "新北市": 3, "基隆市": 4,
                                  "宜蘭縣": 5, "桃園縣": 6, "新竹縣": 7,
                                  "新竹市": 8, "苗栗縣": 9, "臺中市": 10,
                                  "彰化縣": 11, "南投縣": 12, "雲林縣": 13,
                                  "嘉義縣": 14, "嘉義市": 15, "臺南市": 16,
                                  "高雄市": 17, "屏東縣": 18, "花蓮縣": 19,
                                  "臺東縣": 20, "澎湖縣": 21, "金門縣": 22,
                                  "連江縣": 23]
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

class HomeFilterViewController: UIViewController {
    
    @IBOutlet weak var dogButton: UIButton!
    @IBOutlet weak var catButton: UIButton!
    
    @IBOutlet weak var boyButton: UIButton!
    @IBOutlet weak var girlButton: UIButton!
    
    @IBOutlet weak var smallButton: UIButton!
    @IBOutlet weak var mediumButton: UIButton!
    @IBOutlet weak var bigButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
        
    }
}
