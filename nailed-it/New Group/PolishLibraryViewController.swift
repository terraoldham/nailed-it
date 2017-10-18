//
//  PolishLibraryViewController.swift
//  nailed-it
//
//  Created by Lia Zadoyan on 10/10/17.
//  Copyright © 2017 Lia Zadoyan. All rights reserved.
//

import UIKit
import Parse
import SafariServices
import CZPicker

@objc protocol PolishLibraryViewControllerDelegate {
    @objc optional func polishColor(with polishColor: PolishColor?)
}

class PolishLibraryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIActionSheetDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var colors: [PolishColor]?
    var brands = [String]()
    weak var delegate: PolishLibraryViewControllerDelegate?
    weak var hamburgerDelegate: HamburgerDelegate?

    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        brands = ["Essie", "My Color", "Butter London"]
        self.title = "CZPicker"
            
        let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
        
    }
    
    @IBAction func onFilter(_ sender: Any) {
        let picker = CZPickerView(headerTitle: "Brands", cancelButtonTitle: "Cancel", confirmButtonTitle: "Confirm")
        picker?.delegate = self
        picker?.dataSource = self
        picker?.needFooterView = false
        picker?.allowMultipleSelection = true
        picker?.show()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let query = PFQuery(className:"PolishColor")
        query.order(byDescending: "createdAt")
        query.findObjectsInBackground {
            (colors: [PFObject]?, error: Error?) -> Void in
            
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(colors!.count) scores.")
                print(colors!)
                // Do something with the found objects
                if let colors = colors {
                    self.colors = colors as? [PolishColor]
                    self.collectionView.reloadData()
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.localizedDescription)")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.colors?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PolishCollectionViewCell", for: indexPath) as! PolishCollectionViewCell
        cell.polishColor = colors?[indexPath.row]
       
        return cell;
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = colors?[indexPath.row]
        if let delegate = delegate {
            delegate.polishColor!(with: color)
            dismiss(animated: true, completion: nil)
        } else {
            let actionSheetController = UIAlertController(title: "\(color!.displayName!) by \(color!.brand!)", message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                // Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            let sharePolishColor = UIAlertAction(title: "Share Polish Color", style: .default) { action -> Void in
                self.showShareOptions(polishColor: color!)
            }
            actionSheetController.addAction(sharePolishColor)
            
            // Create and add a second option action
            let tryItOnAction = UIAlertAction(title: "Try It On", style: .default) { action -> Void in
                //TODO ONCE SAVING MASK IS DONE
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                let tryItOnViewController = storyboard.instantiateViewController(withIdentifier: "TryItOnViewController") as! TryItOnViewController
//                tryItOnViewController.colorBlahBlah = color
//                self.show(tryItOnViewController, sender: self)
            }
            actionSheetController.addAction(tryItOnAction)
            
            if color!.brand! != "My Color" {
                let findThisColor = UIAlertAction(title: "Find \(color!.displayName!) Online", style: .default) { action -> Void in
                    self.prepareForPolishSearch(color: color)
                }
                actionSheetController.addAction(findThisColor)

            }
            // We need to provide a popover sourceView when using it on iPad
            actionSheetController.popoverPresentationController?.sourceView = self.view as UIView
            
            // Present the AlertController
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    func prepareForPolishSearch(color: PolishColor!) {
        let allowedCharacterSet = (CharacterSet(charactersIn: " ").inverted)
        let escapedBrand = color!.brand!.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
        let escapedName = color!.displayName!.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
        let searchString = "https://www.amazon.com/s/ref=nb_sb_noss?url=search-alias%3Daps&field-keywords=" + escapedName! + "+" + escapedBrand!
        print(searchString)
        UIApplication.shared.open(URL(string: searchString)!, options: [:], completionHandler: nil)
    }
    
    func showShareOptions(polishColor: PolishColor) {
        let image = UIImageView()
        image.image = UIImage.from(color: polishColor.getUIColor())
    
        let imageToShare = [image.image!, "Check out this nail polish color by \(polishColor.brand!). It's called \(polishColor.displayName!).", "\nShared via Nailed It"] as [Any]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func onHamburgerPressed(_ sender: Any) {
        hamburgerDelegate?.hamburgerPressed()
    }
}

extension UIImage {
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

extension PolishLibraryViewController: CZPickerViewDelegate, CZPickerViewDataSource {
    func numberOfRows(in pickerView: CZPickerView!) -> Int {
        return self.brands.count
    }
    
    func numberOfRowsInPickerView(pickerView: CZPickerView!) -> Int {
        return self.brands.count
    }
    
    func czpickerView(_ pickerView: CZPickerView!, titleForRow row: Int) -> String! {
        print(brands)
        return self.brands[row]
    }
    
    func czpickerView(_ pickerView: CZPickerView!, didConfirmWithItemAtRow row: Int){
        print(brands[row])
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func czpickerViewDidClickCancelButton(_ pickerView: CZPickerView!) {
        print("Blah")
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func czpickerView(_ pickerView: CZPickerView!, didConfirmWithItemsAtRows rows: [AnyObject]!) {
        print("hello")
        for row in rows {
            if let row = row as? Int {
                print(self.brands[row])
            }
        }
    }
}
