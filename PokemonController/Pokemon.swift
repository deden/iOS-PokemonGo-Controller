//
//  Pokemon.swift
//  PokemonController
//
//  Created by Ramadhan Noor on 7/22/16.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Foundation
import MapKit

class Pokemon: NSObject, MKAnnotation {
    let name: String
    let coordinate: CLLocationCoordinate2D
    let pokemonId:Int
    //let disappear_time_formatted: String
    let disappear_time:Int
    
    dynamic var title: String?
    
    init(coordinate: CLLocationCoordinate2D, pokemonId:Int, disappear_time:Int, name:String) {
        self.coordinate = coordinate
        self.pokemonId = pokemonId
        self.disappear_time = disappear_time
        self.name = name
        super.init()
    }
    
    /*
    var title: String? {
        return "\(name) (\(disappear_time))"
    }
     */
    
    class func createViewAnnotationForMapView(mapview: MKMapView, annotation: MKAnnotation) -> MKAnnotationView {
        var returnedAnnotationView =
            mapview.dequeueReusableAnnotationViewWithIdentifier(String(Pokemon.self))
        if returnedAnnotationView == nil {
            returnedAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(Pokemon.self))
            returnedAnnotationView!.canShowCallout = true
            returnedAnnotationView!.centerOffset = CGPointMake(returnedAnnotationView!.centerOffset.x + (returnedAnnotationView!.image?.size.width ?? 0)/2, returnedAnnotationView!.centerOffset.y - (returnedAnnotationView!.image?.size.height ?? 0)/2)
        } else {
            returnedAnnotationView!.annotation = annotation
        }
        return returnedAnnotationView!
    }

}