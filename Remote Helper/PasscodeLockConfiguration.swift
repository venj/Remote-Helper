//
//  PasscodeLockConfiguration.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/29/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation
import PasscodeLock

struct PasscodeLockConfiguration: PasscodeLockConfigurationType {
    var isBiometricAuthAllowed: Bool = true
    var shouldRequestBiometricAuthImmediately: Bool = true
    var biometricAuthReason: String? = NSLocalizedString("Remote Helper needs your finger print to protect your content.", comment: "Remote Helper needs your finger print to protect your content.")
    let repository: PasscodeRepositoryType
    let passcodeLength = 4
    let maximumInccorectPasscodeAttempts = -1
    
    init(repository: PasscodeRepositoryType) {
        self.repository = repository
    }
    
    init() {
        self.repository = UserDefaultsPasscodeRepository()
    }
}
