//
//  Gym.swift
//  PokemonController
//
//  Created by Ramadhan Noor on 7/22/16.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Foundation
import MapKit

class Gym: NSObject, MKAnnotation {
    let prestige: Int
    let teamId: Int
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D, teamId:Int, prestige:Int) {
        self.coordinate = coordinate
        self.teamId = teamId
        self.prestige = prestige
        super.init()
    }
    
    var title: String? {
        let str = teamId == 0 ? "Gym" : teamId == 1 ? "Mystic" : teamId == 2 ? "Valor" : "Instict"
        return "\(str) Prestige : \(prestige)"
    }
    
    
    class func createViewAnnotationForMapView(mapview: MKMapView, annotation: MKAnnotation) -> MKAnnotationView {
        var returnedAnnotationView =
            mapview.dequeueReusableAnnotationViewWithIdentifier(String(Gym.self))
        if returnedAnnotationView == nil {
            returnedAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(Gym.self))
            
            returnedAnnotationView!.canShowCallout = true
            returnedAnnotationView!.centerOffset = CGPointMake(returnedAnnotationView!.centerOffset.x + (returnedAnnotationView!.image?.size.width ?? 0)/2, returnedAnnotationView!.centerOffset.y - (returnedAnnotationView!.image?.size.height ?? 0)/2)
        } else {
            returnedAnnotationView!.annotation = annotation
        }
        return returnedAnnotationView!
    }
}