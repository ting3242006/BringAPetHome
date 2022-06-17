//
//  MapViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/17.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var myMapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "收容所位置"
    }
}
