//
//  ViewController.swift
//  SpeedCameraWatcher
//
//  Created by james on 22/12/2016.
//  Copyright © 2016 james. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SpriteKit
import AVFoundation

class ViewController: UIViewController {

    enum WatcherStatus {
        case inwarning
        case normal
        case StopWatch
    }
    
    @IBOutlet var labName_NearSpeedCamera               : UILabel!
    @IBOutlet var labLocation_NearSpeedCamera           : UILabel!
    @IBOutlet var labDistance_NearSpeedCamera           : UILabel!
    @IBOutlet var labSpeedPerHour                       : UILabel!
    @IBOutlet var mapNavi                               : MKMapView!
    @IBOutlet var btnUserCenterResume                   : UIButton!
    
    var locationManager : CLLocationManager!
    var speedCameras    = other.getSpeedCamerasArr()
    var currentCenter   = CLLocationCoordinate2D()
    var watcherStatus   = WatcherStatus.normal
    var currentSpeedPer = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setLocationManager()
        btnUserCenterResume.isHidden = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: mapNavi)
            if mapNavi.bounds.contains(position)  {
                 btnUserCenterResume.isHidden = false
            }
        }
    }

    func setLocationManager() {
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.setSpeedCamerasAnnotation()
    }
    
    func setSpeedCamerasAnnotation(){
        for SpeedCameraLocation in speedCameras{
            let annotation = MKPointAnnotation()
            annotation.coordinate = SpeedCameraLocation.location
            annotation.title = SpeedCameraLocation.name
            self.mapNavi.addAnnotation(annotation)
        }
    }
    
    func setMapCenter(center: CLLocationCoordinate2D){
        if btnUserCenterResume.isHidden == true{
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            self.mapNavi.setRegion(region, animated: true)
            self.mapNavi.showsUserLocation = true
        }
    }
    
    func  playNotice(title:String){
    
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
        notification.alertBody = title
        notification.alertAction = title
        notification.soundName = "emergency.wav"
        notification.userInfo = ["CustomField1": "w00t"]
        UIApplication.shared.scheduleLocalNotification(notification)
        
        if let soundURL = Bundle.main.url(forResource: "emergency", withExtension: "wav") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            // Play
            AudioServicesPlaySystemSound(mySound);
        }
    }
    
    @IBAction func didResume(){
        btnUserCenterResume.isHidden = true
        setMapCenter(center: self.currentCenter)
    }
}

extension ViewController: CLLocationManagerDelegate{
    
    func locationManager(_ manager:CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        currentCenter = (locations.last?.coordinate)!
        var Mix = 99999
        var MixName = ""
        var MixLocation = ""
        print("locations.last?.speed\(locations.last?.speed)")
        currentSpeedPer = (locations.last?.speed)!
        for SpeedCameraLocation in speedCameras{
            
            let distance = other.getLocationDistance(from: SpeedCameraLocation.location, to: (locations.last?.coordinate)!)
            print(distance)
            if (Int(distance) < Mix){
               Mix = Int(distance)
               MixName = SpeedCameraLocation.name
               MixLocation = "\(SpeedCameraLocation.location.latitude),\(SpeedCameraLocation.location.longitude)"
            }
        }
        
        if (Mix < 200 && watcherStatus == WatcherStatus.normal){
            playNotice(title: "[\(Mix)] \(MixName)")
            watcherStatus = WatcherStatus.inwarning
        }else if (Mix > 200 && watcherStatus == WatcherStatus.inwarning){
            watcherStatus = WatcherStatus.normal
        }
        
        labName_NearSpeedCamera.text        = "名字: \(MixName)"
        labLocation_NearSpeedCamera.text    = "位罝: \(MixLocation)"
        labDistance_NearSpeedCamera.text    = "距離: \(Mix)"
        labSpeedPerHour.text                = "時速: \(currentSpeedPer *  3.6)KM/h"
        print("mix distance\(Mix), (\(MixName),(\(MixLocation))")
        self.setMapCenter(center: (locations.last?.coordinate)!)
    }
}


