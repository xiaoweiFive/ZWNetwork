//
//  ResponseValue.swift
//  ZWNetwork
//
//  Created by zhangzhenwei on 2019/9/4.
//  Copyright © 2019 玮大爷的创作. All rights reserved.
//

import Alamofire

//// MARK: - Result
public struct ResponseValue<Value> {
    
    public let isCacheData: Bool
    public let result: Result<Value>
    public let response: HTTPURLResponse?
    
    init(isCacheData: Bool, result: Result<Value>, response: HTTPURLResponse?) {
        self.isCacheData = isCacheData
        self.result = result
        self.response = response
    }
}


typealias Map = [String: Any]
typealias List = [Any]

struct ApiResponse<T>: CustomStringConvertible, CustomDebugStringConvertible {
    let error: Error?
    let timesec: TimeInterval?
    let data: T?
    var description: String {
        if let error = error {
            return error.localizedDescription
        } else {
            if let map = data as? [String: Any] {
                return map.description
            } else if let list = data as? [Any] {
                return list.description
            } else {
                return "Succeed but response data is \(data == nil ? "nil" : "unknown type"). Perhaps it is correctly response or it is your incorrectly request deserialize type"
            }
        }
    }
    var debugDescription: String {
        return description
    }
}


extension ResponseValue {
    func deserialize<T>(type: T.Type)-> ApiResponse<T> {
        
        func deserialize()-> (json: [String: Any]?, error: Error?) {
            guard result.isSuccess else {
                return (nil, result.error)
            }
            if let data = result.value as? Data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let json = json as? [String: Any] {
                        return (json, nil)
                    } else {
                        return (nil, NetworkError.dataDeserializeMapFailed)
                    }
                } catch {
                    return (nil, error)
                }
            } else if let jsonString = result.value as? String {
                if let data = jsonString.data(using: .utf8) {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        if let json = json as? [String: Any] {
                            return (json, nil)
                        } else {
                            return (nil, NetworkError.dataDeserializeMapFailed)
                        }
                    } catch {
                        return (nil, error)
                    }
                } else {
                    return (nil, NetworkError.stringEncodingFailed)
                }
            } else if let json = result.value as? [String: Any] {
                return (json, nil)
            } else {
                return (nil, NetworkError.invalidFormat)
            }
        }
        
        let deserializeResult = deserialize()
        guard let json = deserializeResult.json else {
            return ApiResponse(error: deserializeResult.error, timesec: nil, data: nil)
        }
        
        if let ec = json["ec"] as? Int {
            let timesec = json["timesec"] as? TimeInterval
            if ec == 0 {
                return ApiResponse(error: nil, timesec: timesec, data: json["data"] as? T)
            } else {
                let error = NSError(domain: Network.Api.domain, code: ec, userInfo: [NSLocalizedDescriptionKey: json["em"] as? String ?? "unknown error"])
                return ApiResponse(error: error, timesec: timesec, data: nil)
            }
        } else {
            return ApiResponse(error: NetworkError.invalidFormat, timesec: nil, data: nil)
        }
    }
}

enum NetworkError: LocalizedError {
    case `default`
    case dataDeserializeMapFailed
    case stringEncodingFailed
    case invalidFormat
    var errorDescription: String? {
        switch self {
        case .default:
            return "数据异常"
        case .dataDeserializeMapFailed:
            return "解析异常"
        case .stringEncodingFailed:
            return "编码异常"
        case .invalidFormat:
            return "format error"
        }
    }
}
