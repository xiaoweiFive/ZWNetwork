//
//  api.swift
//  ZWNetwork
//
//  Created by zhangzhenwei on 2019/9/4.
//  Copyright © 2019 玮大爷的创作. All rights reserved.
//

import Foundation

extension Network {
    enum Api: String {
        case test                     = "/v1/test"
        
        
        #if DEBUG
        static let domain = "www.baidu.com"
        #elseif INHOUSE
        static let domain = "www.baidu.com"
        #else
        static let domain = "www.baidu.com"
        #endif
    
        var url: String {
            let url = "https://\(Api.domain)\(rawValue)"
//            url.append("?userID=xxxxx")
            return url
        }

        
    }
}
