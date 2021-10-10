import Insecurity

class ApplicationCoordinator: WindowCoordinator {
    func start() {
        let mainCoordinator = MainCoordinator()
        
        self.start(mainCoordinator, animated: true) { _ in
            
        }
    }
}
