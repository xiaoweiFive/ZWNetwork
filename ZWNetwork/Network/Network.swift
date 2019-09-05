//
//  Network.swift
//  ZWNetwork
//
//  Created by zhangzhenwei on 2019/9/4.
//  Copyright © 2019 玮大爷的创作. All rights reserved.
//

import UIKit
import Alamofire
import Cache

class Network: NSObject {
    
    // MARK: - 网络请求
    
    /// 开启/关闭请求url log
    public static var openUrlLog: Bool = true
    /// 开启/关闭结果log
    public static var openResultLog: Bool = true
    
    /// 网络请求
    ///
    /// - Parameters:
    ///   - url: url
    ///   - method: .get .post ...
    ///   - params: 参数字典
    ///   - cacheFilters: 变化的参数，例如 时间戳-token 等
    ///   - encoding: 编码方式
    ///   - headers: 请求头
    /// - Returns:
    @discardableResult
    public static func request(
        _ url: String,
        method: HTTPMethod = .get,
        params: Parameters? = nil,
        cacheFilters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)
        -> RequestTaskManager
    {
        return RequestManager.default.request(url, method: method, params: params, cacheFilters: cacheFilters, encoding: encoding, headers: headers)
    }
    
    /// urlRequest请求
    ///
    /// - Parameters:
    ///   - urlRequest: 自定义URLRequest
    ///   - params: URLRequest中需要的参数，作为key区分缓存
    ///   - cacheFilters: 变化的参数，例如 时间戳, `token` 等, 用来过滤`params`中的动态参数
    /// - Returns: RequestTaskManager?
    @discardableResult
    public static func request(
        urlRequest: URLRequestConvertible,
        params: Parameters,
        cacheFilters: Parameters? = nil)
        -> RequestTaskManager?
    {
        return RequestManager.default.request(urlRequest: urlRequest, params: params, cacheFilters: cacheFilters)
    }
    
    /// 取消请求
    ///
    /// - Parameters:
    ///   - url: url
    ///   - params: 参数
    ///   - cacheFilters: 变化的参数，例如 时间戳-token 等
    public static func cancel(_ url: String, params: Parameters? = nil, cacheFilters: Parameters? = nil) {
        RequestManager.default.cancel(url, params: params, cacheFilters: cacheFilters)
    }
    
    /// 清除所有缓存
    ///
    /// - Parameter completion: 完成回调
    public static func removeAllCache(completion: @escaping (Bool)->()) {
        RequestManager.default.removeAllCache(completion: completion)
    }
    
    /// 根据url和params清除缓存
    ///
    /// - Parameters:
    ///   - url: url
    ///   - params: 参数
    ///   - cacheFilters: 变化的参数，例如 时间戳-token 等
    ///   - completion: 完成回调
    public static func removeObjectCache(_ url: String, params: [String: Any]? = nil, cacheFilters: Parameters? = nil, completion: @escaping (Bool)->()) {
        RequestManager.default.removeObjectCache(url, params: params,cacheFilters: cacheFilters, completion: completion)
    }
    
    // MARK: - 下载
    
    /// 文件下载
    ///
    /// - Parameters:
    ///   - url: url
    ///   - method: .get .post ... 默认.get
    ///   - parameters: 参数
    ///   - cacheFilters: 变化的参数，例如 时间戳-token 等
    ///   - encoding: 编码方式
    ///   - headers: 请求头
    ///   - fileName: 自定义文件名，需要带文件扩展名
    /// - Returns: DownloadTaskManager
    public static func download(
        _ url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        cacheFilters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        fileName: String? = nil)
        ->DownloadTaskManager
    {
        return DownloadManager.default.download(url, method: method, parameters: parameters, cacheFilters: cacheFilters, encoding: encoding, headers: headers, fileName: fileName)
    }
    
    /// 取消下载
    ///
    /// - Parameter url: url
    public static func downloadCancel(_ url: String, parameters: Parameters? = nil, cacheFilters: Parameters? = nil) {
        DownloadManager.default.cancel(url, parameters: parameters, cacheFilters: cacheFilters)
    }
    
    /// Cancel all download tasks
    public static func downloadCancelAll() {
        DownloadManager.default.cancelAll();
    }
    
    /// 下载百分比
    ///
    /// - Parameter url: url
    /// - Returns: percent
    public static func downloadPercent(_ url: String, parameters: Parameters? = nil, cacheFilters: Parameters? = nil) -> Double {
        return DownloadManager.default.downloadPercent(url, parameters: parameters, cacheFilters: cacheFilters)
    }
    
    /// 删除某个下载
    ///
    /// - Parameters:
    ///   - url: url
    ///   - completion: download success/failure
    public static func downloadDelete(_ url: String, parameters: Parameters? = nil,cacheFilters: Parameters? = nil, completion: @escaping (Bool)->()) {
        DownloadManager.default.delete(url,parameters: parameters,cacheFilters: cacheFilters, completion: completion)
    }
    
    /// 下载状态
    ///
    /// - Parameter url: url
    /// - Returns: status
    public static func downloadStatus(_ url: String, parameters: Parameters? = nil,cacheFilters: Parameters? = nil) -> DownloadStatus {
        return DownloadManager.default.downloadStatus(url, parameters: parameters,cacheFilters: cacheFilters)
    }
    
    /// 下载完成后，文件所在位置
    ///
    /// - Parameter url: url
    /// - Returns: file URL
    public static func downloadFilePath(_ url: String, parameters: Parameters? = nil,cacheFilters: Parameters? = nil) -> URL? {
        return DownloadManager.default.downloadFilePath(url, parameters: parameters,cacheFilters: cacheFilters)
    }
    
    /// 下载中的进度,任务下载中时，退出当前页面,再次进入时继续下载
    ///
    /// - Parameters:
    ///   - url: url
    ///   - progress: 进度
    /// - Returns: taskManager
    @discardableResult
    public static func downloadProgress(_ url: String, parameters: Parameters? = nil,cacheFilters: Parameters? = nil, progress: @escaping ((Double)->())) -> DownloadTaskManager? {
        return DownloadManager.default.downloadProgress(url, parameters: parameters,cacheFilters: cacheFilters, progress: progress)
    }

    
    // MARK: - 上传
    
    /// 文件上传
    ///
    /// - Parameters:
    ///   - payloads: Payload 文件类型 自构造
    ///   - url: url
    ///   - method: .post
    ///   - parameters: 参数
    ///   - cacheFilters: 变化的参数，例如 时间戳-token 等
    ///   - encoding: 编码方式
    ///   - headers: 请求头
    /// - Returns: DownloadTaskManager
    @discardableResult
    public static func upload(_ payloads: Payload...,
        url: String,
        parameters: Parameters? = nil,
        cacheFilters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil) -> UploadTaskManager
    {
       return UploadManager.default.upload(payloads, url: url, parameters: parameters)
    }
    
    /// 取消上传
    ///
    /// - Parameter url: url
    public static func uploadCancel(_ url: String, parameters: Parameters? = nil, cacheFilters: Parameters? = nil) {
        UploadManager.default.cancel(url, parameters: parameters, cacheFilters: cacheFilters)
    }
    
    /// Cancel all upload tasks
    public static func uploadCancelAll() {
        UploadManager.default.cancelAll();
    }
    
    /// 上传百分比
    ///
    /// - Parameter url: url
    /// - Returns: percent
    public static func uploadPercent(_ url: String, parameters: Parameters? = nil, cacheFilters: Parameters? = nil) -> Double {
        return UploadManager.default.uploadPercent(url, parameters: parameters, cacheFilters: cacheFilters)
    }
    
    /// 删除某个上传
    ///
    /// - Parameters:
    ///   - url: url
    ///   - completion: upload success/failure
    public static func uploadDelete(_ url: String, parameters: Parameters? = nil,cacheFilters: Parameters? = nil, completion: @escaping (Bool)->()) {
        UploadManager.default.delete(url,parameters: parameters,cacheFilters: cacheFilters, completion: completion)
    }
    
    /// 上传状态
    ///
    /// - Parameter url: url
    /// - Returns: status
    public static func uploadStatus(_ url: String, parameters: Parameters? = nil,cacheFilters: Parameters? = nil) -> UploadStatus {
        return UploadManager.default.uploadStatus(url, parameters: parameters,cacheFilters: cacheFilters)
    }
    
    /// 上传中的进度,任务上传中时，退出当前页面,再次进入时继续上传
    ///
    /// - Parameters:
    ///   - url: url
    ///   - progress: 进度
    /// - Returns: taskManager
    @discardableResult
    public static func uploadProgress(_ url: String, parameters: Parameters? = nil,cacheFilters: Parameters? = nil, progress: @escaping ((Double)->())) -> UploadTaskManager? {
        return UploadManager.default.uploadProgress(url, parameters: parameters,cacheFilters: cacheFilters, progress: progress)
    }
    
}



extension Network{

    struct Payload {
        let content: Content
        let name: String
        let fileName: String
        let mimeType: MimeType
        
        init(content: Content, name: String, fileName: String = makeShortUUID(), mimeType: MimeType) {
            self.content = content
            self.name = name
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }
    
    enum Content {
        case inputStream(InputStream, UInt64)
        case fileURL(URL)
        case data(Data)
        case jpeg(UIImage, CGFloat)
        case png(UIImage)
    }
    
    enum MimeType: String {
        case jpeg   = "image/jpeg"
        case png    = "image/png"
        case gif    = "image/gif"
        case mp4    = "video/mp4"
        case mp3    = "audio/mpeg"
    }
}

public func makeUUID() -> String {
    return NSUUID().uuidString
}

public func makeShortUUID() -> String {
    return String(makeUUID().suffix(8))
}

