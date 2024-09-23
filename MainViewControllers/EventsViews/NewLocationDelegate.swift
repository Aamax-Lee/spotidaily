//
//  NewLocationDelegate.swift
//  musictime
//
//  Created by Aamax Lee on 21/5/2024.
//

import Foundation

protocol NewLocationDelegate: NSObject {
    func annotationAdded(annotation: LocationAnnotation)
    
    }
