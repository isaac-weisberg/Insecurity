import Foundation

protocol HasAuthService {
    var authService: IAuthService { get }
}

typealias HasAllServices = HasAuthService

class DIContainer: HasAllServices {
    let authService: IAuthService
    
    init() {
        authService = AuthService()
    }
}
