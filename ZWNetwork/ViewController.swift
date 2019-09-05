//
//  ViewController.swift
//  ZWNetwork
//
//  Created by zhangzhenwei on 2019/9/3.
//  Copyright © 2019 玮大爷的创作. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //示例一 data
        Network.request("===").cache(true).cacheData(completion: { [weak self] (responseVale) in
            guard let strongSelf = self else { return }
            strongSelf.deserializeData(responseVale: responseVale)
        }).responseData { [weak self] (responseVale) in
            guard let strongSelf = self else { return }
            strongSelf.deserializeData(responseVale: responseVale)
        }
        
        //示例二 data
        Network.request("===", params: nil, cacheFilters: nil).cache(true).responseCacheAndData { [weak self] (responseData) in
            guard let strongSelf = self else { return }
            strongSelf.deserializeData(responseVale: responseData)
        }

        //示例三 str
        Network.request("===", params: nil, cacheFilters: nil).cache(true).responseString { [weak self] (responseStr) in
            guard let strongSelf = self else { return }
            strongSelf.deserializeData(responseVale: responseStr)
        }
        
        //示例四 json
        Network.request("===").responseJson { [weak self] (responseJson) in
            guard let strongSelf = self else { return }
            strongSelf.deserializeData(responseVale: responseJson)
        }
        
        //下载 data
        Network.download("===").downloadProgress { (precent) in
            debugPrint("====download 进度===\(precent)")
            }.responseData { [weak self] (responseData) in
                guard let strongSelf = self else { return }
                strongSelf.deserializeData(responseVale: responseData)
        }
        
        if let uploadImg = UIImage.init(named: "==") {
            let payload = Network.Payload.init(content: Network.Content.jpeg(uploadImg, 1.0), name: "files[]", mimeType: .jpeg)
            Network.upload(payload, url: "url").uploadProgress { (precent) in
                debugPrint("====upload 进度===\(precent)")
                }.responseData { [weak self] (responseData) in
                    guard let strongSelf = self else { return }
                    strongSelf.deserializeData(responseVale: responseData)
            }
        }
        
        
        
    }
    
    
    func deserializeData<T>(responseVale: ResponseValue<T>)  {

        let isCache = responseVale.isCacheData
        debugPrint("===isCache = \(isCache)")
        
        let response = responseVale.deserialize(type: Map.self)
        if let error = response.error {
            debugPrint(" ====== cache response error=\(error.localizedDescription)")
        } else {
            if let data = response.data,
                let model =  CustomModel.deserialize(from: data)  {
                debugPrint("===model=== \n name = \(model.name ?? ""), age = \(model.age ?? 0)")
            }
        }
    }

}


import HandyJSON
class CustomModel: HandyJSON {
    var name: String?
    var sex: Int?
    var age: Int?
    
    required init() {}

}


