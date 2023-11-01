import Foundation

final class Prom<Val> {
    enum State {
        case inProgress([(Val) -> Void])
        case fulfilled(Val)
    }

    private let lock = NSLock()
    private var state: State

    init(value: Val) {
        self.state = .fulfilled(value)
    }

    init(_ process: (@escaping (Val) -> Void) -> Void) {
        self.state = .inProgress([])
        process { [self] val in
            lock.transact {
                switch state {
                case .inProgress(let handlers):
                    self.state = .fulfilled(val)
                    handlers.forEach { handler in
                        handler(val)
                    }
                case .fulfilled:
                    fatalError()
                }
            }
        }
    }

    func map<NewVal>(_ predicate: @escaping (Val) -> NewVal) -> Prom<NewVal> {
        return lock.transact {
            switch state {
            case .fulfilled(let val):
                return Prom<NewVal>(value: predicate(val))
            case .inProgress(let handlers):
                return Prom<NewVal> { resolve in
                    var newHandlers = handlers
                    newHandlers.append { val in
                        resolve(predicate(val))
                    }
                    self.state = .inProgress(newHandlers)
                }
            }
        }
    }

    func flatMap<NewVal>(_ predicate: @escaping (Val) -> Prom<NewVal>) -> Prom<NewVal> {
        return lock.transact {
            switch state {
            case .fulfilled(let val):
                return predicate(val)
            case .inProgress(let handlers):
                return Prom<NewVal> { resolve in
                    var newHandlers = handlers
                    newHandlers.append { val in
                        _ = predicate(val)
                            .map { newVal in
                                resolve(newVal)
                            }
                    }
                    self.state = .inProgress(newHandlers)
                }
            }
        }
    }
}

extension NSLock {
    func transact<R>(_ tx: () -> R) -> R {
        self.lock()

        let value = tx()
        self.unlock()

        return value
    }
}
