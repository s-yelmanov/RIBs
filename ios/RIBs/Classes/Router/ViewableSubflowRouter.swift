//
//  Copyright (c) 2017. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import UIKit

/// The base protocol for all routers that own navigation controller.
public protocol ViewableSubflowRouting: Routing {
    var parent: ViewableSubflowParentRouting? { get }

    func ensureChildrenConsistency()
    func ensureViewStackConsistency()
}

public typealias ViewableSubflowParentRouting = ViewableFlowRouting & FlowPresentationRoutine
open class ViewableSubflowRouter<InteractorType>: Router<InteractorType>,
                                                  ViewableSubflowRouting,
                                                  SubflowPresentationRoutine {
    public var viewablePresentation: ViewablePresentation.RawValue?
    public var viewControllable: ViewControllable { navigationViewControllable }

    public weak var parent: ViewableSubflowParentRouting?

    private var viewControllers: [UIViewController] = []

    // MARK: - FlowPresentationRoutine

    public var navigationViewControllable: FlowViewControllable { parent?.navigationViewControllable ?? UINavigationController() }
    public var flowTransition: FlowTransition {
        get { parent?.flowTransition ?? .default }
        set { parent?.flowTransition = newValue }
    }

    public func push(viewController: ViewControllable, transition: FlowTransition, completion: FlowPresentationRoutine.BaseCompletion?) {
        viewControllers.append(viewController.uiViewController)
        parent?.push(viewController: viewController, transition: transition, completion: completion)
    }

    public func pop(animated: Bool, completion: FlowPresentationRoutine.BaseCompletion?) {
        guard
            let lastParentViewController = parent?.navigationViewControllable.uiViewController.viewControllers.last,
            viewControllers.last === lastParentViewController
        else {
            return
        }

        parent?.pop(animated: animated, completion: completion)
        viewControllers.removeLast()
    }

    // MARK: - ViewableSubflowRouting

    public func ensureChildrenConsistency() {
        children
            .compactMap { $0 as? ViewableSubflowRouting }
            .forEach { $0.ensureChildrenConsistency() }

        children
            .compactMap { $0 as? ViewableRouting }
            .filter { child in
                let viewControllers = parent?.navigationViewControllable.uiViewController.viewControllers
                return viewControllers?.contains(child.viewControllable.uiViewController) == false
            }
            .forEach { child in
                self.detachChild(child)
                self.didDetachChild(child: child)
            }
    }

    public func ensureViewStackConsistency() {
        viewControllers = viewControllers.filter { controller in
            navigationViewControllable.uiViewController.viewControllers.contains(controller)
        }
    }

    /// Initializer.
    ///
    /// - parameter interactor: The corresponding `Interactor` of this `Router`.
    /// - parameter parent: The corresponding parent `ViewableSubflowParentRouting` for this `Router`.
    public init(interactor: InteractorType, parent: ViewableSubflowParentRouting) {
        self.parent = parent
        super.init(interactor: interactor)
    }

    /// This method is called from NavigationControllerDelegateProxyMethodsHandler to perform resources cleanup
    open func didDetachChild(child: ViewableRouting) {
        fatalError("This method should be overridden by the subclass.")
    }
}
