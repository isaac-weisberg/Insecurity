import XCTest
@testable import Insecurity
@testable import InsecurityAutotestHost
import Nimble

@MainActor
final class InsecurityAutotestTests: XCTestCase {
    let root = ViewController.shared
    
    func testBasicMount() async {
        let root = self.root
        
        let insecurityHost = InsecurityHost()
        
        let child = TestModalCoordinator<Void>()
        
        insecurityHost.mount(child, on: root, animated: false, { _ in
            
        })
        
        expect(root.modalChain) == [child.instantiatedVC]
        
        await root.dismissAndAwait()
    }
}
