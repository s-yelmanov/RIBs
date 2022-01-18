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

public protocol FlowPresentationRoutine: BasePresentationRoutine {
    typealias BaseCompletion = () -> Void

    var flowTransition: FlowTransition { get set }
    var navigationViewControllable: FlowViewControllable { get }

    func push(viewController: ViewControllable, transition: FlowTransition, completion: BaseCompletion?)
    func pop(to viewController: ViewControllable, animated: Bool, completion: BaseCompletion?)
    func pop(animated: Bool, completion: BaseCompletion?)
}

extension FlowPresentationRoutine {
    public func push(viewController: ViewControllable, transition: FlowTransition, completion: BaseCompletion?) {
        flowTransition = transition
        navigationViewControllable.uiViewController.pushViewController(
            viewController.uiViewController,
            animated: transition.animated,
            completion: completion
        )
    }

    public func pop(to viewController: ViewControllable, animated: Bool, completion: BaseCompletion?) {
        navigationViewControllable.uiViewController.popToViewController(
            viewController.uiViewController,
            animated: animated,
            completion: completion
        )
    }

    public func pop(animated: Bool, completion: BaseCompletion?) {
        navigationViewControllable.uiViewController.popViewController(animated: animated, completion: completion)
    }

    public func replaceRoot(with viewController: ViewControllable, transition: FlowTransition, completion: BaseCompletion?) {
        navigationViewControllable.uiViewController.replaceRootViewController(
            with: viewController.uiViewController,
            animated: flowTransition.animated,
            completion: completion
        )
    }
}
