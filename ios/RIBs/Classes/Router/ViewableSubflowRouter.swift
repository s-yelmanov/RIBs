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

import UIKit

/// The base protocol for all routers that own navigation controller.
public protocol ViewableSubflowRouting: Routing {
    var parent: ViewableSubflowParentRouting? { get }
    var routeIdentifier: String { get }

    func ensureChildrenConsistency()
    func ensureViewStackConsistency()
}

public extension ViewableSubflowRouting {
    var routeIdentifier: String { String(describing: Self.self) }
}

public typealias ViewableSubflowParentRouting = ViewableFlowRouting & FlowPresentationRoutine
open class ViewableSubflowRouter<InteractorType>: Router<InteractorType>,
                                                  ViewableSubflowRouting,
                                                  FlowPresentationRoutine,
                                                  AdaptiveViewableRouting {
    public var viewablePresentation: ViewablePresentation.RawValue?
    public var viewControllable: ViewControllable { navigationViewControllable }

    public weak var parent: ViewableSubflowParentRouting?

    private var viewControllers: [UIViewController] = []


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
        // No-op
    }

    /// This method is called once the subflow is being detached to perform resources cleanup
    open func didDetachSubflow(subflow: ViewableSubflowRouting) {
        // No-op
    }

    // MARK: - FlowPresentationRoutine

    public var navigationViewControllable: FlowViewControllable { parent?.navigationViewControllable ?? UINavigationController() }
    public var flowTransition: FlowTransition {
        get { parent?.flowTransition ?? .default }
        set { parent?.flowTransition = newValue }
    }

    public func push(viewController: ViewControllable, transition: FlowTransition, completion: FlowPresentationRoutine.BaseCompletion?) {
        parent?.push(viewController: viewController, transition: transition, completion: completion)
        ensureViewStackConsistency()
    }

    public func pop(animated: Bool, completion: FlowPresentationRoutine.BaseCompletion?) {
        guard viewControllers.last === parentViewControllersStack.last else {
            return assertionFailure("Attempt to pop view controller that current subflow doesn't own")
        }
        parent?.pop(animated: animated, completion: completion)
        ensureViewStackConsistency()
    }

    // MARK: - ViewableSubflowRouting

    public func ensureChildrenConsistency() {
        viewableSubflowChildren
            .forEach { subflow in
                subflow.ensureChildrenConsistency()

                guard subflow.children.isEmpty else { return }
                self.detachChild(subflow)
                self.didDetachSubflow(subflow: subflow)
            }

        children
            .compactMap { $0 as? ViewableRouting }
            .filter { child in
                parentViewControllersStack.contains(child.viewControllable.uiViewController) == false
            }
            .forEach { child in
                self.detachChild(child)
                self.didDetachChild(child: child)
            }

        ensureViewStackConsistency()
    }

    public func ensureViewStackConsistency() {
        let viewableChildren = viewableChildren.map(\.viewControllable.uiViewController)
        viewControllers = parentViewControllersStack.filter(viewableChildren.contains)
    }

    // MARK: - AdaptiveViewableRouting

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        detachCurrentChild()
    }
}

extension ViewableSubflowRouting {
    var allChildViewControllers: [UIViewController] {
        children.reduce(.init()) { result, next -> [UIViewController] in
            if let subflow = next as? ViewableSubflowRouting {
                return result + subflow.allChildViewControllers
            } else if let viewableChild = next as? ViewableRouting {
                return result + [viewableChild.viewControllable.uiViewController]
            }
            return result
        }
    }
}
