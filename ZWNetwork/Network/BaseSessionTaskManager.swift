//
//  BaseSessionTaskManager.swift
//  ZWNetwork
//
//  Created by zhangzhenwei on 2019/9/4.
//  Copyright © 2019 玮大爷的创作. All rights reserved.
//

import UIKit
import Alamofire
import DeviceKit

class BaseSessionTaskManager {

    static let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 15
        return SessionManager(configuration: configuration)
    }()

    static var defaultHTTPHeaders: HTTPHeaders {
        let userAgent: String = {
            if let info = Bundle.main.infoDictionary {
                let appName = "app name"
                let appVersion = info["CFBundleShortVersionString"] as? String ?? ""
                let appBuildVersion = info["CFBundleVersion"] as? String ?? ""
                let platform = Device.current.description as String
                let systemName = UIDevice.current.systemName as String
                let systemVersion = UIDevice.current.systemVersion
                let locale = UserDefaults.standard.string(forKey: "AppleLocale") ?? ""
                let deviceIdentifier = Device.identifier
                let market = "S1"
                return "\(appName)/\(appVersion) ios/\(appBuildVersion) (\(platform); \(systemName) \(systemVersion); \(locale); \(deviceIdentifier); \(market))"
            }
            return ""
        }()
        var headers = SessionManager.defaultHTTPHeaders
        headers["User-Agent"] = userAgent
        //        if islogin == true {
        headers["Cookie"] = "SESSIONID=xxxxxx"
        //        }
        // Todo: 外部URL不要传SessionID
        return headers
    }
    
}


