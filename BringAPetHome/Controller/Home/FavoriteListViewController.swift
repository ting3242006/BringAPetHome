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
    var animalDatas = [AnimalData]() {
        didSet {
            reloadData()
        }
    }

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
    
    private func reloadData() {
        guard Thread.isMainThread == true else {
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
            return
        }
        favoriteTableView.reloadData()
    }
}

extension FavoriteListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        animalList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteListTableViewCell", for: indexPath) as? FavoriteListTableViewCell else { return UITableViewCell() }
        
        let animal = animalList[indexPath.row]
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
//        let animal = self.animalList[indexPath.row]
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeDetailViewController") as? HomeDetailViewController else { return }
//        guard let detailVC = mainStoryboard.instantiateViewController(withIdentifier: HomeDetailViewController.identifier) as? HomeDetailViewController else { return }
        let pet = self.animalDatas[indexPath.row]
        detailVC.pet = pet
//        detailVC.pet = animal
        self.navigationController?.pushViewController(detailVC, animated: true)
//        show(detailVC, sender: nil)
    }
}
