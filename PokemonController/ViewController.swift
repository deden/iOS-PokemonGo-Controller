//
//  ViewController.swift
//  PokemonController
//
//  Created by Ramadhan Noor on 7/16/16.
//  Copyright © 2016 Ramadhan Noor. All rights reserved.
//

import UIKit
import MapKit
import GCDWebServer
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, MKMapViewDelegate, PlayerDelegate {

    let FLASK_SERVER: String = "http://192.168.1.5:5000"
    
    enum LatestAction : String {
        case Walk = "walk", Run = "run", Jump = "jump"
    }
    
    var latestAction: LatestAction = .Walk

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var stopButton: UIButton!

    var mapCenterCoordinate:CLLocationCoordinate2D!
    var targetLocation:CLLocationCoordinate2D!
    var currentMapType = 0
    var players = [Player]()
    var gyms = [MKAnnotation]()
    var pokemons = [MKAnnotation]()
    var pokestops = [MKAnnotation]()
    var currentPlayer:Player?
    var webServer:GCDWebServer = GCDWebServer()
    
    var loadmapScheduler:NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getSavedLocation() ? showMapOnLocation() : ()
        getSavedMapType()
        startWebServer()
        
        mapView.delegate = self
        let ulpgr = UILongPressGestureRecognizer(target: self, action:#selector(ViewController.routeMapLongPressSelector(_:)))
        ulpgr.minimumPressDuration = 0.3
        mapView.addGestureRecognizer(ulpgr)
        
        mapView.addAnnotations(gyms)
        mapView.addAnnotations(pokemons)
        mapView.addAnnotations(pokestops)
        loadPokemapData()
        loadmapScheduler = NSTimer.scheduledTimerWithTimeInterval(15.0,
                                                               target: self,
                                                               selector: #selector(self.tick),
                                                               userInfo: nil,
                                                               repeats: true)
        mapCenterCoordinate = mapView.centerCoordinate
        
        createPlayer("You")
    }
    
    @objc func tick() {
        loadPokemapData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: MKMapViewDelegate
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapCenterCoordinate = mapView.centerCoordinate
        saveLocation()
    }
    
    func assignLeftAccView (returnedAnnotationView: MKAnnotationView!) {
        let destinationImage = UIImage(named: "cplus")! as UIImage
        let lbtn = UIButton(type: .Custom)
        lbtn.frame = CGRectMake(0, 0, 40, 40);
        lbtn.setBackgroundImage(destinationImage, forState: .Normal)
        returnedAnnotationView!.leftCalloutAccessoryView = lbtn
    }
    
    func assignRightAccMenuView (returnedAnnotationView: MKAnnotationView!) {
        let menuImage = UIImage(named: "menu")! as UIImage
        let btn = UIButton(type: .Custom)
        btn.frame = CGRectMake(0, 0, 40, 40);
        btn.setBackgroundImage(menuImage, forState: .Normal)
        returnedAnnotationView!.rightCalloutAccessoryView = btn
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var returnedAnnotationView: MKAnnotationView? = nil
        
        if (annotation is Player) {
            let player = annotation as! Player
            let identifier = "Player"
            var playerView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            if playerView == nil {
                playerView = MKAnnotationView(annotation: player, reuseIdentifier: identifier)
                playerView!.canShowCallout = true
            }
            playerView!.image = UIImage(named:player.imageName)
            return playerView
            
        } else if (annotation is Flag){
            returnedAnnotationView = Flag.createViewAnnotationForMapView(self.mapView, annotation: annotation)
            returnedAnnotationView!.image = UIImage(named: "flag")
            assignLeftAccView(returnedAnnotationView)
            assignRightAccMenuView(returnedAnnotationView)
        } else if (annotation is Gym) {
            let gym = annotation as! Gym
            returnedAnnotationView = Gym.createViewAnnotationForMapView(self.mapView, annotation: gym)
            let imageName:String = gym.teamId == 0 ? "Gym" : gym.teamId == 1 ? "Mystic" : gym.teamId == 2 ? "Valor" : "Instinct"
            returnedAnnotationView!.image = UIImage(named:imageName)
            assignLeftAccView(returnedAnnotationView)
            assignRightAccMenuView(returnedAnnotationView)
        } else if (annotation is Pokemon) {
            let pokemon = annotation as! Pokemon
            returnedAnnotationView = Pokemon.createViewAnnotationForMapView(self.mapView, annotation: pokemon)
            let imageName:String = String(pokemon.pokemonId)
            returnedAnnotationView!.image = UIImage(named:imageName)
            assignLeftAccView(returnedAnnotationView)
            assignRightAccMenuView(returnedAnnotationView)
        } else if (annotation is Pokestop) {
            let pokestop = annotation as! Pokestop
            returnedAnnotationView = Pokestop.createViewAnnotationForMapView(self.mapView, annotation: pokestop)
            if pokestop.lureDisappearTime != 0 {
                let epocTime = NSTimeInterval(pokestop.lureDisappearTime/1000)
                let nowTimestamp = NSDate().timeIntervalSince1970
                returnedAnnotationView!.image = epocTime > nowTimestamp ? UIImage(named:"PstopLured") : UIImage(named:"Pstop")
            } else {
                returnedAnnotationView!.image = UIImage(named:"Pstop")
            }
            assignLeftAccView(returnedAnnotationView)
            assignRightAccMenuView(returnedAnnotationView)
        }
        
        return returnedAnnotationView
    }

    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.mapView.deselectAnnotation(view.annotation, animated: true)
        
        if (view.annotation is Flag) {
            let flag = view.annotation as! Flag
            
            if control == view.rightCalloutAccessoryView {
                let alert = UIAlertController(title: currentPlayer?.name, message:flag.title, preferredStyle: .Alert)
                if currentPlayer != nil {
                    alert.addAction(UIAlertAction(title: "Walk here", style: .Default, handler: { (action: UIAlertAction!) in
                        self.latestAction = .Walk
                        self.currentPlayer?.moveToLocation(flag.coordinate)
                    }))
                    alert.addAction(UIAlertAction(title: "Run here", style: .Default, handler: { (action: UIAlertAction!) in
                        self.latestAction = .Run
                        self.currentPlayer?.moveToLocation(flag.coordinate, shouldRun: true)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Jump here", style: .Default, handler: { (action: UIAlertAction!) in
                        self.latestAction = .Jump
                        self.currentPlayer?.jumpToLocation(flag.coordinate)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Load Pokemon map data in this location", style: .Default, handler: { (action: UIAlertAction!) in
                        self.setNextLocation(flag.coordinate)
                    }))
                }
                alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { (action: UIAlertAction!) in
                    mapView.removeAnnotation(view.annotation!)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true){}
                
            } else {
                if currentPlayer != nil {
                    if latestAction == .Walk {
                        self.currentPlayer?.moveToLocation(flag.coordinate)
                    } else if latestAction == .Run {
                        self.currentPlayer?.moveToLocation(flag.coordinate, shouldRun: true)
                    } else if latestAction == .Jump {
                        self.currentPlayer?.jumpToLocation(flag.coordinate)
                    } else {
                        // why!!!
                    }
                }
            }
        } else if (view.annotation is Player) {
            //let player = view.annotation as! Player
            //selectPlayer(player)
        } else if (view.annotation is Gym || view.annotation is Pokemon || view.annotation is Pokestop) {
            if control == view.rightCalloutAccessoryView {
                let alert = UIAlertController(title: currentPlayer?.name, message:view.annotation!.title!, preferredStyle: .Alert)
                if currentPlayer != nil {
                    alert.addAction(UIAlertAction(title: "Walk here", style: .Default, handler: { (action: UIAlertAction!) in
                        self.latestAction = .Walk
                        self.currentPlayer?.moveToLocation(view.annotation!.coordinate)
                    }))
                    alert.addAction(UIAlertAction(title: "Run here", style: .Default, handler: { (action: UIAlertAction!) in
                        self.latestAction = .Run
                        self.currentPlayer?.moveToLocation(view.annotation!.coordinate, shouldRun: true)
                    }))
                    alert.addAction(UIAlertAction(title: "Jump here", style: .Default, handler: { (action: UIAlertAction!) in
                        self.latestAction = .Jump
                        self.currentPlayer?.jumpToLocation(view.annotation!.coordinate)
                    }))
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true){}
            } else {
                if latestAction == .Walk {
                    self.currentPlayer?.moveToLocation(view.annotation!.coordinate)
                } else if latestAction == .Run {
                    self.currentPlayer?.moveToLocation(view.annotation!.coordinate, shouldRun: true)
                } else if latestAction == .Jump {
                    self.currentPlayer?.jumpToLocation(view.annotation!.coordinate)
                } else {
                    // why!!!
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.lineWidth = 1
        circleRenderer.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.2)
        circleRenderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.85)
        
        return circleRenderer
    }
    
    func showMapOnLocation() {
        mapView.setCamera(MKMapCamera(lookingAtCenterCoordinate: mapCenterCoordinate, fromEyeCoordinate: mapCenterCoordinate, eyeAltitude: 500.0), animated: false)
    }
    
    //MARK: NSUserDefaults
    func saveLocation() {
        NSUserDefaults.standardUserDefaults().setObject(["lat":"\(mapCenterCoordinate.latitude)", "lng":"\(mapCenterCoordinate.longitude)"], forKey: "savedLocation")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func getSavedMapType() {
        let savedType = NSUserDefaults.standardUserDefaults().integerForKey("mapType")
        currentMapType = savedType
        switch (currentMapType) {
        case 0:
            mapView.mapType = MKMapType.Standard
        case 2:
            mapView.mapType = MKMapType.Satellite
        default:
            mapView.mapType = MKMapType.Hybrid
        }
        mapTypeSegmentedControl.selectedSegmentIndex = currentMapType
    }
    
    func getSavedLocation() -> Bool {
        guard let savedLocation = NSUserDefaults.standardUserDefaults().objectForKey("savedLocation") else {
            return false
        }
        return putCurrentLocationFromDict(savedLocation as! [String : String])
    }
    
    func getPlayersLocationDict() -> [[String:String]] {
        var locations = [[String:String]]()
        for player in players {
            locations.append(["lat":"\(player.coordinate.latitude)", "lng":"\(player.coordinate.longitude)"])
        }
        return locations
    }
    
    func putCurrentLocationFromDict(dict: [String:String]) -> Bool {
        mapCenterCoordinate = CLLocationCoordinate2D(latitude: Double(dict["lat"]!)!, longitude: Double(dict["lng"]!)!)
        return true
    }
    
    //MARK: GestureRecognizer
    func routeMapLongPressSelector(sender: UIPanGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.Began) {
            let touchPoint = sender.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = Flag(coordinate: newCoordinates)
            mapView.addAnnotation(annotation)
        }
        
    }
    
    func setNextLocation (coord:CLLocationCoordinate2D) {
        let url = "\(FLASK_SERVER)/next_loc?lat=\(coord.latitude)&lon=\(coord.longitude)"
        //let params:[String:Double] = ["lat": coord.latitude, "lon" : coord.longitude ]
        Alamofire.request(.POST, url)
            .validate()
            .response { request, response, data, error in
                print(response)
                print(error)
        }
    }
    
    func createPlayer (playerName:String) {
        
        if (playerName ?? "").isEmpty {
            let alert = UIAlertController(title: "", message:"Player name required!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true){}
            return
        }
        
        if (players.count >= 2 ) {
            let alert = UIAlertController(title: "", message:"Can't add more player?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true){}
            return
        }
        
        let player = Player(name: playerName, coordinate: mapCenterCoordinate)
        player.delegate = self
        player.imageName = "player"
        self.players.append(player)

        selectPlayer(player)
        
        mapView.addAnnotation(player)
        mapView.selectAnnotation(player, animated: true)
    }
    
    //MARK: IBActions
    @IBAction func mapTypeChange (sender:AnyObject) {
        let mapType = MKMapType(rawValue: UInt(mapTypeSegmentedControl.selectedSegmentIndex))
        switch (mapType!) {
        case .Standard:
            mapView.mapType = MKMapType.Standard
            currentMapType = 0
        case .Hybrid:
            mapView.mapType = MKMapType.Satellite
            currentMapType = 2
        default:
            mapView.mapType = MKMapType.Hybrid
            currentMapType = 1
        }
        NSUserDefaults.standardUserDefaults().setInteger(currentMapType, forKey: "mapType")
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    @IBAction func addPlayer (sender:AnyObject) {
        let alert = UIAlertController(title: "Add Player?", message:"Add new player on map?", preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.placeholder = "Player name goes here..";
        })
        
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
            let textField = alert.textFields![0] as UITextField
            let playerName = textField.text!
            self.createPlayer(playerName)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        
        self.presentViewController(alert, animated: true){}
    }
    
    @IBAction func stopPlayer(sender: UIButton) {
        currentPlayer?.stop()
    }
    
    //MARK: GCDWebServer
    
    func startWebServer(){
        webServer.addDefaultHandlerForMethod("GET", requestClass: GCDWebServerRequest.self, processBlock: {request in
            return GCDWebServerDataResponse.init(JSONObject: self.getPlayersLocationDict())
        })
        webServer.startWithPort(80, bonjourName: "pokemonController")
    }
    
    func loadPokemapData() {
        let url =  "\(FLASK_SERVER)/raw_data?pokestops=true&scanned=false"
        Alamofire.request(.GET, url)
            .responseJSON { response in
                if let json = response.result.value {
                    let swiftyJsonVar = JSON(json)
                    
                    var g = [Gym]()
                    var p = [Pokemon]()
                    var ps = [Pokestop]()
                    
                    if let arrayGym = swiftyJsonVar["gyms"].array {
                        for a in arrayGym {
                            let c = CLLocationCoordinate2D(latitude: a["latitude"].doubleValue, longitude: a["longitude"].doubleValue)
                            let gym = Gym(coordinate:c, teamId: a["team_id"].intValue, prestige: a["gym_points"].intValue)
                            g.append(gym)
                        }
                    }

                    
                    if let arrayPokemons = swiftyJsonVar["pokemons"].array {
                        for a in arrayPokemons {
                            let c = CLLocationCoordinate2D(latitude: a["latitude"].doubleValue, longitude: a["longitude"].doubleValue)
                            let pokemon = Pokemon(coordinate: c, pokemonId: a["pokemon_id"].intValue, disappear_time: a["disappear_time"].doubleValue, name: a["pokemon_name"].stringValue)
                            let epocTime = NSTimeInterval(pokemon.disappear_time/1000)
                            let nowTimestamp = NSDate().timeIntervalSince1970
                            if (epocTime > nowTimestamp) {
                                p.append(pokemon)
                            }
                        }
                    }
                    
                    if let arrayPokestops = swiftyJsonVar["pokestops"].array {
                        for a in arrayPokestops {
                            let c = CLLocationCoordinate2D(latitude: a["latitude"].doubleValue, longitude: a["longitude"].doubleValue)
                            let pokestop = Pokestop(coordinate: c, lureDisappearTime: a["lure_expiration"].doubleValue)
                            ps.append(pokestop)
                        }
                    }
                    
                    self.mapView.removeAnnotations(self.gyms)
                    self.mapView.removeAnnotations(self.pokemons)
                    self.mapView.removeAnnotations(self.pokestops)

                    self.gyms = g
                    self.pokemons = p
                    self.pokestops = ps
                    
                    self.mapView.addAnnotations(self.pokestops)
                    self.mapView.addAnnotations(self.gyms)
                    self.mapView.addAnnotations(self.pokemons)
                    MapData.updateMapCallOutTitle(self.mapView)
                } else {
                    print ("failed to load pokemap json")
                }
        }
        
    }

    //MARK: Player & PlayerDelegate
    func selectPlayer (player:Player) {
        currentPlayer = player
    }
    
    func onPlayerMoving (player: Player) {
        self.mapView.viewForAnnotation(player)
        stopButton.enabled = true
    }
    
    func onPlayerMovingStart (player: Player) {
        stopButton.enabled = true
        loadPokemapData()
    }
    func onPlayerMovingFinish (player: Player) {
        stopButton.enabled = false
    }
}