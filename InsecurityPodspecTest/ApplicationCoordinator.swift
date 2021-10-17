import Insecurity

class ApplicationCoordinator: WindowCoordinator {
    func start() {
        let mainCoordinator = MainCoordinator()
        
        self.start(mainCoordinator, duration: nil, options: nil) { _ in
            
        }
    }
}
