//
//  AuthService.swift
//  InsecurityDemo
//
//  Created by a.vaysberg on 10/1/21.
//

import Foundation

struct Creds {
    let token: String
}

protocol IAuthService: AnyObject {
    var onLogout: (() -> Void)? { get set }
    
    var hasCreds: Bool { get }
    
    func logout()
    
    func saveCreds(_ creds: Creds)
    
    func getCreds() -> Creds?
}

class AuthService: IAuthService {
    var creds: Creds?
    
    var onLogout: (() -> Void)?
    
    func logout() {
        creds = nil
        onLogout?()
    }
    
    func saveCreds(_ creds: Creds) {
        self.creds = creds
    }
    
    var hasCreds: Bool {
        creds != nil
    }
    
    func getCreds() -> Creds? {
        return creds
    }
}
