//
//  ShopViewController.swift
//  w in the W
//
//  Created by don't touch me on 3/23/17.
//  Copyright © 2017 trvl, LLC. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ShopViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var searchedProducts: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let manager = CLLocationManager()
    var shops: ShopAPI!
    var shopData = [Shop]()
    var filteredShops = [Shop]()
    var userZipcode: String = ""
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        shops.fetchShops() { (shops) -> Void in
            self.shopData = shops
            print(self.shopData)
            
            OperationQueue.main.addOperation { //addOperation
                
                if self.userZipcode != "" {
                    self.reloadShopsFrom(zipcode: self.userZipcode)
                } else {
                    self.collectionView.reloadData()
                }
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        collectionView.prefetchDataSource = self
        self.searchedProducts.delegate = self
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 128, height: 42))
        imageView.contentMode = .scaleAspectFit
        
        let image = UIImage(named: "wW1")
        imageView.image = image
        
        navigationItem.titleView = imageView
        
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if searchedProducts.text != "" {
            return self.filteredShops.count
        }
        
        if filteredShops.count > 0 {
            print(filteredShops)
            return self.filteredShops.count
        }
        
        print(self.shopData.count)
        return self.shopData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShopCell", for: indexPath) as! ShopCollectionViewCell
        
        let shop: Shop
        
        if searchedProducts.text != "" {
            shop = filteredShops[indexPath.row]
        } else if filteredShops.count > 0 {
            shop = filteredShops[indexPath.row]
        } else {
            shop = shopData[indexPath.row]
        }
        
        cell.imageView?.imageFromServer(urlString: shop.image)
        cell.name.text = shop.title
        cell.price.text = shop.price
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ShopCollectionViewCell else {
            return
        }
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            cell.imageView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { (finished) in
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                cell.imageView?.transform = CGAffineTransform.identity
            }, completion: { [weak self] finished in
                self?.performSegue(withIdentifier: "detailViewSegue", sender: self)
            })
        }

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let selectedIndex = collectionView.indexPathsForSelectedItems?.first {
            
            var photo: Shop
            
            if filteredShops.count > 0 {
                photo = filteredShops[selectedIndex.row]
                
            } else {
                photo = shopData[selectedIndex.row]
            }
            
            let destinationVC = segue.destination as! ShopDetailViewController
            print(photo.image)
            destinationVC.shopImageURL = photo.image
        }
    }
    
    func reloadShopsFrom(zipcode: String) {
        print("Reload Shops")
        print(zipcode)
        if shopData.isEmpty {
            return
        }
        filteredShops = self.shopData.filter({ (s) -> Bool in
            return s.tags.lowercased().range(of: zipcode.lowercased()) != nil
        })
        
        self.collectionView.reloadData()
    }
    
}

extension UIImageView {
    public func imageFromServer(urlString: String) {
        
        URLSession.shared.dataTask(with: URL(string: urlString)!) {
            (data, response, error) in
            
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                let image = UIImage(data: data!)
                self.image = image
                
            })
        }.resume()
    }
}

extension ShopViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
         filteredShops = self.shopData.filter({ (s) -> Bool in
              return s.tags.lowercased().range(of: searchText.lowercased()) != nil
        })
        self.collectionView.reloadData()
    }
}

extension ShopViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
    }
}

extension ShopViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.first
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        let userLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location!.coordinate.latitude, location!.coordinate.longitude)
        
        let region: MKCoordinateRegion = MKCoordinateRegionMake(userLocation, span)
        
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error) -> Void in
            
            if (error != nil) {
                print(error?.localizedDescription)
            }
            
            if (placemarks?.count)! > 0 {
                let pm = (placemarks?[0])! as CLPlacemark
                if let zipcode = pm.postalCode {
                    manager.stopUpdatingLocation()
                    self.userZipcode = zipcode
                }
            }
        })
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
