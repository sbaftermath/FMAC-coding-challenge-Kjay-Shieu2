//
//  ViewController.swift
//  AWSRekognitionKjayShieu
//
//  Created by admin on 3/31/20.
//  Copyright © 2020 revature. All rights reserved.
//

import UIKit
import AWSRekognition

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var rekognitionObject:AWSRekognition?
    
    @IBOutlet weak var sourceImage: UIImageView!
    
    @IBOutlet weak var secondImage: UIImageView!
    
    @IBOutlet weak var similarityScoreLabel: UILabel!
    
    var imagePicked = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let Image1:Data = sourceImage.image!.jpegData(compressionQuality: 0.2)!
        let Image2:Data = secondImage.image!.jpegData(compressionQuality: 0.2)!
        sendImageToRekognition(Image1Data: Image1, Image2Data: Image2)
    }
    
    func sourceOfPhotos(sourceType: UIImagePickerController.SourceType){
        if UIImagePickerController.isSourceTypeAvailable(sourceType){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self;
            myPickerController.sourceType = sourceType
            self.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    @IBAction func CameraOpen(_ sender: Any) {
        let currentSelectedBtn = (sender as! UIButton)
        if(currentSelectedBtn.currentTitle == "Take Source Image"){
            imagePicked = 1
        } else if (currentSelectedBtn.currentTitle == "Take Target Image"){
            imagePicked = 2
        }
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .camera
        pickerController.cameraCaptureMode = .photo
        present(pickerController, animated: true)
    }
    
    @IBAction func PhotoLibraryOpen(_ sender: Any) {
        let currentSelectedBtn = (sender as! UIButton)
        if(currentSelectedBtn.currentTitle == "Choose Source Image"){
            imagePicked = 1
        } else if (currentSelectedBtn.currentTitle == "Choose Target Image"){
            imagePicked = 2
        }
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .savedPhotosAlbum
        present(pickerController, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("couldn't load image from Photos")
        }
        
        if imagePicked == 1 {
            sourceImage.image = image
        }else if imagePicked == 2{
            secondImage.image = image
        }
        
        let Image1:Data = sourceImage.image!.jpegData(compressionQuality: 0.2)!
        let Image2:Data = secondImage.image!.jpegData(compressionQuality: 0.2)!
        
        //Function call to send the image to Rekognition
        sendImageToRekognition(Image1Data: Image1, Image2Data: Image2)
    }
    
    
    //MARK: - AWS Methods
    func sendImageToRekognition(Image1Data: Data, Image2Data: Data){
        
        //Delete older labels or buttons
        rekognitionObject = AWSRekognition.default()
        let Image1AWS = AWSRekognitionImage()
        Image1AWS?.bytes = Image1Data
        let Image2AWS = AWSRekognitionImage()
        Image2AWS?.bytes = Image2Data
        let faceRequest = AWSRekognitionCompareFacesRequest()
        faceRequest?.sourceImage = Image1AWS
        faceRequest?.targetImage = Image2AWS
        
        rekognitionObject?.compareFaces(faceRequest!){
            (result, error) in
            if error != nil{
                print(error!)
                return
            }
            if result != nil {
                print(result!)
                //1. First we check if there are any celebrities in the response
                if ((result!.faceMatches!.count) > 0){
                    
                    //2. Celebrities were found. Lets iterate through all of them
                    for (index, faceImage) in result!.faceMatches!.enumerated(){
                        
                        //Check the confidence value returned by the API for each celebirty identified
                        if(faceImage.similarity!.intValue > 10){ //Adjust the confidence value to whatever you are comfortable with
                            DispatchQueue.main.async {
                                [weak self] in
                                self!.similarityScoreLabel.text = "Similarity Score: \(faceImage.similarity!.uintValue)%"
                                
                            }  
                        }
                        
                    }
                }
                    //If there were no celebrities in the image, lets check if there were any faces (who, granted, could one day become celebrities)
                else if ((result!.unmatchedFaces!.count) > 0){
                    //Faces are present. Point them out in the Image (left as an exercise for the reader)
                    DispatchQueue.main.async {
                        [weak self] in
                        self!.similarityScoreLabel.text = "Faces are not similar"
                        
                    }
                }
                else{
                    //No faces were found (presumably no people were found either)
                    print("No faces in this pic")
                }
            }
            else{
                print("No Result")
            }
        }
        
        DispatchQueue.main.async {
            [weak self] in
            for subView in (self?.sourceImage.subviews)! {
                subView.removeFromSuperview()
            }
        }
        
    }
    
}

