//
//  Pokestop.swift
//  PokemonController
//
//  Created by Ramadhan Noor on 7/22/16.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Foundation
import MapKit

class Pokestop: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let lureDisappearTime:NSTimeInterval
    dynamic var title: String?
    
    init(coordinate: CLLocationCoordinate2D, lureDisappearTime:NSTimeInterval) {
        self.coordinate = coordinate
        self.lureDisappearTime = lureDisappearTime
        super.init()
    }
    
    class func createViewAnnotationForMapView(mapview: MKMapView, annotation: MKAnnotation) -> MKAnnotationView {
        var returnedAnnotationView =
            mapview.dequeueReusableAnnotationViewWithIdentifier(String(Pokestop.self))
        if returnedAnnotationView == nil {
            returnedAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(Pokestop.self))
            returnedAnnotationView!.canShowCallout = true
            returnedAnnotationView!.centerOffset = CGPointMake(returnedAnnotationView!.centerOffset.x + (returnedAnnotationView!.image?.size.width ?? 0)/2, returnedAnnotationView!.centerOffset.y - (returnedAnnotationView!.image?.size.height ?? 0)/2)
        } else {
            returnedAnnotationView!.annotation = annotation
        }
        return returnedAnnotationView!
    }

}