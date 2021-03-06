//
//  NetworkService.swift
//  GithubList
//
//  Created by Vladislav on 26.04.2022.
//

import Foundation
import Moya
import PromiseKit


protocol NetworkServiceProtocol {
    func getAllUser(since: Int) -> Promise<MainUsersNetworkModel>
    func getSingleUser(userName: String) -> Promise<UserDetailNetworkModel>
}

class NetworkService: NetworkServiceProtocol {
    
    lazy private var gitHubProvider = MoyaProvider<GitHub>(plugins: [NetworkLoggerPlugin(configuration: .init(formatter: .init(responseData: JSONResponseDataFormatter), logOptions: .verbose))])
        
    func getAllUser(since: Int) -> Promise<MainUsersNetworkModel> {
        
        return Promise { seal in
            gitHubProvider.request(.allUser(since, 50)) { result in
                switch result {
                case .success(let response):
                    if let responseModel = try? response.map(MainUsersNetworkModel.self) {
                        seal.fulfill(responseModel)
                    }
                    
                    if let responseModel = try? response.map(GitAlertNetworkModel.self) {
                        seal.reject(GitError.somethingIsWrong(info: responseModel.message ?? ""))
                    }
                    
                case .failure(let error):
                    print(error.errorDescription ?? "Unknown error")
                    seal.reject(error)
                }
            }
        }
    }
    
    func getSingleUser(userName: String) -> Promise<UserDetailNetworkModel> {
        return Promise { seal in
            gitHubProvider.request(.userDetail(userName)) { result in
                switch result {
                case .success(let response):
                    if let responseModel = try? response.map(UserDetailNetworkModel.self) {
                        seal.fulfill(responseModel)
                    }
                case .failure(let error):
                    print(error.errorDescription ?? "Unknown error")
                    seal.reject(error)
                }
            }
        }
    }
    
    
    private func JSONResponseDataFormatter(_ data: Data) -> String {
        do {
            let dataAsJSON = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
            return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
        } catch {
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
    
}
