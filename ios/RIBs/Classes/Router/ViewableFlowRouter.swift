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

/// The base protocol for all routers that own navigation controller.
public protocol ViewableFlowRouting: Routing {

    // The following methods must be declared in the base protocol, since `Router` internally invokes these methods.
    // In order to unit test router with a mock child router, the mocked child router first needs to conform to the
    // custom subclass routing protocol, and also this base protocol to allow the `Router` implementation to execute
    // base class logic without error.

    /// The base view controllable associated with this `Router`.
    var navigationViewControllable: FlowViewControllable { get }

    func routeToInitialComponent()
}

// swiftlint:disable:next generic_type_name
open class ViewableFlowRouter<FlowInteractorType, FlowViewControllerType>: Router<FlowInteractorType>,
                                                                           ViewableFlowRouting,
                                                                           FlowPresentationRoutine {

    public var viewControllable: ViewControllable { navigationViewControllable }

    /// The corresponding `ViewController` owned by this `Router`.
    public let navigationViewController: FlowViewControllerType

    /// The base `FlowViewControllable` associated with this `Router`.
    public let navigationViewControllable: FlowViewControllable

    // MARK: - FlowPresentationRoutine

    public var viewablePresentation: ViewablePresentation.RawValue?
    public var flowTransition: FlowTransition = .default

    /// Initializer.
    ///
    /// - parameter interactor: The corresponding `Interactor` of this `Router`.
    /// - parameter viewController: The corresponding `ViewController` of this `Router`.
    public init(interactor: FlowInteractorType, viewController: FlowViewControllerType) {
        self.navigationViewController = viewController
        guard let navigationViewControllable = viewController as? FlowViewControllable else {
            fatalError("\(viewController) should conform to \(FlowViewControllable.self)")
        }
        self.navigationViewControllable = navigationViewControllable

        super.init(interactor: interactor)

        self.navigationControllerDelegateProxy.handler = self
        self.navigationViewControllable.uiViewController.delegate = navigationControllerDelegateProxy
    }

    open func routeToInitialComponent() {
        fatalError("This method should be overridden by the subclass.")
    }

    // MARK: - Internal

    override func internalDidLoad() {
        setupViewControllerLeakDetection()

        super.internalDidLoad()
    }

    // MARK: - FlowPresentationRoutine

    public func push(viewController: ViewControllable, transition: FlowTransition, completion: BaseCompletion?) {
        navigationControllerDelegateProxy.startPresentation()

        flowTransition = transition
        navigationViewControllable.uiViewController.pushViewController(
            viewController.uiViewController,
            animated: transition.animated,
            completion: completion
        )
    }

    public func replaceRoot(with viewController: ViewControllable, transition: FlowTransition, completion: BaseCompletion?) {
        replaceRoot(with: [viewController], transition: transition, completion: completion)
    }

    public func replaceRoot(with viewControllers: [ViewControllable], transition: FlowTransition, completion: BaseCompletion?) {
        navigationControllerDelegateProxy.startPresentation()

        flowTransition = transition
        navigationViewControllable.uiViewController.replaceViewControllers(
            with: viewControllers.map(\.uiViewController),
            animated: flowTransition.animated,
            completion: completion
        )
    }

    // MARK: - Private

    private var viewControllerDisappearExpectation: LeakDetectionHandle?

    private func setupViewControllerLeakDetection() {
        let cancellable = interactable.isActiveStream
            // Do not retain self here to guarantee execution. Retaining self will cause the cancellables to never be
            // cancelled, thus self is never deallocated. Also cannot just store the cancellable and call cancel(),
            // since we want to keep the subscription alive until deallocation, in case the router is re-attached.
            // Using weak does require the router to be retained until its interactor is deactivated.
            .sink(receiveValue: { [weak self] (isActive: Bool) in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.viewControllerDisappearExpectation?.cancel()
                strongSelf.viewControllerDisappearExpectation = nil

                if !isActive {
                    let viewController = strongSelf.navigationViewControllable.uiViewController
                    strongSelf.viewControllerDisappearExpectation = LeakDetector.instance.expectViewControllerDisappear(
                        viewController: viewController
                    )
                }
            })

        deinitCancellable.insert(cancellable)
    }

    private let navigationControllerDelegateProxy = NavigationControllerDelegateProxy()

    /// This method is called from NavigationControllerDelegateProxyMethodsHandler to perform resources cleanup
    open func didDetachChild(child: ViewableRouting) {
        fatalError("This method should be overridden by the subclass.")
    }
}
