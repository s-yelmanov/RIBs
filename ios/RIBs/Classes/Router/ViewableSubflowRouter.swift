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
    func ensureChildrenConsistency()
    func ensureViewStackConsistency()
}

// swiftlint:disable:next generic_type_name
open class ViewableSubflowRouter<InteractorType>: Router<InteractorType>,
                                                  ViewableSubflowRouting,
                                                  SubflowPresentationRoutine {
    public var viewablePresentation: ViewablePresentation.RawValue?
    public var viewControllable: ViewControllable { navigationViewControllable }

    public let baseFlowRouter: ViewableFlowRouting & FlowPresentationRoutine

    private var viewControllers: [UIViewController] = []

    // MARK: - FlowPresentationRoutine

    public var navigationViewControllable: FlowViewControllable { baseFlowRouter.navigationViewControllable }
    public var flowTransition: FlowTransition {
        get { baseFlowRouter.flowTransition }
        set { baseFlowRouter.flowTransition = newValue }
    }

    public func push(viewController: ViewControllable, transition: FlowTransition, completion: FlowPresentationRoutine.BaseCompletion?) {
        viewControllers.append(viewController.uiViewController)
        baseFlowRouter.push(viewController: viewController, transition: transition, completion: completion)
    }

    public func pop(animated: Bool, completion: FlowPresentationRoutine.BaseCompletion?) {
        guard viewControllers.last === baseFlowRouter.navigationViewControllable.uiViewController.viewControllers.last else {
            return
        }
        baseFlowRouter.pop(animated: animated, completion: completion)
        viewControllers.removeLast()

        guard viewControllers.isEmpty else { return }
        didBecomeEmpty()
    }

    // MARK: - ViewableSubflowRouting

    public func ensureChildrenConsistency() {
        children
            .compactMap { $0 as? ViewableSubflowRouting }
            .forEach { $0.ensureChildrenConsistency() }

        children
            .compactMap { $0 as? ViewableRouting }
            .filter { child in
                baseFlowRouter.navigationViewControllable.uiViewController.viewControllers.contains(child.viewControllable.uiViewController) == false
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
    /// - parameter viewController: The corresponding `ViewController` of this `Router`.
    public init(interactor: InteractorType, baseFlowRouter: ViewableFlowRouting & FlowPresentationRoutine) {
        self.baseFlowRouter = baseFlowRouter
        super.init(interactor: interactor)
    }

    /// This method is called from NavigationControllerDelegateProxyMethodsHandler to perform resources cleanup
    open func didDetachChild(child: ViewableRouting) {
        fatalError("This method should be overridden by the subclass.")
    }

    open func didBecomeEmpty() {
        fatalError("This method should be overridden by the subclass.")
    }
}
