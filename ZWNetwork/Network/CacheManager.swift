//
//  CacheManager.swift
//  ZWNetwork
//
//  Created by zhangzhenwei on 2019/9/4.
//  Copyright © 2019 玮大爷的创作. All rights reserved.
//

import Foundation
import Cache

public enum ZWNetworkExpiry {
    /// Object will be expired in the nearest future
    case never
    /// Object will be expired in the specified amount of seconds
    case seconds(TimeInterval)
    /// Object will be expired on the specified date
    case date(Date)
    
    /// Returns the appropriate date object
    public var expiry: Expiry {
        switch self {
        case .never:
            return Expiry.never
        case .seconds(let seconds):
            return Expiry.seconds(seconds)
        case .date(let date):
            return Expiry.date(date)
        }
    }
    public var isExpired: Bool {
        return expiry.isExpired
    }
}

struct CacheModel: Codable {
    var data: Data?
    var dataDict: Dictionary<String, Data>?
    init() { }
}

class CacheManager: NSObject {
    static let `default` = CacheManager()
    /// Manage storage
    private var storage: Storage<CacheModel>?
    /// init
    override init() {
        super.init()
        expiryConfiguration()
    }
    var expiry: ZWNetworkExpiry = .never
    
    func expiryConfiguration(expiry: ZWNetworkExpiry = .never) {
        self.expiry = expiry
        let diskConfig = DiskConfig(
            name: "ZWNetworkCache",
            expiry: expiry.expiry
        )
        let memoryConfig = MemoryConfig(expiry: expiry.expiry)
        do {
            storage = try Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: CacheModel.self))
        } catch {
            debugPrint(error)
        }
    }
    
    /// 清除所有缓存
    ///
    /// - Parameter completion: completion
    func removeAllCache(completion: @escaping (_ isSuccess: Bool)->()) {
        storage?.async.removeAll(completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .value: completion(true)
                case .error: completion(false)
                }
            }
        })
    }
    
    /// 根据key值清除缓存
    ///
    /// - Parameters:
    ///   - cacheKey: cacheKey
    ///   - completion: completion
    func removeObjectCache(_ cacheKey: String, completion: @escaping (_ isSuccess: Bool)->()) {
        storage?.async.removeObject(forKey: cacheKey, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .value: completion(true)
                case .error: completion(false)
                }
            }
        })
    }
    
    /// 读取缓存
    ///
    /// - Parameter key: key
    /// - Returns: model
    func objectSync(forKey key: String) -> CacheModel? {
        do {
            ///过期清除缓存
            if let isExpire = try storage?.isExpiredObject(forKey: key), isExpire {
                removeObjectCache(key) { (_) in }
                return nil
            } else {
                return (try storage?.object(forKey: key)) ?? nil
            }
        } catch {
            return nil
        }
    }
    
    /// 异步缓存
    ///
    /// - Parameters:
    ///   - object: model
    ///   - key: key
    func setObject(_ object: CacheModel, forKey key: String) {
        storage?.async.setObject(object, forKey: key, expiry: nil, completion: { (result) in
            switch result {
            case .value(_):
                debugPrint("缓存成功")
            case .error(let error):
                debugPrint("缓存失败: \(error)")
            }
        })
    }
}


public func debugPrint(_ item: @autoclosure () -> Any) {
    #if DEBUG
    NSLog("[😇Debug] \(item())")
    #endif
}
