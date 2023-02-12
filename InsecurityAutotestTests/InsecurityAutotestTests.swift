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
    
    func testDismissToMiddleOfNavController() async {
        Insecurity.loggerMode = .full
        
        // MARK: Setup
        let root = self.root
        
        let host = InsecurityHost()
        
        let modal1 = TestModalCoordinator<Type1>()
        
        host.mount(modal1, on: root, animated: false, { _ in
            
        })
        
        await awaitAnimsShort()
        
        let navRoot1 = TestNavigationCoordinator<Type2>()
        
        let navChildren1 = [ TestNavigationCoordinator<Type2>(), TestNavigationCoordinator<Type2>() ]
        
        modal1.start(TestNavigationController(),
                     navRoot1,
                     animated: false) { _ in
            
        }
        
        await awaitAnimsShort()
        
        var parent1 = navRoot1
        for navChild in navChildren1 {
            parent1.start(navChild, animated: false) { _ in }
            
            await awaitAnimsShort()
            
            parent1 = navChild
        }
        
        let modal2 = TestModalCoordinator<Type3>()
        
        navChildren1.last!.start(modal2, animated: false, { _ in })
        
        await awaitAnimsShort()
        
        let navRoot2 = TestNavigationCoordinator<Type4>()
        
        let navChildren2 = [ TestNavigationCoordinator<Type4>(), TestNavigationCoordinator<Type4>() ]
        
        modal2.start(TestNavigationController(),
                     navRoot2,
                     animated: false) { _ in
            
        }
        
        await awaitAnimsShort()
        
        var parent2 = navRoot2
        for navChild in navChildren2 {
            parent2.start(navChild, animated: false) { _ in }
            
            await awaitAnimsShort()
            
            parent2 = navChild
        }
        
        let modal3 = TestModalCoordinator<Type5>()
        
        navChildren2.last!.start(modal3, animated: false, { _ in})
        
        await awaitAnimsShort()
        
        // MARK: Test
        
        expect(host.frames).to(haveCount(5))
        
        // MARK: Teardown
        await root.dismissAndAwait()
    }
}
