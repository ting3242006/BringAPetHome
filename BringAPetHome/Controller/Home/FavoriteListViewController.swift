//
//  FavoriteListViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/18.
//

import UIKit

class FavoriteListViewController: UIViewController {

    @IBOutlet weak var favoriteTableView: UITableView!
    
    var animalList: [FavoriteRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        favoriteTableView.delegate = self
        favoriteTableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            guard let favorites = try FavoriteStore.shared.allFavorites() else { return }
            animalList = favorites
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
        
        let record = animalList[indexPath.row]
        let animal = record.animalData
        cell.idLabel.text = "ID:\(animal.animalId)"
        cell.opendate.text = "\(record.openDate ?? "")"
        cell.sterilization.text = ShelterManager.shared.sterilization(sterilization: record.steriization ?? "")
        cell.place.text = record.place
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageUrl = documentsDirectory.appendingPathComponent("\(animal.animalId)").appendingPathExtension("jpg")
        cell.animalImageView.image = UIImage(contentsOfFile: imageUrl.path)
        cell.sexLabel.text = ShelterManager.shared.sexCh(sex: animal.sex)
        var name = ""
        switch cell.sexLabel.text {
        case "男":
            name = "BOY-1"
        case "女":
            name = "GIRL-1"
        default:
            name = "paws"
        }
        cell.sexImageView.image = UIImage(named: name)
        
        return cell
    }
    
    // swiftlint:disable all
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        favoriteTableView.deselectRow(at: indexPath, animated: true)
        let animalData = self.animalList[indexPath.row].animalData
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeDetailViewController") as? HomeDetailViewController else { return }
        detailVC.pet = animalData
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
    // swiftlint:ensable all
}
