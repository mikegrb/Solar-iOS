//
//  ViewController.swift
//  Solar
//
//  Created by Michael Greb on 10/9/17.
//  Copyright © 2017 Michael Greb. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageDay: UIImageView!
    @IBOutlet weak var imageMonth: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelLoaded: UILabel!
    @IBOutlet weak var labelSummary: UILabel!
    @IBOutlet weak var labelNet: UILabel!
    
    var dateLoadTime: Date?
    let dateFormatter = DateFormatter()
    let timeFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .medium
        loadData()
    }

    func loadData() {
        dateLoadTime = Date()
        let timestamp = String(format:"%.0f", (dateLoadTime?.timeIntervalSince1970)!)

        jsonFromURL(urlString: "https://solar.thegrebs.com/json") { (json) in
            let latestDate = json["date"].stringValue
            self.jsonFromURL(urlString: "https://solar.thegrebs.com/day/" + latestDate + ".json") { (json) in

                self.labelTitle.text = json["date_str"].stringValue
                self.labelSummary.text = """
                    Today, generated \(json["tot_solar"].stringValue), used \(json["tot_used"].stringValue).
                """
                self.labelSummary.isHidden = false
                
                let netUsed = json["tot_used"].double! - json["tot_solar"].double!
                self.labelNet.text = String(format: "%.2f", netUsed) + " kWh"
                switch netUsed < 0 {
                case true:
                    self.labelNet.textColor = UIColor.green
                case false:
                    self.labelNet.textColor = UIColor.black
                }
                self.labelNet.isHidden = false

                self.labelLoaded.text = "Refreshed at " + self.timeFormatter.string(from: self.dateLoadTime!)
                self.labelLoaded.isHidden = false
            }
            
            let yearMonth = latestDate[..<latestDate.index(latestDate.startIndex, offsetBy: 7)]
            self.imageDay.imageFromUrl(urlString: "https://solar.thegrebs.com/graphs/" + latestDate + "?" + timestamp) {}
            self.imageMonth.imageFromUrl(urlString: "https://solar.thegrebs.com/graphs/" + yearMonth + "?" + timestamp) {}
        }
    }
    
    @IBAction func buttonRefresh(_ sender: Any) {
        loadData()
    }
    
    private func jsonFromURL(urlString: String, whenDone: @escaping (JSON)-> Void) {
        URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
            if let data = data {
                DispatchQueue.main.async {
                    let json = JSON(data)
                    whenDone(json)
                }
            }
        }.resume()
    }
}

extension UIImageView {
    public func imageFromUrl(urlString: String, whenDone: @escaping () -> Void) {
        URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
            DispatchQueue.main.async {
                self.image = UIImage(data: data!)
                whenDone()
            }
        }.resume()
    }
}
