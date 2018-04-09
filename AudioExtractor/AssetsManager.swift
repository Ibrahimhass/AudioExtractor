//
//  AssetsManager.swift
//  AudioExtractor
//
//  Created by Md Ibrahim Hassan on 08/04/18.
//  Copyright © 2018 Md Ibrahim Hassan. All rights reserved.
//

import Foundation

class AssetsManager {
    
    func getAudioFilesCount() -> Int {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            let mp3Files = directoryContents.filter{ $0.pathExtension == "m4a" }
            return mp3Files.count
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return 0
    }
    
    func getM4AfilePathAt(index : IndexPath) -> URL? {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            let mp3Files = directoryContents.filter{ $0.pathExtension == "m4a" }
            if (index.row < mp3Files.count) {
                return mp3Files[index.row]
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func getFileNameAt(index indexPath: IndexPath) -> String? {
        if let m4AUrl = getM4AfilePathAt(index: indexPath) {
            return(m4AUrl.deletingPathExtension().lastPathComponent)
        }
        return nil
    }
}
