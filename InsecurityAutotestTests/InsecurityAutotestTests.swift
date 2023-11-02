import XCTest
@testable import Insecurity
@testable import InsecurityAutotestHost
import Nimble


@MainActor
final class InsecurityAutotestTests: XCTestCase {
    let root = ViewController.shared

    func void<T>() -> (T) -> Void {
        return { _ in }
    }

    func testBasicMount() async {
        let root = self.root
        
        let insecurityHost = InsecurityHost()
        
        let child = TestModalCoordinator<Void>()
        
        insecurityHost.mountOnExistingController(child, on: root, animated: false, { _ in
            
        })
        
        expect(root.modalChain) == [child.instantiatedVC]
        
        await root.dismissAndAwait()
    }

    func testCoordinatorIsCompletelyUsableAfterStuffWasDismissedFromIt() {
        enum ChainRoot { }; enum ToReturnTo { };
        let root = self.root
        let insecurityHost = InsecurityHost()

        let chainRoot = Coord<ChainRoot>()
        insecurityHost.mountOnExistingController(chainRoot, on: root, animated: false, void())

        let exp = expectation(description: "should've been done at some point")
        let coordToReturnTo = Coord<ToReturnTo>()
        _ = chainRoot.startProm(coordToReturnTo)
            .flatMap { _ in
                let type1Coord = Coord(Type1.self)
                return coordToReturnTo.startProm(type1Coord)
                    .map { _ in type1Coord }
            }
            .flatMap { type1Coord in
                let type2Coord = Coord(Type2.self)

                return type1Coord.startProm(type2Coord)
                    .map { _ in Coords(type1Coord: type1Coord, type2Coord: type2Coord) }
            }
            .flatMap { coords in
                expect(root.modalChain) == [
                    chainRoot.instantiatedVC,
                    coordToReturnTo.instantiatedVC,
                    coords.type1Coord.instantiatedVC,
                    coords.type2Coord.instantiatedVC
                ]
                expect(insecurityHost.frames.count) == 4
                return coordToReturnTo.dismissChildrenProm()
            }
            .flatMap { _ in
                expect(root.modalChain) == [
                    chainRoot.instantiatedVC,
                    coordToReturnTo.instantiatedVC
                ]
                expect(insecurityHost.frames.count) == 2

                let type1Coord = Coord(Type1.self)
                let type2Coord = Coord(Type2.self)

                return coordToReturnTo.startProm(type1Coord)
                    .flatMap { _ in
                        type1Coord.startProm(type2Coord, completion: { _ in
                            type1Coord.finish(Type1())
                        })
                    }
                    .map { _ in Coords(type1Coord: type1Coord, type2Coord: type2Coord) }
            }
            .flatMap { args in
                expect(root.modalChain) == [
                    chainRoot.instantiatedVC,
                    coordToReturnTo.instantiatedVC,
                    args.type1Coord.instantiatedVC,
                    args.type2Coord.instantiatedVC
                ]
                expect(insecurityHost.frames.count) == 4
                return args.type2Coord.dismissProm()
            }
            .map { _ in
                expect(root.modalChain) == [
                    chainRoot.instantiatedVC,
                    coordToReturnTo.instantiatedVC
                ]
                expect(insecurityHost.frames.count) == 2
            }
            .flatMap { _ in
                root.dismissProm()
            }
            .map {
                exp.fulfill()
            }

        wait(for: [exp], timeout: 60)
    }
}

extension ModalCoordinator {
    func startProm<Result>(
        _ child: ModalCoordinator<Result>,
        animated: Bool = true,
        completion: @escaping (Result?) -> Void = { _ in }
    ) -> Prom<Void> {
        Prom { resolve in
            self.start(child, animated: animated, completion, presentationCompleted: {
                resolve(())
            })
        }
    }

    func dismissChildrenProm(
        animated: Bool = true
    ) -> Prom<Void> {
        Prom { res in
            self.dismissChildren(animated: animated, presentationCompleted: {
                res(())
            })
        }
    }

    func dismissProm(

    ) -> Prom<Void> {
        Prom { res in
            self.dismiss(presentationCompleted: {
                res(())
            })
        }
    }
}


struct Coords {
    let type1Coord: Coord<Type1>
    let type2Coord: Coord<Type2>
}
typealias Coord = TestModalCoordinator
