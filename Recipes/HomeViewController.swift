//
//  HomeViewController.swift
//  Recipes
//
//  Created by Santiago Sanchez merino on 11/07/2019.
//  Copyright © 2019 Santiago Sanchez Merino. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    let cellId = "RecipeCell"
    let searchController = UISearchController(searchResultsController: nil)
    var model = Response(dict: [:])

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = 60
     
        let cell = UINib(nibName: cellId, bundle: nil)
        self.tableView.register(cell, forCellReuseIdentifier: cellId)
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Escribe una palabra"
        navigationItem.searchController = searchController
        definesPresentationContext = true        
        
    }

}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) 
        
        cell.textLabel?.text = model.results[indexPath.row].title
        cell.detailTextLabel?.text = model.results[indexPath.row].href
        cell.imageView?.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        cell.imageView?.sizeThatFits(CGSize(width: 50, height: 50))
        cell.imageView?.sizeToFit()

        retrieveThumbnail(urlString: model.results[indexPath.row].thumbnail) { thumb in
            DispatchQueue.main.async {
                cell.imageView?.image = thumb
                
                // Importante para refrescar la imagen
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
            }
        }
        return cell

    }
    
}

extension HomeViewController: UITableViewDelegate {
    
}

extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if !searchController.searchBar.text!.isEmpty && searchController.searchBar.text != nil {
            self.retrieveRecipes(name: searchController.searchBar.text!) { response in
                DispatchQueue.main.async {
                    self.model = response
                    self.tableView.reloadData()
                }
            }
        }
    }
}


extension HomeViewController {
    func retrieveRecipes(name: String, completion: @escaping (Response) -> ()) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        if let url = URL(string: "http://www.recipepuppy.com/api/?q=\(name)") {
            let task = session.dataTask(with: url) { data, response, error in
                if let data = data {
                    let dict = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let recipes = Response(dict: dict!)
                    completion(recipes)
                }
            }
            task.resume()
        }
    }
    
    func retrieveThumbnail(urlString: String, completion: @escaping (UIImage) -> ()) {
        if urlString == "" {
            completion(UIImage())
        } else {
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let url = URL(string: urlString)
            let task = session.dataTask(with: url!) { data, response, error in
                if let data = data {
                    let thumb = UIImage(data: data) ?? UIImage()
                    completion(thumb)
                }
            }
            task.resume()
            
        }
    }
    
}


struct Response {
    var title: String!
    var version: Double!
    var href: String!
    var results: [Result]
    
    init(dict: [String: Any]) {
        title = dict["title"] as? String
        version = dict["version"] as? Double
        href = dict["href"] as? String
        results = [Result]()
        if let tempResults = dict["results"] as? [[String: Any]] {
            for result in tempResults {
                let value = Result(title: result["title"] as? String,
                    href: result["href"] as? String,
                    ingredients: result["ingredients"] as? String,
                    thumbnail: result["thumbnail"] as? String,
                    thumbnailImage: nil)
                results.append(value)
            }
        }
        
    }
}

struct Result {
    var title: String!
    var href: String!
    var ingredients: String!
    var thumbnail: String!
    var thumbnailImage: UIImage?
}
