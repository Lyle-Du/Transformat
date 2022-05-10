//
//  FormatBoxModel.swift
//  Transformat
//
//  Created by QIU DU on 7/5/22.
//

import Foundation

import RxCocoa
import RxSwift
import VLCKit

final class FormatBoxModel {
    
    let formatLabel = "Format:"
    let videoCodecLabel = "Video Codec:"
    
    let audioCodecLabel = "Audio Codec:"
    
    let outputPathLabel = "Save to:"
    let outputPathButtonTitle = "Choose"
    
    let outputPath: Driver<String>
    let selectedFormatIndex: Driver<Int>
    let formatTitles = ContainerFormat.allCases.map { $0.titleWithFileExtension }
    
    let videoCodecTitles: Driver<[String]>
    let audioCodecTitles: Driver<[String]>
    let selectedVideoCodecIndex: Driver<Int>
    let selectedAudioCodecIndex: Driver<Int>
    
    private let videoCodecTitlesRelay = BehaviorRelay<[String]>(value: [])
    private let selectedVideoCodecIndexRelay: BehaviorRelay<Int>
    private let audioCodecTitlesRelay = BehaviorRelay<[String]>(value: [])
    private let selectedAudioCodecIndexRelay: BehaviorRelay<Int>
    
    private let mediaPlayer: VLCMediaPlayer
    private let savePanel: NSSavePanel
    private let userDefaults: UserDefaults
    
    private let disposeBag = DisposeBag()
    private let outputPathRelay = BehaviorRelay<URL?>(value: nil)
    private let selectedFormatRelay: BehaviorRelay<ContainerFormat>
    
    init(
        mediaPlayer: VLCMediaPlayer,
        savePanel: NSSavePanel = NSSavePanel(),
        userDefaults: UserDefaults = .standard)
    {
        self.mediaPlayer = mediaPlayer
        self.savePanel = savePanel
        self.userDefaults = userDefaults
        
        videoCodecTitles = videoCodecTitlesRelay.asDriver()
        audioCodecTitles = audioCodecTitlesRelay.asDriver()
        
        savePanel.allowedFileTypes = ContainerFormat.allCases.map(\.rawValue)
        savePanel.allowsOtherFileTypes = false
        savePanel.showsTagField = false
        
        var selectedFormat = ContainerFormat.gif
        if
            let formatString = userDefaults.string(forKey: StoreKeys.selectedFormat),
            let format = ContainerFormat(rawValue: formatString)
        {
            selectedFormat = format
        }
        
        selectedFormatRelay = BehaviorRelay(value: selectedFormat)
        
        selectedVideoCodecIndexRelay = BehaviorRelay(value: selectedFormat.videoCodecs.count > 0 ? 0 : -1)
        selectedAudioCodecIndexRelay = BehaviorRelay(value: selectedFormat.audioCodecs.count > 0 ? 0 : -1)
        
        selectedFormatIndex = selectedFormatRelay.distinctUntilChanged()
            .compactMap { ContainerFormat.allCases.firstIndex(of: $0) }
            .asDriver(onErrorJustReturn: 0)
        
        outputPath = outputPathRelay.asDriver().map { $0?.path ?? "" }
        
        selectedVideoCodecIndex = selectedVideoCodecIndexRelay.asDriver()
        selectedAudioCodecIndex = selectedAudioCodecIndexRelay.asDriver()
        
        let selectedFormatObserable = selectedFormatRelay.distinctUntilChanged()
        
        disposeBag.insert([
            selectedFormatObserable.map { [$0.rawValue] }.bind(to: savePanel.rx.allowedFileTypes),
            selectedFormatObserable.subscribe(onNext: { [weak self] selected in
                guard let self = self else { return }
                self.userDefaults.set(selected.rawValue, forKey: StoreKeys.selectedFormat)
                self.outputPathRelay.accept(nil)
                self.videoCodecTitlesRelay.accept(selected.videoCodecs.map(\.title))
                self.audioCodecTitlesRelay.accept(selected.audioCodecs.map(\.title))
            }),
        ])
    }
    
    func setOutputPath() {
        let url = mediaPlayer.media?.url?.deletingPathExtension().appendingPathExtension(selectedFormatRelay.value.rawValue)
        savePanel.nameFieldStringValue = "Untitled.\(selectedFormatRelay.value.rawValue)"
        if let filename = url?.lastPathComponent {
            savePanel.nameFieldStringValue = filename
        }
        
        if savePanel.runModal() == .OK {
            guard var url = savePanel.url else { return }
            if let format = ContainerFormat(rawValue: url.pathExtension) {
                selectedFormatRelay.accept(format)
            } else {
                url.deletePathExtension()
                url.appendPathExtension(selectedFormatRelay.value.rawValue)
            }
            outputPathRelay.accept(url)
        }
    }
}

extension FormatBoxModel {
    
    struct StoreKeys {
        static let selectedFormat = "FormatBoxModel.StoreKeys.selectedFormat"
    }
}

extension FormatBoxModel {
    
    var selectedIndexBinder: Binder<Int> {
        Binder(self) { target, index in
            let selected = ContainerFormat.allCases[index]
            guard selected != target.selectedFormatRelay.value else {
                return
            }
            target.selectedFormatRelay.accept(selected)
            target.outputPathRelay.accept(nil)
        }
    }
    
    var selectedVideoCodecIndexBinder: Binder<Int> {
        Binder(self) { target, index in
            target.selectedVideoCodecIndexRelay.accept(index)
        }
    }
    
    var selectedAudioCodecIndexBinder: Binder<Int> {
        Binder(self) { target, index in
            target.selectedAudioCodecIndexRelay.accept(index)
        }
    }
}

extension FormatBoxModel {
    
    var fileURL: URL? {
        outputPathRelay.value
    }
    
    var format: ContainerFormat {
        selectedFormatRelay.value
    }
    
    var videoCodec: VideoCodec? {
        let index = selectedVideoCodecIndexRelay.value
        guard
            index != -1,
            selectedFormatRelay.value.videoCodecs.count > 0 else
        {
            return nil
        }
        return selectedFormatRelay.value.videoCodecs[index]
    }
    
    var audioCodec: AudioCodec? {
        let index = selectedAudioCodecIndexRelay.value
        guard
            index != -1,
            selectedFormatRelay.value.audioCodecs.count > 0 else {
            return nil
        }
        return selectedFormatRelay.value.audioCodecs[index]
    }
}
