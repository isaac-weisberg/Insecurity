//
//  DI.swift
//  InsecurityDemo
//
//  Created by a.vaysberg on 10/1/21.
//

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
