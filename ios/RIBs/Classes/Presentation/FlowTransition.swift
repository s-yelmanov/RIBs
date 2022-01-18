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

public enum FlowTransition {
    case `default`
    case custom(push: UIViewControllerAnimatedTransitioning?, pop: UIViewControllerAnimatedTransitioning?)
    case notAnimated

    var animated: Bool {
        switch self {
        case .notAnimated:
            return false
        case .custom, .default:
            return true
        }
    }

    public static func push(_ transition: UIViewControllerAnimatedTransitioning?) -> FlowTransition {
        .custom(push: transition, pop: nil)
    }

    public static func pop(_ transition: UIViewControllerAnimatedTransitioning?) -> FlowTransition {
        .custom(push: nil, pop: transition)
    }
}
