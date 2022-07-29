//
//  MapViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/17.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    let petAnnotation = MKPointAnnotation()
    var address: String?
    var cllocation = CLLocationCoordinate2D()
    
    @IBOutlet weak var myMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "收容所位置"
        setMap()
        getShelterLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    private func getShelterLocation() {
        guard let address = address else {
            return
        }
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let placemarks = placemarks {
                // 取得第一個地點標記
                let placemark = placemarks[0]
                // 加上標記
                if let location = placemark.location {
                    self.petAnnotation.coordinate = location.coordinate
                    print("location.coordinate", location.coordinate)
                    self.myMapView.addAnnotation(self.petAnnotation)
                    self.myMapView.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                }
            }
        }
    }
}

// MARK: - 使用者位置
extension MapViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    func setMap() {
        // 設置委任對象
        myMapView.delegate = self
        
        // 地圖樣式
        myMapView.mapType = .standard
        
        // 允許縮放地圖
        myMapView.isZoomEnabled = true
        
        // 地圖是否可滾動
        myMapView.isScrollEnabled = true
        
        // 地圖預設顯示的範圍大小 (數字越小越精確)
        let latDelta = 0.05
        let longDelta = 0.05
        let currentLocationSpan: MKCoordinateSpan =
        MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        
        // 設置地圖顯示的範圍與中心點座標
        let center: CLLocation = CLLocation(
            latitude: cllocation.latitude, longitude: cllocation.longitude)
        let currentRegion: MKCoordinateRegion =
        MKCoordinateRegion(
            center: center.coordinate,
            span: currentLocationSpan)
        myMapView.setRegion(currentRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView,
                 didSelect view: MKAnnotationView) {
        print("點擊大頭針")
    }
    
    // 自定義大頭針樣式
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
            
            markerAnnotationView?.glyphText = "🐾"
            markerAnnotationView?.markerTintColor = UIColor(named: "HoneyYellow")
            
            annotationView = markerAnnotationView
            
        } else {
            var pinAnnotationView: MKPinAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            
            if pinAnnotationView == nil {
                pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                pinAnnotationView?.canShowCallout = true
                pinAnnotationView?.pinTintColor = UIColor(named: "HoneyYellow")
            }
            annotationView = pinAnnotationView
        }
        
        let leftIconView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: 53, height: 53))
        leftIconView.image = UIImage(named: "browser")
        annotationView?.leftCalloutAccessoryView = leftIconView
        
        return annotationView
    }
}
