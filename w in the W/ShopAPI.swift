//
//  ShopAPI.swift
//  w in the W
//
//  Created by don't touch me on 3/23/17.
//  Copyright © 2017 trvl, LLC. All rights reserved.
//

import Foundation


enum ShopResult {
    case Success([Shop])
    case Failure(Error)
}

enum ShopError: Error {
    case InvalidJSON
}

class ShopAPI {
    
    var imageURL: String?
    var price: String?
    
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    func fetchShops(completion: @escaping ([Shop]) -> Void) {
        
        var shops = [Shop]()
        
        let url = URL(string: "https://b3bf9e612052301245f0ab57a34b168f:eda3cb1ef8d8ac3846ff893cbd9b731a@itseverywhere.myshopify.com/admin/products.json?limit=250")
        let request = URLRequest(url: url!)
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) in
            
            guard error == nil else {
                print("error getting products from shopifyAPI")
                print(error?.localizedDescription)
                return
            }
            
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // Parse the JSON result
            do {
                guard let shopsJSON = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject], let shop = shopsJSON["shops"] as? [[String: AnyObject]] else {
                    print("Error trying to convert data to JSON")
                    return
                }
                
                shops = shop.flatMap { json in
                    
                    guard let id = json["id"] as? NSNumber,
                        let title = json["title"] as? String,
                        let productType = json["vendor"] as? String,
                        let imagesArray = json ["images"] as? [[String: AnyObject]],
                        let variantsArray = json["variants"] as? [[String: AnyObject]],
                        let tags = json["tags"] as? String else {
                        print("Error: could not turn map into json")
                        return nil
                    }
                    // print(tags)
            
                    let _ = imagesArray.flatMap{ image in
                        guard let imageSRC = image["src"] as? String else {
                            print("unable to get src for image")
                            return
                        }
                        self.getImageURL(imageSRC: imageSRC)

                    }
                    let _ = variantsArray.flatMap { variant in
                        guard let price = variant["price"] as? String else {
                            print("unable to get price from variant array")
                            return
                        }
                        self.setPrice(price: price)
                    }
                    
                    guard let image = self.imageURL, let price = self.price else {
                        print("error with imageURL or price")
                        return nil
                    }
                    
                    let s = Shop(id: id, title: title, productType: productType, image: image, price: price, tags: tags)
                    return s
                }
                completion(shops)
        
            } catch {
                print("Error trying to convert data to JSON")
                return
            }
            // print(shops)
        })
        task.resume()
        return
    }
    
    private func setPrice(price: String) {
        self.price = price
    }
    
    private func getImageURL(imageSRC: String) {
        self.imageURL = imageSRC
    }
}


