//
//  MapViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/17.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    var myLocationManager :CLLocationManager!
    var cllocation = CLLocationCoordinate2D()
    var titlename = ""
    let annotation = MKPointAnnotation()
    
    @IBOutlet weak var myMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "收容所位置"
    }
}

//MARK: - 取網路api資料
//func getData(url:String, completion: @escaping([AnimalData]) -> Void) {
//    AF.request(url).responseJSON { response in
//        if let data = response.data {
//            do {
//                let dataList = try JSONDecoder().decode( [AnimalData].self, from: data)
//                completion(dataList)
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//    }
//}

//MARK: - CLGeocoder地理編碼 地址轉換經緯度位置
func geocode(address: String, completion: @escaping (CLLocationCoordinate2D, Error?) -> ())  {
    CLGeocoder().geocodeAddressString(address) { placemarks, error in
        if let error = error {
            print(error.localizedDescription)
            return
        }
        if let placemarks = placemarks {
            // 取得第一個地點標記
            let placemark = placemarks[0]
            //加上標記
            let annotation = MKPointAnnotation()
            if let location = placemark.location {
                annotation.coordinate = location.coordinate
                print("~~~\(annotation.coordinate)")
                
            }
            completion(annotation.coordinate, nil)
        }
    }
}

// MARK: - 使用者位置
extension MapViewController: CLLocationManagerDelegate, MKMapViewDelegate{
    
    func setMap() {
        // 建立一個 CLLocationManager
        myLocationManager = CLLocationManager()
        
        // 設置委任對象
        myLocationManager.delegate = self
        
        // 距離篩選器 用來設置移動多遠距離才觸發委任方法更新位置
        myLocationManager.distanceFilter =
        kCLLocationAccuracyNearestTenMeters
        
        // 取得自身定位位置的精確度
        myLocationManager.desiredAccuracy =
        kCLLocationAccuracyBest
        
        // 設置委任對象
        myMapView.delegate = self
        
        // 地圖樣式
        myMapView.mapType = .standard
        
        // 顯示自身定位位置
        myMapView.showsUserLocation = true
        
        // 允許縮放地圖
        myMapView.isZoomEnabled = true
        
        // 地圖預設顯示的範圍大小 (數字越小越精確)
        let latDelta = 0.05
        let longDelta = 0.05
        let currentLocationSpan:MKCoordinateSpan =
        MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        
        // 設置地圖顯示的範圍與中心點座標
        let center:CLLocation = CLLocation(
            latitude: cllocation.latitude, longitude: cllocation.longitude)
        let currentRegion:MKCoordinateRegion =
        MKCoordinateRegion(
            center: center.coordinate,
            span: currentLocationSpan)
        myMapView.setRegion(currentRegion, animated: true)
        
        // 請求使用者授權使用定位服務
        myLocationManager.requestWhenInUseAuthorization()
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            myMapView.showsUserLocation = true
        }
    }
    
    func myPosition() {
        // 首次使用 向使用者詢問定位自身位置權限
        if CLLocationManager.authorizationStatus()
            == .notDetermined {
            // 取得定位服務授權
            myLocationManager.requestWhenInUseAuthorization()
            
            // 開始定位自身位置
            myLocationManager.startUpdatingLocation()
        }
        // 使用者已經拒絕定位自身位置權限
        else if CLLocationManager.authorizationStatus()
                    == .denied {
            // 提示可至[設定]中開啟權限
            let alertController = UIAlertController(
                title: "定位權限已關閉",
                message:
                    "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟",
                preferredStyle: .alert)
            let okAction = UIAlertAction(
                title: "確認", style: .default, handler:nil)
            alertController.addAction(okAction)
            self.present(
                alertController,
                animated: true, completion: nil)
        }
        // 使用者已經同意定位自身位置權限
        else if CLLocationManager.authorizationStatus()
                    == .authorizedWhenInUse {
            // 開始定位自身位置
            myLocationManager.startUpdatingLocation()
        }
    }
    
    //取得位置並顯示
    func MKpoint() {
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.title = "\(titlename)"
        objectAnnotation.coordinate = CLLocation(latitude: cllocation.latitude,longitude: cllocation.longitude).coordinate
        self.myMapView.showAnnotations([objectAnnotation], animated: true)
        self.myMapView.selectAnnotation(objectAnnotation, animated: true)
        
        myMapView.addAnnotation(objectAnnotation)
    }
    
    func mapView(_ mapView: MKMapView,
                 didSelect view: MKAnnotationView) {
        print("點擊大頭針")
    }
    
    //繪製路徑
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 3.0
        
        return renderer
    }
    
    //自定義大頭針樣式
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "MyPin"
        
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        // Reuse the annotation if possible
        var annotationView: MKAnnotationView?
        
        if #available(iOS 11.0, *) {
            var markerAnnotationView: MKMarkerAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if markerAnnotationView == nil {
                markerAnnotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                markerAnnotationView?.canShowCallout = true
            }
            
            markerAnnotationView?.glyphText = "🐶"
            markerAnnotationView?.markerTintColor = UIColor.orange
            
            annotationView = markerAnnotationView
            
        } else {
            
            var pinAnnotationView: MKPinAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            
            if pinAnnotationView == nil {
                pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                pinAnnotationView?.canShowCallout = true
                pinAnnotationView?.pinTintColor = UIColor.orange
            }
            
            annotationView = pinAnnotationView
        }
        
        let leftIconView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: 53, height: 53))
        leftIconView.image = UIImage(named: "browser")
        annotationView?.leftCalloutAccessoryView = leftIconView
        return annotationView
    }
}
