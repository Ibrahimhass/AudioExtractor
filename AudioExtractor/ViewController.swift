//
//  ViewController.swift
//  AudioExtractor
//
//  Created by Md Ibrahim Hassan on 08/04/18.
//  Copyright © 2018 Md Ibrahim Hassan. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import MediaPlayer

class ViewController: UIViewController {
    
    @IBOutlet weak var timeSeeker: UISlider!
    
    @IBAction func sliderChanged(_ sender: UISlider) {
    }
    
    @IBAction func togglePlayPause(_ sender: UIButton) {
        if audioPlayer.isPlaying {
            sender.isSelected = false
            audioPlayer.stop()
        } else {
            sender.isSelected = true
            audioPlayer.play()
        }
    }
    
    @IBAction func playPrevious(_ sender: UIButton) {
         playPreviousSong()
    }
    
    @IBAction func playNext(_ sender: UIButton) {
         playNextSong()
    }
    
    @IBAction func loadFilesTapped(_ sender: Any) {
        present(picker, animated: true)
    }
    
    @IBOutlet weak var songsTableView: UITableView!
    fileprivate var audioPlayer: AVAudioPlayer!
    fileprivate lazy var assetsManager : AssetsManager = {
        AssetsManager()
    }()
    fileprivate let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        customizeImagePickerToPickOnlyVideo()
        configureAudioSessionToPlayIfTheAppIsMinimized()
    }
    
    private func customizeImagePickerToPickOnlyVideo() {
        picker.mediaTypes = [kUTTypeMovie as String, kUTTypeAVIMovie as String, kUTTypeVideo as String, kUTTypeMPEG4 as String]
        picker.videoQuality = .typeLow
        picker.sourceType = .photoLibrary
    }
    
    private func configureAudioSessionToPlayIfTheAppIsMinimized() {
    do {
        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .defaultToSpeaker)
        try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("error audio session")
        }
    }
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
            dismiss(animated: true, completion: {
                guard let mediaType : CFString = info[UIImagePickerControllerMediaType] as! CFString,
                    let mediaUrl = info[UIImagePickerControllerMediaURL]
                    else { return }
                if (mediaType == kUTTypeVideo || mediaType == kUTTypeMovie) {
                    let mediaData = try! Data.init(contentsOf: mediaUrl as! URL)
                    let fileManager = FileManager.default
                    do {
                        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                        let dateFormat = DateFormatter()
                        dateFormat.dateFormat = "dd-MM-yyyy||HH:mm:SS"
                        let now = Date()
                        let theDate = dateFormat.string(from: now)
                        
                        let fileURL = documentDirectory.appendingPathComponent("\(theDate).mov")
                        let pathTo = documentDirectory.appendingPathComponent("\(theDate).m4a")
                        try mediaData.write(to: fileURL)
                        let asset = AVURLAsset.init(url: fileURL)
                        asset.writeAudioTrack(to: pathTo, success: {
                            try? fileManager.removeItem(at: fileURL)
                            DispatchQueue.main.async {
                                self.songsTableView.reloadData()
                            }
                            }, failure: { (error) in
                            print(error.localizedDescription)
                        })
                    } catch {
                        print(error)
                    }
                }
            }
        )
    }
    
    fileprivate func playAudioAt(Url url: URL){
        do {
            let sound = try AVAudioPlayer(contentsOf: url)
            audioPlayer = sound
            audioPlayer.enableRate = true
            audioPlayer.isMeteringEnabled = true
            audioPlayer.volume = 1.0
            audioPlayer.play()
            setUpBackgroundMode()
        } catch {
        }
    }
    
    fileprivate func setUpBackgroundMode() {
        let ar = MPMediaItemArtwork(image: UIImage(named: "Music")!)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Music1234",
            MPMediaItemPropertyArtist: "RecordededAudio",
            MPMediaItemPropertyArtwork: ar,
            MPMediaItemPropertyPlaybackDuration: audioPlayer.duration
        ]
        UIApplication.shared.beginReceivingRemoteControlEvents()
        becomeFirstResponder()
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        if let receivedEvent = event {
            if (receivedEvent.type == .remoteControl) {
                switch receivedEvent.subtype {
                case .remoteControlTogglePlayPause:
                    if audioPlayer.isPlaying {
                        audioPlayer.stop()
                    } else {
                        audioPlayer.play()
                    }
                case .remoteControlPlay:
                    audioPlayer.play()
                case .remoteControlPause:
                    audioPlayer.pause()
                case .remoteControlNextTrack:
                    playNextSong()
                case .remoteControlPreviousTrack:
                    playPreviousSong()
                default:
                    print("received sub type \(receivedEvent.subtype) Ignoring")
                }
            }
        }
    }
    
    fileprivate func playNextSong() {
        if let currentIndex = self.songsTableView.indexPathForSelectedRow {
            if currentIndex.row + 1 < assetsManager.getAudioFilesCount() {
                if let assetUrl = assetsManager.getM4AfilePathAt(
                    index: IndexPath.init(
                        row: currentIndex.row + 1,
                        section: 0)
                    ) {
                    self.songsTableView.selectRow(at: IndexPath.init(row: currentIndex.row + 1, section: 0), animated: true, scrollPosition: .none)
                    self.playAudioAt(Url: assetUrl)
                }
            } else {
                if let assetUrl = assetsManager.getM4AfilePathAt(
                    index: IndexPath.init(
                        row: 0,
                        section: 0)
                    ) {
                    self.songsTableView.selectRow(at: IndexPath.init(row: 0, section: 0), animated: true, scrollPosition: .none)
                    self.playAudioAt(Url: assetUrl)
                }
            }
        }
    }
    
    fileprivate func playPreviousSong() {
        if let currentIndex = self.songsTableView.indexPathForSelectedRow {
            if currentIndex.row - 1 >= 0 {
                if let assetUrl = assetsManager.getM4AfilePathAt(
                    index: IndexPath.init(
                        row: currentIndex.row - 1,
                        section: 0)
                    ) {
                    self.songsTableView.selectRow(at: IndexPath.init(
                        row: currentIndex.row - 1,
                        section: 0
                    ), animated: true,
                       scrollPosition: .none
                    )
                    self.playAudioAt(Url: assetUrl)
                }
            } else {
                if let assetUrl = assetsManager.getM4AfilePathAt(
                    index: IndexPath.init(
                        row: assetsManager.getAudioFilesCount() - 1,
                        section: 0)
                    ) {
                    self.songsTableView.selectRow(at: IndexPath.init(
                        row: assetsManager.getAudioFilesCount() - 1,
                        section: 0
                        ), animated: true,
                           scrollPosition: .none
                    )

                    self.playAudioAt(Url: assetUrl)
                }
            }
        }
    }
    
}

extension ViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let soundURL = assetsManager.getM4AfilePathAt(index: indexPath) {
            playAudioAt(Url: soundURL)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let editAction = UITableViewRowAction(style: .normal, title: "Edit") { (rowAction, indexPath) in
            
            let alert = UIAlertController(title: "Edit File Name",
                                          message: "Enter new name",
                                          preferredStyle: .alert)
            
            
            let saveAction = UIAlertAction(title: "Save",
                                           style: .default) {
                                            [unowned self] action in
                                            
                                            guard let textField = alert.textFields?.first,
                                                let nameToSave = textField.text,
                                                let fileUrl = self.assetsManager.getM4AfilePathAt(index: indexPath) else {
                                                    return
                                            }
                                            
                                            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                                            let documentDirectory = URL(fileURLWithPath: path)
                                            let destinationPath = documentDirectory.appendingPathComponent("\(nameToSave).m4a")
                                            try? FileManager.default.moveItem(at: fileUrl, to: destinationPath)
                                            DispatchQueue.main.async {
                                                self.songsTableView.reloadData()
                                            }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel",
                                             style: .default)
            
            alert.addTextField()
            
            alert.addAction(saveAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true)
            //TODO: edit the row at indexPath here
        }
        editAction.backgroundColor = .blue
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
            //TODO: Delete the row at indexPath here
            if let assetURl = self.assetsManager.getM4AfilePathAt(index: indexPath) {
                try? FileManager.default.removeItem(
                    at: assetURl
                )
                DispatchQueue.main.async {
                    self.songsTableView.reloadData()
                }
            }
        }
        deleteAction.backgroundColor = .red
        
        return [
            editAction,
            deleteAction
        ]
    }
}

extension ViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetsManager.getAudioFilesCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell")
        if let m4AFileName = assetsManager.getFileNameAt(index: indexPath) {
            cell?.textLabel?.text = m4AFileName
        }
        return cell!
    }
}
