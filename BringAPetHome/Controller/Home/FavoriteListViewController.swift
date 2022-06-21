//
//  FavoriteListViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/18.
//

import UIKit

class FavoriteListViewController: UIViewController {

    @IBOutlet weak var favoriteTableView: UITableView!
    
    static var identifier: String {
        return String(describing: self)
    }
    
    // 宣告 Core Data 常數
    let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    var animalList: [Animal] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        favoriteTableView.delegate = self
        favoriteTableView.dataSource = self
        guard let context = context else { return }
        
        do {
            animalList = try context.fetch(Animal.fetchRequest())
        } catch {
            print("error")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let context = context else { return }

        do {
            animalList = try context.fetch(Animal.fetchRequest())
        } catch {
            print("error")
        }
        favoriteTableView.reloadData()
    }
}

extension FavoriteListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.animalList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteListTableViewCell", for: indexPath) as? FavoriteListTableViewCell else { return UITableViewCell() }
        
        let animal = self.animalList[indexPath.row]
        cell.sex.text = "\(animal.id)"
//        cell.sex.text = "性別:\(animal.sex ?? "")"
        cell.opendate.text = "開放領養:\(animal.openDate ?? "")"
        cell.sterilization.text = "是否節育:\(animal.steriization ?? "")"
        cell.place.text = "所在地:\(animal.place ?? "")"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageUrl = documentsDirectory.appendingPathComponent("\(animal.id)").appendingPathExtension("jpg")
        cell.animalImageView.image = UIImage(contentsOfFile: imageUrl.path)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        favoriteTableView.deselectRow(at: indexPath, animated: true)
        let animal = self.animalList[indexPath.row]
//        let homeDetailViewController = UIStoryboard.instantiateViewController(
//            withIdentifier: HomeDetailViewController.identifier)
//        guard let detailVC = homeDetailViewController as? HomeDetailViewController else { return }
//        detailVC.pet = animal
//        show(detailVC, sender: nil)
    }
}
