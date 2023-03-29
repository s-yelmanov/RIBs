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

public protocol NavigationContainable {
    var navigationViewControllable: FlowViewControllable { get }
}

public protocol FlowPresentationRoutine: BasePresentationRoutine, NavigationContainable {
    typealias BaseCompletion = () -> Void

    var flowTransition: FlowTransition { get set }

    func push(viewController: ViewControllable, transition: FlowTransition, completion: BaseCompletion?)
    func pop(animated: Bool, completion: BaseCompletion?)

    func pushAttached(router: ViewableRouting, transition: FlowTransition, completion: BaseCompletion?, unique: Bool)
    func popDetached(animated: Bool, completion: BaseCompletion?)
}
