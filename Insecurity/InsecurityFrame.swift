import UIKit

struct FrameNavigationChild {
    let coordinator: CommonNavigationCoordinatorAny
    let controller: Weak<UIViewController>
    let previousController: Weak<UIViewController>
    
    init(
        coordinator: CommonNavigationCoordinatorAny,
        controller: Weak<UIViewController>,
        previousController: Weak<UIViewController>
    ) {
        self.coordinator = coordinator
        self.controller = controller
        self.previousController = previousController
    }
}

struct FrameNavigationData {
    let children: [FrameNavigationChild]
    let navigationController: Weak<UINavigationController>
    let rootController: Weak<UIViewController>
    
    init(
        children: [FrameNavigationChild],
        navigationController: UINavigationController,
        rootController: UIViewController
    ) {
        self.init(children: children,
                  navigationController: Weak(navigationController),
                  rootController: Weak(rootController))
    }
    
    private init(children: [FrameNavigationChild],
                 navigationController: Weak<UINavigationController>,
                 rootController: Weak<UIViewController>) {
        self.children = children
        self.navigationController = navigationController
        self.rootController = rootController
    }
    
    func replacingChildren(_ children: [FrameNavigationChild]) -> FrameNavigationData {
        return FrameNavigationData(children: children,
                                   navigationController: self.navigationController,
                                   rootController: self.rootController)
    }
}

struct Frame {
    let coordinator: CommonCoordinatorAny
    let controller: Weak<UIViewController>
    let previousController: Weak<UIViewController>
    let navigationData: FrameNavigationData?
    
    init(
        coordinator: CommonCoordinatorAny,
        controller: UIViewController,
        previousController: UIViewController,
        navigationData: FrameNavigationData?
    ) {
        self.init(coordinator: coordinator,
                  controller: Weak(controller),
                  previousController: Weak(previousController),
                  navigationData: navigationData)
    }
    
    init(
        coordinator: CommonCoordinatorAny,
        controller: Weak<UIViewController>,
        previousController: Weak<UIViewController>,
        navigationData: FrameNavigationData?
    ) {
        self.coordinator = coordinator
        self.controller = controller
        self.previousController = previousController
        self.navigationData = navigationData
    }
    
    func replacingNavigationData(_ newNavData: FrameNavigationData) -> Frame {
        return Frame(coordinator: self.coordinator,
                     controller: self.controller,
                     previousController: self.previousController,
                     navigationData: newNavData)
    }
}

extension Array where Element == Frame {
    func topIndex() -> CoordinatorIndex? {
        if isEmpty {
            return nil
        }
        let modalIndex = count - 1
        
        if let navigationData = self[modalIndex].navigationData {
            let navIndex: Int?
            if navigationData.children.isEmpty {
                navIndex = nil
            } else {
                navIndex = navigationData.children.count - 1
            }
            return CoordinatorIndex(modalIndex: modalIndex,
                                    navigationData: CoordinatorIndex.NavigationData(navigationIndex: navIndex))
        }
        return CoordinatorIndex(modalIndex: modalIndex, navigationData: nil)
    }
}

extension Sequence where Element == Frame {
    func dismountFromHost() {
        for frame in self {
            frame.coordinator.dismountFromHost()
            frame.navigationData?.children.forEach { child in
                child.coordinator.dismountFromHost()
            }
        }
    }
}
