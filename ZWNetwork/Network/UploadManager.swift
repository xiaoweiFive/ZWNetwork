//
//  UploadManager.swift
//  ZWNetwork
//
//  Created by zhangzhenwei on 2019/9/5.
//  Copyright © 2019 玮大爷的创作. All rights reserved.
//

import UIKit
import Foundation
import Alamofire

class UploadManager {
    
    
    static let `default` = UploadManager()
    /// 下载任务管理
    fileprivate var uploadTasks = [String: UploadTaskManager]()
    
    func upload(_ payloads: [Network.Payload],
                url: String,
                parameters: Parameters? = nil,
                cacheFilters: Parameters? = nil,
                encoding: ParameterEncoding = URLEncoding.default,
                headers: HTTPHeaders? = nil) -> UploadTaskManager
    {
        
        let key = cacheKey(url, parameters, cacheFilters)
        let taskManager = UploadTaskManager(url, parameters: parameters, cacheFilters: cacheFilters)
        var tempParam = parameters==nil ? [:] : parameters!
        let dynamicTempParam = cacheFilters==nil ? [:] : cacheFilters!
        dynamicTempParam.forEach { (arg) in
            tempParam[arg.key] = arg.value
        }
        
        var innerPayloads = [Network.Payload]()
        for payload in payloads {
            switch payload.content {
            case .inputStream(let inputStream, let length):
                innerPayloads.append(Network.Payload(content: .inputStream(inputStream, length), name: payload.name, fileName: payload.fileName, mimeType: payload.mimeType))
            case .fileURL(let url):
                innerPayloads.append(Network.Payload(content: .fileURL(url), name: payload.name, fileName: payload.fileName, mimeType: payload.mimeType))
            case .data(let data):
                innerPayloads.append(Network.Payload(content: .data(data), name: payload.name, fileName: payload.fileName, mimeType: payload.mimeType))
            case .jpeg(let image, let compressionQuality):
                innerPayloads.append(Network.Payload(content: .jpeg(image, compressionQuality), name: payload.name, fileName: payload.fileName, mimeType: payload.mimeType))
            case .png(let image):
                innerPayloads.append(Network.Payload(content: .png(image), name: payload.name, fileName: payload.fileName, mimeType: payload.mimeType))
            }
        }
        
        taskManager.upload(innerPayloads, url: url, method: .post, params: parameters, cacheKey: key, encoding: encoding, headers: headers)

        self.uploadTasks[key] = taskManager
        taskManager.cancelCompletion = {
            self.uploadTasks.removeValue(forKey: key)
        }
       return taskManager
    }
    
    /// 暂停下载
    func cancel(_ url: String, parameters: Parameters?, cacheFilters: Parameters? = nil) {
        let key = cacheKey(url, parameters, cacheFilters)
        let task = uploadTasks[key]
        task?.uploadRequest?.cancel()
        NotificationCenter.default.post(name: NSNotification.Name("ZWNetworkUploadCancel"), object: nil)
    }
    
    // Cancel all tasks
    func cancelAll() {
        for (key, task) in uploadTasks {
            task.uploadRequest?.cancel()
            task.cancelCompletion = {
                self.uploadTasks.removeValue(forKey: key)
            }
        }
    }
    
    /// 删除单个下载
    func delete(_ url: String, parameters: Parameters? , cacheFilters: Parameters? = nil, completion: @escaping (Bool)->()) {
        let key = cacheKey(url, parameters, cacheFilters)
        if let task = uploadTasks[key] {
            task.uploadRequest?.cancel()
            task.cancelCompletion = {
                self.uploadTasks.removeValue(forKey: key)
                CacheManager.default.removeObjectCache(key, completion: completion)
            }
        } else {
            CacheManager.default.removeObjectCache(key, completion: completion)
        }
    }
 
    /// 下载百分比
    func uploadPercent(_ url: String, parameters: Parameters?, cacheFilters: Parameters? = nil) -> Double {
        let key = cacheKey(url, parameters, cacheFilters)
        let percent = getProgress(key)
        return percent
    }
    /// 下载状态
    func uploadStatus(_ url: String, parameters: Parameters?, cacheFilters: Parameters? = nil) -> UploadStatus {
        let key = cacheKey(url, parameters, cacheFilters)
        let task = uploadTasks[key]
        if uploadPercent(url, parameters: parameters) == 1 { return .complete }
        return task?.uploadStatus ?? .suspend
    }
    /// 下载进度
    @discardableResult
    func uploadProgress(_ url: String, parameters: Parameters?, cacheFilters: Parameters? = nil, progress: @escaping ((Double)->())) -> UploadTaskManager? {
        let key = cacheKey(url, parameters, cacheFilters)
        if let task = uploadTasks[key], uploadPercent(url, parameters: parameters) < 1 {
            task.uploadProgress(progress: { pro in
                progress(pro)
            })
            return task
        } else {
            let pro = uploadPercent(url, parameters: parameters)
            progress(pro)
            return nil
        }
    }
}



// MARK: - 下载状态
public enum UploadStatus {
    case uploading
    case suspend
    case complete
}

class UploadTaskManager: BaseSessionTaskManager {
    
    fileprivate var uploadRequest: UploadRequest?
    fileprivate var uploadStatus: UploadStatus = .suspend
    fileprivate var cancelCompletion: (()->())?
    fileprivate var completionClosure: (()->())?
    var cacheDictionary = [String: Data]()
    private var key: String
    var manager = BaseSessionTaskManager.sessionManager

    init(_ url: String,
         parameters: Parameters? = nil,
         cacheFilters: Parameters? = nil) {
        key = cacheKey(url, parameters, cacheFilters)
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(uploadCancel), name: NSNotification.Name.init("ZWNetworkUploadCancel"), object: nil)
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { (_) in
            self.uploadRequest?.cancel()
        }
    }
    
    @objc fileprivate func uploadCancel() {
        self.uploadStatus = .suspend
    }
    
    @discardableResult
    fileprivate func upload(
        _ payloads: [Network.Payload],
        url: String,
        method: HTTPMethod = .get,
        params: Parameters? = nil,
        cacheKey: String,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = defaultHTTPHeaders)
        -> UploadTaskManager
    {
        self.key = cacheKey
        uploadStatus = .uploading

        manager.upload(multipartFormData: { multipartFormData in
            for payload in payloads {
                switch payload.content {
                case .inputStream(let stream, let length):
                    multipartFormData.append(stream, withLength: length, name: payload.name, fileName: payload.fileName, mimeType: payload.mimeType.rawValue)
                case .fileURL(let url):
                    multipartFormData.append(url, withName: payload.name, fileName: payload.fileName, mimeType: payload.mimeType.rawValue)
                case .data(let data):
                    multipartFormData.append(data, withName: payload.name, fileName: payload.fileName, mimeType: payload.mimeType.rawValue)
                case .jpeg(let image, let compressionQuality):
                    if let data = image.jpegData(compressionQuality: compressionQuality) {
                        multipartFormData.append(data, withName: payload.name, fileName: payload.fileName, mimeType: payload.mimeType.rawValue)
                    } else {
                        assertionFailure()
                    }
                case .png(let image):
                    if let data = image.pngData() {
                        multipartFormData.append(data, withName: payload.name, fileName: payload.fileName, mimeType: payload.mimeType.rawValue)
                    } else {
                        assertionFailure()
                    }
                }
            }
            if let parameters = params {
                for (key, value) in parameters {
                    guard let data = "\(value)".data(using: .utf8) else {
                        assertionFailure()
                        continue
                    }
                    multipartFormData.append(data, withName: key)
                }
            }
        }, to: url, method: method, headers: headers) { (encodingResult) in
            switch encodingResult {
            case .success(let request, _, _):
                self.uploadRequest = request
                debugPrint("======encodingResult==success")
            case .failure(let error):
                debugPrint("======encodingResult==\(error.localizedDescription)")
            }
        }
        return self
    }
    
    /// 下载进度
    @discardableResult
    public func uploadProgress(progress: @escaping ((Double) -> Void)) -> UploadTaskManager {
        uploadRequest?.uploadProgress(closure: { (pro) in
            self.saveProgress(pro.fractionCompleted)
            progress(pro.fractionCompleted)
        })
        return self
    }
    
    /// 响应
    public func responseData(completion: @escaping (ResponseValue<Data>)->()) {
        uploadRequest?.responseData(completionHandler: { (response) in
            switch response.result {
            case .success:
                self.uploadStatus = .complete
                if self.cancelCompletion != nil { self.cancelCompletion!() }
            case .failure(_):
                self.uploadStatus = .suspend
                self.saveResumeData(response.data)
                if self.cancelCompletion != nil { self.cancelCompletion!() }
            }
            let result = ResponseValue(isCacheData: false, result: response.result, response: response.response)
            completion(result)
        })
    }

    
    func saveProgress(_ progress: Double) {
        if let progressData = "\(progress)".data(using: .utf8) {
            cacheDictionary["progress"] = progressData
            var model = CacheModel()
            model.dataDict = cacheDictionary
            CacheManager.default.setObject(model, forKey: key)
        }
    }
    
    func saveResumeData(_ data: Data?) {
        cacheDictionary["resumeData"] = data
        var model = CacheModel()
        model.dataDict = cacheDictionary
        CacheManager.default.setObject(model, forKey: key)
    }
    
    func saveFilePath(_ filePath: String?) {
        if let filePathData = filePath?.data(using: .utf8) {
            cacheDictionary["filePath"] = filePathData
            var model = CacheModel()
            model.dataDict = cacheDictionary
            CacheManager.default.setObject(model, forKey: key)
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    

}
