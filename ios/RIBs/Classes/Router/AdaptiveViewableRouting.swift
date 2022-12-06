//
//  AdaptiveViewableRouting.swift
//  
//
//  Created by Sergey Yelmanov on 06.12.2022.
//

import UIKit

/// The base protocol for all routers for `UIAdaptivePresentationControllerDelegate` conformance.
public protocol AdaptiveViewableRouting: UIAdaptivePresentationControllerDelegate {
    var viewControllable: ViewControllable { get }
}
