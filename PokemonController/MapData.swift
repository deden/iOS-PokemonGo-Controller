//
//  MapData.swift
//  PokemonController
//
//  Created by Ramadhan Noor on 7/22/16.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Foundation
import MapKit
import SwiftyJSON

class MapData: NSObject {
    static var pokemonJSON:JSON? = nil
    static var disappearTick:NSTimer?
    static var map:MKMapView!
    
    class func getPokemonNameById(pokemonId:Int!) -> String {
        if (MapData.pokemonJSON == nil) {
            let path = NSBundle.mainBundle().pathForResource("pokemon.en", ofType: "json")
            let jsonData = NSData(contentsOfFile:path!)
            MapData.pokemonJSON = JSON(data: jsonData!)
        }
        
        return MapData.pokemonJSON![pokemonId].stringValue
    }
    
    class func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    @objc class func tick() {
        for annotation in MapData.map.annotations {
            if annotation is Pokemon {
                let pokemon = annotation as! Pokemon
                let epocTime = NSTimeInterval(pokemon.disappear_time/1000)
                let nowTimestamp = NSDate().timeIntervalSince1970
                let elapsed = epocTime - nowTimestamp
                if (elapsed > 0) {
                    let elapsedFormat = MapData.stringFromTimeInterval(elapsed)
                    pokemon.title = "\(pokemon.name) \(elapsedFormat)"
                } else {
                    pokemon.title = "\(pokemon.name) expired"
                }
            } else if annotation is Pokestop {
                let pokestop = annotation as! Pokestop
                let epocTime = NSTimeInterval(pokestop.lureDisappearTime/1000)
                if (epocTime > 0) {
                    let nowTimestamp = NSDate().timeIntervalSince1970
                    let elapsed = epocTime - nowTimestamp
                    let elapsedFormat = MapData.stringFromTimeInterval(elapsed)
                    if (elapsed > 0) {
                        pokestop.title = "Lured Pokestop, expires in \(elapsedFormat)"
                    } else {
                        pokestop.title = "Pokestop"
                    }
                } else {
                    pokestop.title = "Pokestop"
                }
            }
        }
    }
    
    class func updateMapCallOutTitle (map:MKMapView!) {
        MapData.map = map
        MapData.resetTimer()
        MapData.disappearTick = NSTimer.scheduledTimerWithTimeInterval(1.0,
                                                               target: MapData.self,
                                                               selector: #selector(MapData.tick),
                                                               userInfo: nil,
                                                               repeats: true)
    }
    
    class func resetTimer () {
        MapData.disappearTick?.invalidate()
    }


}