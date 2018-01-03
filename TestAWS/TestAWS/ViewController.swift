//
//  ViewController.swift
//  TestAWS
//
//  Created by Ma Yulu on 2018/1/3.
//  Copyright © 2018年 Ma Yulu. All rights reserved.
//

import UIKit
import Photos
import Gallery
import AWSS3
import AWSCore

class ViewController: UIViewController {
    
    // DEFINE YOUR ENV HERE
    let MyAccessKey = "--YOUR KEY--"
    let MySecretKey = "--YOUR KEY--"
    let MyMinioServer = "http://x.x.x.x:9000"
    let MyBucketName = "qbme"
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton(type: UIButtonType.system) as UIButton
        let xPostion:CGFloat = (UIApplication.shared.delegate?.window??.bounds.width)! / 2.0 - 100
        let yPostion:CGFloat = (UIApplication.shared.delegate?.window??.bounds.height)! / 2.0 - 30
        let buttonWidth:CGFloat = 200
        let buttonHeight:CGFloat = 60
        
        
        
        button.frame = CGRect(x:xPostion, y:yPostion, width:buttonWidth, height:buttonHeight)
        
        button.backgroundColor = UIColor.lightGray
        button.setTitle("Pick Image", for: UIControlState.normal)
        button.tintColor = UIColor.black
        button.addTarget(self, action: #selector(self.buttonAction(_:)), for: .touchUpInside)
        
        self.view.addSubview(button)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func buttonAction(_ sender:UIButton!) {
        let gallery = GalleryController()
        gallery.delegate = self
        present(gallery, animated: true, completion: nil)
    }
}

extension ViewController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        
        debugPrint("Did Selected Images: ", images.count)
        
        for image in images {
            image.resolve(completion: { (aImage) in
                let imgData = UIImageJPEGRepresentation(aImage!, 0.5)!
                self.push2awss3(data: imgData)
            })
        }
        controller.dismiss(animated: true, completion: nil)
    }
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
    }
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
    }
    func galleryControllerDidCancel(_ controller: GalleryController) {
    }
}

// Helper functions
extension ViewController {

    func push2awss3(data: Data?) {
        let accessKey = MyAccessKey
        let secretKey = MySecretKey
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
        let configuration = AWSServiceConfiguration(region: .USEast1,
                                                    endpoint: AWSEndpoint(region: .USEast1,
                                                                          service: .S3,
                                                                          url: URL(string: MyMinioServer)),
                                                    credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        let S3BucketName = MyBucketName
        let remoteName = "testaws.jpg"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(remoteName)
        do {
            try data?.write(to: fileURL)
        }
        catch {
        }
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()!
        uploadRequest.body = fileURL
        uploadRequest.key = remoteName
        uploadRequest.bucket = S3BucketName
        uploadRequest.contentType = "image/jpeg"
        uploadRequest.acl = .publicRead
        
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(uploadRequest).continueWith { (task: AWSTask<AnyObject>) -> Any? in
            DispatchQueue.main.async {
                
            }
            if let error = task.error {
                print("Upload failed with error: (\(error.localizedDescription))")
            }
            if task.result != nil {
                let url = AWSS3.default().configuration.endpoint.url
                let publicURL = url?.appendingPathComponent(uploadRequest.bucket!).appendingPathComponent(uploadRequest.key!)
                print("Uploaded to:\(String(describing: publicURL!))")
            }
            return nil
        }
    }
    
}

