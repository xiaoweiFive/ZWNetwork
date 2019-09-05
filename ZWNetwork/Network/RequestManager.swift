//
//  RequestManager.swift
//  ZWNetwork
//
//  Created by zhangzhenwei on 2019/9/4.
//  Copyright © 2019 玮大爷的创作. All rights reserved.
//

import UIKit
import Alamofire


class RequestManager {
    static let `default` = RequestManager()
    private var requestTasks = [String: RequestTaskManager]()
    
    func request(
        _ url: String,
        method: HTTPMethod = .get,
        params: Parameters? = nil,
        cacheFilters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)
        -> RequestTaskManager
    {
        let key = cacheKey(url, params, cacheFilters)
        var taskManager : RequestTaskManager?
        if requestTasks[key] == nil {
            taskManager = RequestTaskManager()
            requestTasks[key] = taskManager
        } else {
            taskManager = requestTasks[key]
        }
        
        taskManager?.completionClosure = {
            self.requestTasks.removeValue(forKey: key)
        }
        
        taskManager?.request(url, method: method, params: params, cacheKey: key, encoding: encoding, headers: headers)
        return taskManager!
    }
    
    func request(
        urlRequest: URLRequestConvertible,
        params: Parameters,
        cacheFilters: Parameters? = nil)
        -> RequestTaskManager? {
            if let urlStr = urlRequest.urlRequest?.url?.absoluteString {
                let components = urlStr.components(separatedBy: "?")
                if components.count > 0 {
                    let key = cacheKey(components.first!, params, cacheFilters)
                    var taskManager : RequestTaskManager?
                    if requestTasks[key] == nil {
                        taskManager = RequestTaskManager()
                        requestTasks[key] = taskManager
                    } else {
                        taskManager = requestTasks[key]
                    }
                    
                    taskManager?.completionClosure = {
                        self.requestTasks.removeValue(forKey: key)
                    }
                    taskManager?.request(urlRequest: urlRequest, cacheKey: key)
                    return taskManager!
                }
                return nil
            }
            return nil
    }
    
    
    /// 取消请求
    func cancel(_ url: String, params: Parameters? = nil, cacheFilters: Parameters? = nil) {
        let key = cacheKey(url, params, cacheFilters)
        let taskManager = requestTasks[key]
        taskManager?.dataRequest?.cancel()
    }
    
    /// 清除所有缓存
    func removeAllCache(completion: @escaping (Bool)->()) {
        CacheManager.default.removeAllCache(completion: completion)
    }
    
    /// 根据key值清除缓存
    func removeObjectCache(_ url: String, params: [String: Any]? = nil, cacheFilters: Parameters? = nil,  completion: @escaping (Bool)->()) {
        let key = cacheKey(url, params, cacheFilters)
        CacheManager.default.removeObjectCache(key, completion: completion)
    }
}

// MARK: - 请求任务
class RequestTaskManager: BaseSessionTaskManager {
    fileprivate var dataRequest: DataRequest?
    fileprivate var cache: Bool = false
    fileprivate var cacheKey: String!
    fileprivate var completionClosure: (()->())?
    
    @discardableResult
    fileprivate func request(
        _ url: String,
        method: HTTPMethod = .get,
        params: Parameters? = nil,
        cacheKey: String,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = defaultHTTPHeaders)
        -> RequestTaskManager
    {
        self.cacheKey = cacheKey
        dataRequest = BaseSessionTaskManager.sessionManager.request(url, method: method, parameters: params, encoding: encoding, headers: headers)
        return self
    }
    
    
    /// request
    ///
    /// - Parameters:
    ///   - urlRequest: urlRequest
    ///   - cacheKey: cacheKey
    /// - Returns: RequestTaskManager
    @discardableResult
    fileprivate func request(
        urlRequest: URLRequestConvertible,
        cacheKey: String)
        -> RequestTaskManager {
            self.cacheKey = cacheKey
            dataRequest = BaseSessionTaskManager.sessionManager.request(urlRequest)
            return self
    }
    
    /// 是否缓存数据
    public func cache(_ cache: Bool) -> RequestTaskManager {
        self.cache = cache
        return self
    }
    /// 获取缓存Data
    @discardableResult
    public func cacheData(completion: @escaping (ResponseValue<Data>)->()) -> ZWNetworkDataResponse {
        let dataResponse = ZWNetworkDataResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        return dataResponse.cacheData(completion: completion)
    }
    /// 响应Data
    public func responseData(completion: @escaping (ResponseValue<Data>)->()) {
        let dataResponse = ZWNetworkDataResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        dataResponse.responseData(completion: completion)
    }
    /// 先获取Data缓存，再响应Data
    public func responseCacheAndData(completion: @escaping (ResponseValue<Data>)->()) {
        let dataResponse = ZWNetworkDataResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        dataResponse.responseCacheAndData(completion: completion)
    }
    /// 获取缓存String
    @discardableResult
    public func cacheString(completion: @escaping (String)->()) -> ZWNetworkStringResponse {
        let stringResponse = ZWNetworkStringResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        return stringResponse.cacheString(completion:completion)
    }
    /// 响应String
    public func responseString(completion: @escaping (ResponseValue<String>)->()) {
        let stringResponse = ZWNetworkStringResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        stringResponse.responseString(completion: completion)
    }
    /// 先获取缓存String,再响应String
    public func responseCacheAndString(completion: @escaping (ResponseValue<String>)->()) {
        let stringResponse = ZWNetworkStringResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        stringResponse.responseCacheAndString(completion: completion)
    }
    /// 获取缓存JSON
    @discardableResult
    public func cacheJson(completion: @escaping (Any)->()) -> ZWNetworkJsonResponse {
        let jsonResponse = ZWNetworkJsonResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        return jsonResponse.cacheJson(completion:completion)
    }
    /// 响应JSON
    public func responseJson(completion: @escaping (ResponseValue<Any>)->()) {
        let jsonResponse = ZWNetworkJsonResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        jsonResponse.responseJson(completion: completion)
    }
    /// 先获取缓存JSON，再响应JSON
    public func responseCacheAndJson(completion: @escaping (ResponseValue<Any>)->()) {
        let jsonResponse = ZWNetworkJsonResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        jsonResponse.responseCacheAndJson(completion: completion)
    }
}
// MARK: - ZWNetworkBaseResponse
public class ZWNetworkResponse {
    fileprivate var dataRequest: DataRequest
    fileprivate var cache: Bool
    fileprivate var cacheKey: String
    fileprivate var completionClosure: (()->())?
    fileprivate init(dataRequest: DataRequest, cache: Bool, cacheKey: String, completionClosure: (()->())?) {
        self.dataRequest = dataRequest
        self.cache = cache
        self.cacheKey = cacheKey
        self.completionClosure = completionClosure
    }
    ///
    fileprivate func response<T>(response: DataResponse<T>, completion: @escaping (ResponseValue<T>)->()) {
        responseCache(response: response) { (result) in
            completion(result)
        }
    }
    /// isCacheData
    fileprivate func responseCache<T>(response: DataResponse<T>, completion: @escaping (ResponseValue<T>)->()) {
        if completionClosure != nil { completionClosure!() }
        let result = ResponseValue(isCacheData: false, result: response.result, response: response.response)
        if Network.openResultLog {
            debugPrint("================请求数据=====================")
        }
        if Network.openUrlLog {
            debugPrint(response.request?.url?.absoluteString ?? "")
        }
        switch response.result {
        case .success(_):
            if Network.openResultLog {
                if let data = response.data,
                    let str = String(data: data, encoding: .utf8) {
                    debugPrint(str)
                }
            }
            if self.cache {/// 写入缓存
                var model = CacheModel()
                model.data = response.data
                CacheManager.default.setObject(model, forKey: self.cacheKey)
            }
        case .failure(let error):
            if Network.openResultLog {
                debugPrint(error.localizedDescription)
            }
        }
        completion(result)
    }
}
// MARK: - ZWNetworkJsonResponse
public class ZWNetworkJsonResponse: ZWNetworkResponse {
    /// 响应JSON
    func responseJson(completion: @escaping (ResponseValue<Any>)->()) {
        dataRequest.responseJSON(completionHandler: { response in
            self.response(response: response, completion: completion)
        })
    }
    fileprivate func responseCacheAndJson(completion: @escaping (ResponseValue<Any>)->()) {
        if cache { cacheJson(completion: { (json) in
            let res = ResponseValue(isCacheData: true, result: Alamofire.Result.success(json), response: nil)
            completion(res)
        }) }
        dataRequest.responseJSON { (response) in
            self.responseCache(response: response, completion: completion)
        }
    }
    /// 获取缓存json
    @discardableResult
    fileprivate func cacheJson(completion: @escaping (Any)->()) -> ZWNetworkJsonResponse {
        if let data = CacheManager.default.objectSync(forKey: cacheKey)?.data,
            let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            if Network.openResultLog {
                debugPrint("=================缓存=====================")
                if let str = String(data: data, encoding: .utf8) {
                    debugPrint(str)
                }
            }
            completion(json)
        } else {
            if Network.openResultLog {
                debugPrint("读取缓存失败")
            }
        }
        return self
    }
}
// MARK: - ZWNetworkStringResponse
public class ZWNetworkStringResponse: ZWNetworkResponse {
    /// 响应String
    func responseString(completion: @escaping (ResponseValue<String>)->()) {
        dataRequest.responseString(completionHandler: { response in
            self.response(response: response, completion: completion)
        })
    }
    @discardableResult
    fileprivate func cacheString(completion: @escaping (String)->()) -> ZWNetworkStringResponse {
        if let data = CacheManager.default.objectSync(forKey: cacheKey)?.data,
            let str = String(data: data, encoding: .utf8) {
            completion(str)
        } else {
            if Network.openResultLog {
                debugPrint("读取缓存失败")
            }
        }
        return self
    }
    fileprivate func responseCacheAndString(completion: @escaping (ResponseValue<String>)->()) {
        if cache { cacheString(completion: { str in
            let res = ResponseValue(isCacheData: true, result: Alamofire.Result.success(str), response: nil)
            completion(res)
        })}
        dataRequest.responseString { (response) in
            self.responseCache(response: response, completion: completion)
        }
    }
}
// MARK: - ZWNetworkDataResponse
public class ZWNetworkDataResponse: ZWNetworkResponse {
    /// 响应Data
    func responseData(completion: @escaping (ResponseValue<Data>)->()) {
        dataRequest.responseData(completionHandler: { response in
            self.response(response: response, completion: completion)
        })
    }
    @discardableResult
    fileprivate func cacheData(completion: @escaping (ResponseValue<Data>)->()) -> ZWNetworkDataResponse {
        if let data = CacheManager.default.objectSync(forKey: cacheKey)?.data {
            let res = ResponseValue(isCacheData: true, result: Alamofire.Result.success(data), response: nil)
            completion(res)
        } else {
            if Network.openResultLog {
                debugPrint("读取缓存失败")
            }
        }
        return self
    }
    fileprivate func responseCacheAndData(completion: @escaping (ResponseValue<Data>)->()) {
        if cache { cacheData(completion: { (response) in
            completion(response)
        }) }
        dataRequest.responseData { (response) in
            self.responseCache(response: response, completion: completion)
        }
    }
}

