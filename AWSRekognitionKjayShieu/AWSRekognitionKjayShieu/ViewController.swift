//
//  ViewController.swift
//  AWSRekognitionKjayShieu
//
//  Created by admin on 3/31/20.
//  Copyright © 2020 revature. All rights reserved.
//

import UIKit
import AWSRekognition
import os.log

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var rekognitionObject:AWSRekognition?
    
    @IBOutlet weak var sourceImage: UIImageView!
    
    @IBOutlet weak var secondImage: UIImageView!
    
    @IBOutlet weak var similarityScoreLabel: UILabel!
    
    var imagePicked = 0
    
    //overrided to convert default images to jpeg and send to AWS
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let Image1:Data = sourceImage.image!.jpegData(compressionQuality: 0.2)!
        let Image2:Data = secondImage.image!.jpegData(compressionQuality: 0.2)!
        sendImageToRekognition(Image1Data: Image1, Image2Data: Image2)
    }
        
    //function to open up camera and to change the image of the corresponding image view
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
    
    //functino to open photo lobrary and to chang the image of the corresponding image view
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
    
    //image picker controller that will update the images and send to AWS
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
    
    
    //Function that will call the AWS compare faces API
    func sendImageToRekognition(Image1Data: Data, Image2Data: Data){
        
        //formats the data recieved and creates a AWS Rekognition request for compare faces
        rekognitionObject = AWSRekognition.default()
        let Image1AWS = AWSRekognitionImage()
        Image1AWS?.bytes = Image1Data
        let Image2AWS = AWSRekognitionImage()
        Image2AWS?.bytes = Image2Data
        let faceRequest = AWSRekognitionCompareFacesRequest()
        faceRequest?.sourceImage = Image1AWS
        faceRequest?.targetImage = Image2AWS
        
        //checks to see if the resposnse contains a result and handles errors
        rekognitionObject?.compareFaces(faceRequest!){
            (result, error) in
            if error != nil{
                os_log("Error has occured")
                return
            }
            if result != nil {
                print(result!)
                //checks if there are any similar faces in the response
                if ((result!.faceMatches!.count) > 0){
                    
                    //iterates through the matched faces
                    for (index, faceImage) in result!.faceMatches!.enumerated(){
                        
                        //Check the similarity value returned by the API for each matched face
                        if(faceImage.similarity!.intValue > 10){
                            
                            //Displays the similarity to UI
                            DispatchQueue.main.async {
                                [weak self] in
                                self!.similarityScoreLabel.text = "Similarity Score: \(faceImage.similarity!.uintValue)%"
                                
                            }  
                        }
                        
                    }
                }
                    //if the faces are unmatched display message to UI
                else if ((result!.unmatchedFaces!.count) > 0){
                    
                    DispatchQueue.main.async {
                        [weak self] in
                        self!.similarityScoreLabel.text = "Faces are not similar"
                        
                    }
                }
                else{
                    //No faces were found (presumably no people were found either)
                    DispatchQueue.main.async {
                    [weak self] in
                    self!.similarityScoreLabel.text = "Faces are not similar"
                    }
                }
            }
            else{
                os_log("No Result")
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

