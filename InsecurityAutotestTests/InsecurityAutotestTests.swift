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
        
        modal2.start(TestNavigationController(),
                     navRoot2,
                     animated: false) { _ in
            modal2.dismiss()
        }
        
        await awaitAnimsShort()
        
        let navChildren2 = [ TestNavigationCoordinator<Type4>(), TestNavigationCoordinator<Type4>() ]
        
        navRoot2.start(navChildren2[0], animated: true, { _ in})
        
        await awaitAnims()
        
        navChildren2[0].start(navChildren2[1], animated: true, { _ in
            navChildren2[0].dismiss()
        })
        
        let modal3 = TestModalCoordinator<Type5>()
        
        navChildren2.last!.start(modal3, animated: false, { _ in
            navChildren2.last!.dismiss()
        })
        
        await awaitAnimsShort()
        
        // MARK: Initial Test
        
        expect(host.frames).to(haveCount(5))
        expect(root.modalChain) == [
            modal1.instantiatedVC!,
            navRoot1.instantiatedNavController!,
            modal2.instantiatedVC!,
            navRoot2.instantiatedNavController!,
            modal3.instantiatedVC!
        ]
        
        expect(navRoot1.instantiatedNavController!.viewControllers) == [
            navRoot1.instantiatedVC
        ] + navChildren1.map(\.instantiatedVC)
        
        expect(navRoot2.instantiatedNavController!.viewControllers) == [
            navRoot2.instantiatedVC
        ] + navChildren2.map(\.instantiatedVC)
        
        // MARK: First dismiss
        
        modal3.instantiatedVC!.dismiss(animated: true) // Simulate downswipe
        
        await awaitAnims()
        
        expect(host.frames).to(haveCount(4))
        expect(host.frames[3].navigationData).toNot(beNil())
        expect(host.frames[3].navigationData?.children).to(haveCount(0))
        expect(root.modalChain) == [
            modal1.instantiatedVC!,
            navRoot1.instantiatedNavController!,
            modal2.instantiatedVC!,
            navRoot2.instantiatedNavController!
        ]
        expect(navRoot2.instantiatedNavController!.viewControllers) == [ navRoot2.instantiatedVC ]
        
        // MARK: Teardown
        await root.dismissAndAwait()
    }
}
