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

class ViewController: UIViewController ,MKMapViewDelegate{

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
    
    var locationManager         : CLLocationManager!
    var speedCameras            = SpeedCameraWatcher.getSpeedCamerasArr()
    var userCoordinate2D        = CLLocationCoordinate2D()
    var watcherStatus           = WatcherStatus.normal
    var currentSpeedPerHour     = 0.0
    var distanceNearSpeedCamera = 0.0
    var GpsSleepTimes = 0
    var warning_speedCameras = SpeedCameraWatcher.speedCamera()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLocationManager()
        btnUserCenterResume.isHidden = true
        mapNavi.delegate = self
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
   
        self.setSpeedCamerasAnnotation()
    }
    
    func setSpeedCamerasAnnotation(){
        for SpeedCameraLocation in speedCameras{
            let annotation = ColorPointAnnotation(pinColor: UIColor.green)
            annotation.coordinate = SpeedCameraLocation.location
            annotation.title = SpeedCameraLocation.name
            
            switch SpeedCameraLocation.kind {
            case .FreeWay:
                annotation.pinColor = .yellow
            case .ExpressWay:
                annotation.pinColor = .green
            case .CityWay:
                annotation.pinColor = .red
            }
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
    
    func  playNotice(title:String, soundFile:String ){
    
        let notification = UILocalNotification()
        notification.alertTitle = title
        notification.alertBody = title
        notification.soundName = "\(soundFile).wav"
        UIApplication.shared.scheduleLocalNotification(notification)
        
        if let soundURL = Bundle.main.url(forResource: "\(soundFile)", withExtension: "wav") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            AudioServicesPlaySystemSound(mySound);
        }
    }
    
    func chieckinCameraWatchArea(distance:Double,currentSpeedCamera: SpeedCameraWatcher.speedCamera) {
        if (distanceNearSpeedCamera < distance && watcherStatus == WatcherStatus.normal){
                        watcherStatus = WatcherStatus.inwarning
            switch distance {
            case 200:
                playNotice(title: "[\(distanceNearSpeedCamera)] \(currentSpeedCamera.name)", soundFile: "200")
            case 300:
                playNotice(title: "[\(distanceNearSpeedCamera)] \(currentSpeedCamera.name)", soundFile: "300")
            case 500:
                playNotice(title: "[\(distanceNearSpeedCamera)] \(currentSpeedCamera.name)", soundFile: "500")
            default:
                print("NO")
            }
        }
        else if (distanceNearSpeedCamera > 500 && watcherStatus == WatcherStatus.inwarning){
                watcherStatus = WatcherStatus.normal
        }
    }
    
    func updateVCUI(currentCLLcation :CLLocation,currentSpeedCamera: SpeedCameraWatcher.speedCamera){
        currentSpeedCamera.kind
        labName_NearSpeedCamera.text        = "名字: \(currentSpeedCamera.name) \( currentSpeedCamera.kind)"
        labLocation_NearSpeedCamera.text    = "位罝: \(currentSpeedCamera.location)"
        labDistance_NearSpeedCamera.text    = "距離: \(distanceNearSpeedCamera)"
        labSpeedPerHour.text                = "時速: \(currentSpeedPerHour   )KM/h"
    }
    
    func checkNearCameraWatch (currentCLLcation: CLLocation, currentSpeedCamera: SpeedCameraWatcher.speedCamera){
        
        if currentSpeedCamera.kind == .FreeWay{
            chieckinCameraWatchArea(distance: 500.0, currentSpeedCamera: currentSpeedCamera)
        }else if (currentSpeedCamera.kind == .ExpressWay){
            chieckinCameraWatchArea(distance: 300.0, currentSpeedCamera: currentSpeedCamera)
        }else{
            chieckinCameraWatchArea(distance: 200.0, currentSpeedCamera: currentSpeedCamera)
        }
    }
    
    @IBAction func didResume(){
        btnUserCenterResume.isHidden = true
        setMapCenter(center: self.userCoordinate2D)
    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if !(annotation is MKPointAnnotation) {
//            return nil
//        }
//       let newAnnotation = annotation as! ColorPointAnnotation
//        
//        let reuseId = "test"
//        
//        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
//        if anView == nil {
//            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
//            if (newAnnotation.pinColor == UIColor.yellow ){
//                anView?.image = UIImage(named:"FreeWayCamera.png")}
//            else if (newAnnotation.pinColor == UIColor.green){
//                anView?.image = UIImage(named:"ExpressWayCamera.png")
//            }else if (newAnnotation.pinColor == UIColor.red){
//                anView?.image = UIImage(named:"CityWayCamera.png")
//            }
//        }
//        else {
//            anView?.annotation = annotation
//        }
//        
//        return anView
//    }
    
    func setSystemsleeping_Wakeup(speed :Double){
        
        if (self.locationManager.desiredAccuracy == kCLLocationAccuracyBestForNavigation){
        
            if (speed < 20){
                GpsSleepTimes += 1
            }
            if GpsSleepTimes >= 100 {
                GpsSleepTimes = 0
                self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
                playNotice(title: "駕駛結束進入省電模式", soundFile: "駕駛結束進入省電模式")
            }
            print("GpsSleepTimes\(GpsSleepTimes)")
        }else{
            if (speed > 10){
                GpsSleepTimes = 0
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                playNotice(title: "啟動測速偵測模式", soundFile: "啟動測速偵測模式")
            }
        }
    }
}

extension ViewController: CLLocationManagerDelegate{
    
    func locationManager(_ manager:CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
        let currentCLLcation    = locations.last!
        let nearestSpeedCamer      = self.getCloseCamera(currentCLLcation: currentCLLcation, speedCameras: self.speedCameras)
        
        distanceNearSpeedCamera  = SpeedCameraWatcher.getLocationDistance(from: currentCLLcation.coordinate, to: nearestSpeedCamer.location)
    
        currentSpeedPerHour = currentCLLcation.speed * 3.6
        self.checkNearCameraWatch(currentCLLcation: currentCLLcation, currentSpeedCamera: nearestSpeedCamer)
        
        updateVCUI(currentCLLcation: currentCLLcation, currentSpeedCamera: nearestSpeedCamer)
        self.setMapCenter(center: (locations.last?.coordinate)!)
        print("distance:\(distanceNearSpeedCamera),location \(nearestSpeedCamer.location)")
        //setSystemsleeping_Wakeup(speed: currentSpeedPerHour)
    }
    
    func getCloseCamera(currentCLLcation :CLLocation,speedCameras: [SpeedCameraWatcher.speedCamera]) -> (SpeedCameraWatcher.speedCamera){
        var Mix = 99999
        var retrunSpeedCamera = SpeedCameraWatcher.speedCamera()
        
        for SpeedCameraLocation in speedCameras{
            let distance = SpeedCameraWatcher.getLocationDistance(from: SpeedCameraLocation.location, to: currentCLLcation.coordinate)
            if (Int(distance) < Mix){
                Mix = Int(distance)
                retrunSpeedCamera = SpeedCameraLocation
            }
        }
        return retrunSpeedCamera
    }
}


