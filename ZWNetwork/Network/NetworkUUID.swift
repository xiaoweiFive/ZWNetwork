//
//  NetworkUUID.swift
//  ZWNetwork
//
//  Created by zhangzhenwei on 2019/9/5.
//  Copyright © 2019 玮大爷的创作. All rights reserved.
//

import Foundation

public func makeUUID() -> String {
    return NSUUID().uuidString
}

public func makeShortUUID() -> String {
    return String(makeUUID().suffix(8))
}



