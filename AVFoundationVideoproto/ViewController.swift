//
//  ViewController.swift
//  AVFoundationVideoproto
//
//  Created by om on 2019/11/23.
//  Copyright © 2019 Ree. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Foundation

class ViewController: UIViewController,AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var Preview: UIView!
    

    //セッション
    var session: AVCaptureSession!
    //ビデオデバイス
    var videoDevice: AVCaptureDevice!
    //オーディオデバイス
    var audioDevice: AVCaptureDevice!
    //ファイル出力
    var fileOutput: AVCaptureMovieFileOutput!
    //ステータス
    //let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)

    override func viewDidLoad() {
        
        //セッション生成
        session = AVCaptureSession()
        //入力：背面カメラ
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice)
        session.addInput(videoInput)
        
        //フォーマット指定
        switchFormat(desired: 60.0)
        
        //入力：マイク
        audioDevice = AVCaptureDevice.default(for: .audio)
        let audioInput = try! AVCaptureDeviceInput.init(device: audioDevice)
        session.addInput(audioInput)
        
        //出力
        fileOutput = AVCaptureMovieFileOutput()
        session.addOutput(fileOutput)
        
        //プレビュー
        let previewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = self.Preview.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        self.Preview.layer.addSublayer(previewLayer)

        //セッション開始
        session.startRunning()
        
        super.viewDidLoad()
        

    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//
//
//    }

        
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("録画完了")
    }
    
    private func switchFormat(desired: Double) {
        let isRunning = session.isRunning
        if isRunning { session.stopRunning() }
        
        //取得したフォーマットを格納する変数
        var selectedFormat: AVCaptureDevice.Format! = nil
        //そのフレームレートの中で一番大きい解像度を取得する
        var currentMaxWidth: Int32 = 0
        
        //フォーマット探索
        for format in videoDevice.formats {
            for range: AVFrameRateRange in format.videoSupportedFrameRateRanges {
                let description = format.formatDescription as CMFormatDescription //フォーマットの説明
                let dimensions = CMVideoFormatDescriptionGetDimensions(description) //幅・高さの情報
                let width = dimensions.width //幅
                
                //指定のフレームレートで一番大きな解像度を得る
                if desired == range.maxFrameRate && currentMaxWidth <= width && width <= 1920 {
                    selectedFormat = format
                    currentMaxWidth = width
                }
            }
        }
        
        if selectedFormat != nil {
            do {
                try videoDevice.lockForConfiguration()
                videoDevice.activeFormat = selectedFormat
                videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(desired))
                videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(desired))
                videoDevice.unlockForConfiguration()
                
                if isRunning { session.startRunning() }
            }
            catch {
                print("フォーマット・フレームレートが指定できませんでした : \(desired)fps")
            }
        }
        else {
            print("フォーマットが取得できませんでした : \(desired)fps")
        }
    }

    //録画開始
    private func startRecording() {
        //Documents ディレクトリ直下にファイルを生成する
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        //現在時刻をファイル名に付与する
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSS"
        let filePath: String? = "\(documentsDirectory)/myvideo-\(formatter.string(from: Date())).mp4"
        let fileURL = NSURL(fileURLWithPath: filePath!)
        
        print("録画開始 : \(filePath!)")
        fileOutput?.startRecording(to: fileURL as URL, recordingDelegate: self)

        
    }
    
    //録画停止
    private func stopRecording() {
        print("録画停止")
        fileOutput?.stopRecording()
        
    }
    
    //アプリ内に保存したmp4ファイルをカメラロールに書き出す
    private func outputVideos() {
        //Documentsディレクトリ
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            //Documenrtsディレクトリ配下のファイル一覧を取得する
            let contentUrls = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil)
            for contentUrl in contentUrls {
                //拡張しで判定する
                if contentUrl.pathExtension == "mp4" {
                    //mp4ファイルならカメラロールに書き出す
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: contentUrl)
                    }) { (isCompleted, error) in
                        if isCompleted {
                            //カメラロールに書き出し成功
                            do {
                                try FileManager.default.removeItem(atPath: contentUrl.path)
                                print("カメラロール書き出し・ファイル削除成功 : \(contentUrl.lastPathComponent)")
                            }
                            catch {
                                print("カメラロール書き出し後のファイル削除失敗 : \(contentUrl.lastPathComponent)")
                            }
                        }
                        else {
                            print("カメラロール書き出し失敗 : \(contentUrl.lastPathComponent)")
                        }
                    }
                }
            }
        }
        catch {
            print("ファイル一覧取得エラー")
        }
    }

}

