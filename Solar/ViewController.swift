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
    @IBOutlet weak var labelNet: UILabel! // label displaying value
    @IBOutlet weak var buttonRefresh: UIButton!
    
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
        labelTitle.text = "Loading..."
        labelLoaded.isHidden = true
        labelSummary.isHidden = true
        labelNet.isHidden = true
        imageDay.isHidden = true
        imageMonth.isHidden = true
        buttonRefresh.isEnabled = false

        dateLoadTime = Date()
        let timestamp = String(format:"%.0f", (dateLoadTime?.timeIntervalSince1970)!)

        jsonFromURL(urlString: "https://solar.thegrebs.com/json") { (json) in
            let latestDate = json["date"].stringValue
            self.jsonFromURL(urlString: "https://solar.thegrebs.com/day/" + latestDate + ".json") { (json) in

                self.labelTitle.text = json["date_str"].stringValue
                self.labelSummary.text =
                      "\tGenerated: " + String(format:"%.3f", json["tot_solar"].floatValue ) + " kWh\n"
                    + "\tConsumed: " + String(format:"%.3f", json["tot_used"].floatValue) + "kWh\n"
                    + "\tNet:"
                

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

                self.buttonRefresh.isEnabled = true
                self.setupTimer()
            }
            
            let yearMonth = latestDate[..<latestDate.index(latestDate.startIndex, offsetBy: 7)]
            self.imageDay.imageFromUrl(urlString: "https://solar.thegrebs.com/graphs/" + latestDate + "?" + timestamp) {
                self.imageDay.isHidden = false
            }
            self.imageMonth.imageFromUrl(urlString: "https://solar.thegrebs.com/graphs/" + yearMonth + "?" + timestamp) {
                self.imageMonth.isHidden = false
            }
        }
    }
    
    @IBAction func buttonRefresh(_ sender: Any) {
        loadData()
    }
    
    private func setupTimer() {
        let calendar = Calendar.current
        let nextUpdate = calendar.nextDate(after: Date(), matching: DateComponents(calendar: calendar, minute:6), matchingPolicy: .nextTime)
        let timer = Timer(fire: nextUpdate!, interval: 0, repeats: false, block: ( {(timer) in
            self.loadData()
        }))
        timer.tolerance = 30
        RunLoop.main.add(timer, forMode: .commonModes)
    }
    
    private func jsonFromURL(urlString: String, whenDone: @escaping (JSON)-> Void) {
        URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
            if let data = data {
                DispatchQueue.main.async {
                    let json = JSON(data)
                    whenDone(json)
                }
            }
            else {
                DispatchQueue.main.async {
                    self.buttonRefresh.isEnabled = true
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
