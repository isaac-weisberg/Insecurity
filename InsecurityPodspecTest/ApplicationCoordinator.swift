import Insecurity

class ApplicationCoordinator: WindowCoordinator {
    func start() {
        let mainCoordinator = MainCoordinator()
        
        self.navigation.start(mainCoordinator, duration: nil, options: nil) { _ in
            
        }
    }
}
