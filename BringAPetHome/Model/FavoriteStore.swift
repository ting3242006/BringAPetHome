//
//  FavoriteStore.swift
//  BringAPetHome
//

import CoreData
import UIKit

/// 收藏列表一筆資料：`animalData` 為既有的轉回 AnimalData 結果，
/// 其餘三個欄位是列表 cell 直接顯示、且與 `animalData` 欄位不同源的值。
struct FavoriteRecord {
    let animalData: AnimalData
    let openDate: String?
    let steriization: String?
    let place: String?
}

final class FavoriteStore {

    static let shared = FavoriteStore()

    private init() { }

    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }

    private var context: NSManagedObjectContext? {
        appDelegate?.persistentContainer.viewContext
    }

    private static func firstAnimal(id: Int, in context: NSManagedObjectContext) throws -> Animal? {
        let request: NSFetchRequest<Animal> = Animal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", NSNumber(value: Int64(id)))
        return try context.fetch(request).first
    }

    func isFavorite(id: Int) -> Bool {
        guard let context = context else { return false }
        do {
            let animal = try Self.firstAnimal(id: id, in: context)
            print("saveAnimal", id, animal as Any)
            return animal != nil
        } catch {
            print("error", error)
            return false
        }
    }

    func add(_ pet: AnimalData) {
        guard let context = context else { return }
        let animal = Animal(context: context)
        animal.id = Int64(pet.animalId)
        animal.sex = pet.sex
        animal.steriization = pet.animalSterilization
        animal.openDate = pet.opendate
        animal.place = pet.place
        animal.bodytype = pet.bodytype
        animal.animalVariety = pet.animalVariety
        animal.shelterTel = pet.shelterTel
        animal.areaPkid = Int64(pet.areaPkid)
        animal.kind = pet.kind
        animal.colour = pet.colour
        animal.albumFile = pet.albumFile
        animal.remark = pet.remark
        animal.cDate = pet.cDate
        animal.shelterAddress = pet.shelterAddress
        animal.shelterName = pet.shelterName
        animal.age = pet.age
        animal.opendate = pet.opendate
        animal.like = false
        appDelegate?.saveContext()

        do {
            let animals = try context.fetch(Animal.fetchRequest())
            animals.forEach { animal in
                print("DEBUG: \(animal.id) \(animal.like)")
            }
        } catch {

        }
    }

    func remove(id: Int) -> Bool {
        guard let context = context else { return false }
        return Self.remove(id: id, in: context)
    }

    static func remove(id: Int, in context: NSManagedObjectContext) -> Bool {
        // 從乾淨的 context 開始，失敗時才能只復原這次刪除。
        guard !context.hasChanges else { return false }
        do {
            // 與舊行為一致：只刪除查詢到的第一筆。
            guard let animal = try firstAnimal(id: id, in: context) else { return true }
            context.delete(animal)
            try context.save()
            return true
        } catch {
            context.rollback()
            print("移除收藏失敗", error)
            return false
        }
    }

    /// 回傳 nil 代表取不到 context；fetch 失敗則 throw，由呼叫端決定如何處理。
    func allFavorites() throws -> [FavoriteRecord]? {
        guard let context = context else { return nil }
        let animals: [Animal] = try context.fetch(Animal.fetchRequest())
        return animals.map { animal in
            let animalData = AnimalData(animalId: Int(animal.id),
                                        place: animal.place ?? "", kind: animal.kind ?? "",
                                        sex: animal.sex ?? "",
                                        bodytype: animal.bodytype ?? "",
                                        colour: animal.colour ?? "",
                                        age: animal.age ?? "",
                                        status: animal.status ?? "",
                                        remark: animal.remark ?? "",
                                        opendate: animal.opendate ?? "",
                                        shelterName: animal.shelterName ?? "",
                                        albumFile: animal.albumFile ?? "",
                                        shelterAddress: animal.shelterAddress ?? "",
                                        shelterTel: animal.shelterTel ?? "",
                                        animalVariety: animal.animalVariety ?? "",
                                        areaPkid: Int(animal.areaPkid),
                                        animalSterilization: animal.animalSterilization ?? "",
                                        title: animal.title ?? "",
                                        cDate: animal.cDate ?? "",
                                        albumUpdate: "")
            return FavoriteRecord(animalData: animalData,
                                  openDate: animal.openDate,
                                  steriization: animal.steriization,
                                  place: animal.place)
        }
    }
}
