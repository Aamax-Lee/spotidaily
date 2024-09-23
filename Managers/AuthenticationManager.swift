//
//  AuthenticationManager.swift
//  musictime
//
//  Created by Aamax Lee on 21/4/2024.
//

import Foundation

//class responsible for managing user authentication
final class AuthManager {
    static let shared = AuthManager()
    
//    flag indicating whether the token is currently being refreshed
    private var refreshingToken = false
    
//    authentication constants (keep secret)
    struct Constants {
        static let clientID = ""
        static let clientSecret = ""
        static let tokenAPIURL = "https://accounts.spotify.com/api/token"
        static let redirectURI = "http://localhost:1410/"

    }
    
    private init() {}
    
//    URL for Spotify sign-in
    public var signInURL: URL? {
        let scopes = "user-read-private%20user-read-email%20user-top-read"
        let string = "https://accounts.spotify.com/authorize?response_type=code&client_id=\(Constants.clientID)&scope=\(scopes)&redirect_uri=\(Constants.redirectURI)&show_dialog=TRUE"
        
        return URL(string: string)
    }
//    Retrieves the access token from user defaults
    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }
    
//    Retrieves the refresh token from user defaults
    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    
//    Retrieves the token expiration date from user defaults
    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }
    
//    returns true if there is 5 minutes left before token expires
    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else {
            return false
        }
        let currentDate = Date()
        let fiveMins: TimeInterval = 300
        return currentDate.addingTimeInterval(fiveMins) >= expirationDate
    }
    
//    indicator to know if user is signed in (ie access token exists)
    var isSignedIn:Bool {
        return accessToken != nil
    }
    
//    exchanges the authorization code for an access token
    public func exchangeCodeForToken(code: String,  completion: @escaping ((Bool) -> Void)) {
        guard let url = URL(string: Constants.tokenAPIURL) else {
            return
        }
        
//        components to retrieve
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI)
        ]
        
//        request url to prepare
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        
//        use client id and secret to make a base64 string to be used to make a request for authorizatiob
        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            completion(false)
            return
        }
        
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        
//perform the token exchange request
        let task = URLSession.shared.dataTask(with: request) {
            [weak self] data, _, error in //underscore is response, weak self prevents memory leak
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            
            do {    //decode json response into authresponse object to be used
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.cacheToken(result: result)
//                print("SUCCESS HERE: \(json)")
                completion(true)
            }
            catch {
                print("authentication manager error: ", error.localizedDescription)
                completion(false)
            }
            
        }
        task.resume()
        
    }
    
//    array of refresh token completion blocks
    public var onRefreshBlocks = [((String) -> Void)]()
    
    
//    supplis the valid token to be used with api calls
    public func withValidToken(completion: @escaping (String) -> Void) {
        guard !refreshingToken else {
            onRefreshBlocks.append(completion)
            return
        }
        if shouldRefreshToken {
            refreshIfNeeded { [weak self] success in
                if success {
                    if let token = self?.accessToken, success {
                        completion(token)
                    }
                }
            }
        }
        else if let token = accessToken {
                completion(token)
            }
        }
    
     
//    checks if token should be refreshed, then refreshes if required
    public func refreshIfNeeded(completion: @escaping (Bool) -> Void){
        guard !refreshingToken else {
            return
        }
        
        guard shouldRefreshToken else {
            return
        }
        guard let refreshToken = self.refreshToken else {
            return
        }
        
        guard let url = URL(string: Constants.tokenAPIURL) else {
            return
        }
        
        refreshingToken = true
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
//            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        
//        new request url
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        
//        same token
        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("Base 64 failure here")
            completion(false)
            return
        }
        
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) {
            [weak self] data, _, error in //underscore is response, weak self prevents memory leak
            self?.refreshingToken = false
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.onRefreshBlocks.forEach { $0(result.access_token) }
                self?.onRefreshBlocks.removeAll()
                self?.cacheToken(result: result)
                completion(true)
            }
            catch {
                print(error.localizedDescription)
                completion(false)
            }
            
        }
        task.resume()
    }
    
//    caches the token in user defaults
    private func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.access_token, forKey: "access_token")
        
        if let refresh_token = result.refresh_token {
            UserDefaults.standard.setValue(refresh_token, forKey: "refresh_token")
        }
        
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)), forKey: "expirationDate")
    }
    
    
    
}
