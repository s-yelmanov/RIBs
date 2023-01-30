//
//  RouteIdentifiable.swift
//  
//
//  Created by Vladyslav Skintiian on 30.01.2023.
//

import Foundation

public protocol RouteIdentifiable {
    var routeIdentifier: String { get }
}

public extension RouteIdentifiable {
    var routeIdentifier: String { String(describing: Self.self) }
}
