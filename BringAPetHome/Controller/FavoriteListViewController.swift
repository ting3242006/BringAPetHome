//
//  FavoriteListViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/18.
//

import UIKit

class FavoriteListViewController: UIViewController {

    @IBOutlet weak var favoriteTableView: UITableView!
    
    // 宣告 Core Data 常數
//    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var userList:[User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        favoriteTableView.delegate = self
        favoriteTableView.dataSource = self
    }
}

extension FavoriteListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteListTableViewCell", for: indexPath) as UITableViewCell
//        cell.sex.text = self.userList[indexPath.row].like
        return cell
    }
}
