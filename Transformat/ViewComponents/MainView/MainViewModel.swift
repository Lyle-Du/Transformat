//
//  MainViewModel.swift
//  Transformat
//
//  Created by QIU DU on 7/5/22.
//

import ffmpegkit
import RxCocoa
import RxSwift
import VLCKit

final class MainViewModel {
    
    let controlPanelViewModel: ControlPanelViewModel
    let mediaInfomationBoxModel: MediaInfomationBoxModel
    let formatBoxModel: FormatBoxModel
    
    let importButtonTitle: Driver<String>
    let exportButtonTitle: Driver<String>
    
    let mediaPlayer: VLCMediaPlayer
    
    let stateChangedDriver: Driver<VLCMediaPlayer>
    let progressPercentage: Driver<Double?>
    let progressPercentageText: Driver<String>
    let isImportExportDisabled: Driver<Bool>
    
    private let disposeBag = DisposeBag()
    private let importButtonTitleRelay = BehaviorRelay<String>(value: Constants.importTitle.formatCString(""))
    private let exportButtonTitleRelay = BehaviorRelay<String>(value: Constants.exportTitle.formatCString(""))
    private let startTimeRelay = BehaviorRelay<TimeInterval>(value: .zero)
    private let endTimeRelay = BehaviorRelay<TimeInterval>(value: .zero)
    private let progressPercentageRelay = BehaviorRelay<Double?>(value: nil)
    private let isImportExportDisabledRelay = BehaviorRelay<Bool>(value: false)
    
    private let openPanel: NSOpenPanel
    private let mediaPlayerDelegator: MediaPlayerDelegator
    
    init(
        openPanel: NSOpenPanel = NSOpenPanel(),
        mediaPlayer: VLCMediaPlayer = VLCMediaPlayer())
    {
        self.openPanel = openPanel
        self.mediaPlayer = mediaPlayer
        self.mediaPlayerDelegator = MediaPlayerDelegator(mediaPlayer: self.mediaPlayer)
        
        openPanel.allowedFileTypes = ContainerFormat.allCases.map(\.rawValue)
        
        importButtonTitle = importButtonTitleRelay.asDriver()
        exportButtonTitle = exportButtonTitleRelay.asDriver()
        isImportExportDisabled = isImportExportDisabledRelay.asDriver()
        
        controlPanelViewModel = ControlPanelViewModel(mediaPlayer: mediaPlayer, mediaPlayerDelegator: mediaPlayerDelegator)
        mediaInfomationBoxModel = MediaInfomationBoxModel(mediaPlayer: mediaPlayer, mediaPlayerDelegator: mediaPlayerDelegator)
        formatBoxModel = FormatBoxModel(mediaPlayer: mediaPlayer)
        stateChangedDriver = mediaPlayerDelegator.stateChangedDriver
        progressPercentage = progressPercentageRelay.asDriver().map { $0?.clamped(to: .zero...1) }.distinctUntilChanged()
        progressPercentageText = progressPercentage.map { percent in
            guard let percent = percent else {
                return ""
            }
            return String(format: "%.0f", percent * 100) + "%"
        }
        
        disposeBag.insert([
            mediaPlayerDelegator.stateChangedDriver.drive(controlPanelViewModel.stateChanged),
            mediaPlayerDelegator.timeChangedDriver.drive(controlPanelViewModel.timeChanged),
            startTimeRelay.asDriver().drive(mediaInfomationBoxModel.startTimeLimitBinder),
            endTimeRelay.asDriver().drive(mediaInfomationBoxModel.endTimeLimitBinder),
            mediaInfomationBoxModel.startTimeRatio.drive(controlPanelViewModel.trimControlModel.startTimeRatio),
            mediaInfomationBoxModel.endTimeRatio.drive(controlPanelViewModel.trimControlModel.endTimeRatio),
            controlPanelViewModel.trimControlModel.startTimePositionRatio.drive(mediaInfomationBoxModel.startTimeRatioBinder),
            controlPanelViewModel.trimControlModel.endTimePositionRatio.drive(mediaInfomationBoxModel.endTimeRatioBinder),
            progressPercentageText.map { Constants.exportTitle.formatCString($0) }.drive(exportButtonTitleRelay),
            Driver.zip(isImportExportDisabled, isImportExportDisabled.skip(1))
                .filter { previous, current in return !current && previous }
                .map { _, _ in return nil }
                .delay(.seconds(1))
                .drive(progressPercentageRelay),
        ])
    }
    
    func importButtonClicked() {
        guard
            openPanel.runModal() == .OK,
            let url = openPanel.url else
        {
            return
        }
        
        setMedia(url: url)
    }
    
    func exportButtonClicked() {
        guard
            let media = mediaPlayer.media,
            let inputURL = mediaPlayer.media?.url,
            let outputURL = formatBoxModel.fileURL else
        {
            return
        }
        
        guard inputURL.path != outputURL.path else {
            return
        }
        
        var videoBitrateOption: String?
        var videoBitrateText: String?
        if let audioBitrate = FFprobeKit.videoBitrate(media: media) {
            videoBitrateOption = "-b:v"
            videoBitrateText = String(audioBitrate)
        }
        
        var audioBitrateOption: String?
        var audioBitrateText: String?
        if let audioBitrate = FFprobeKit.audioTracks(media: media)[mediaInfomationBoxModel.audioTrackIndex]?.bitrate {
            audioBitrateOption = "-b:a"
            audioBitrateText = String(audioBitrate)
        }
        
        var videoCodecOption: String?
        let videoCodec = formatBoxModel.videoCodec?.rawValue
        if videoCodec != nil {
            videoCodecOption = "-c:v"
        }
        var audioCodecOption: String?
        let audioCodec = formatBoxModel.audioCodec?.encoder
        if audioCodec != nil {
            audioCodecOption = "-c:a"
        }
        
        var resolutionOption: String?
        var resolutionValue: String?
        if let resolution = mediaInfomationBoxModel.resolution {
            resolutionOption = "-vf"
            resolutionValue = "scale=\(resolution.width):\(resolution.height)"
        }
        
        let arguments = [
            "-ss",
            mediaInfomationBoxModel.startTime,
            "-to",
            mediaInfomationBoxModel.endTime,
            "-nostdin",
            "-y",
            "-i",
            inputURL.path,
            videoCodecOption,
            videoCodec,
            audioCodecOption,
            audioCodec,
            videoBitrateOption,
            videoBitrateText,
            audioBitrateOption,
            audioBitrateText,
            resolutionOption,
            resolutionValue,
            outputURL.path,
        ].compactMap { $0 }
        
        print(arguments.joined(separator: " "))
        
        var duration: TimeInterval?
        if
            let startTimeInterval = mediaInfomationBoxModel.startTime.toTimeInterval(),
            let endTimeInterval = mediaInfomationBoxModel.endTime.toTimeInterval()
        {
            duration = endTimeInterval - startTimeInterval
        }
        
        guard let duration = duration else {
            return
        }
        isImportExportDisabledRelay.accept(true)
        progressPercentageRelay.accept(nil)
        let sesson = FFmpegKit.execute(
            withArgumentsAsync: arguments,
            withCompleteCallback: { [weak self] session in
                self?.isImportExportDisabledRelay.accept(false)
                guard
                    let self = self,
                    let session = session else
                {
                    return
                }
                self.progressPercentageRelay.accept(1)
            },
            withLogCallback: { session in
                guard let session = session else {
                    return
                }
            },
            withStatisticsCallback: { [weak self] session in
                guard
                    let self = self,
                    let session = session else
                {
                    return
                }
                let current = Double(session.getTime()) / 1000
                let percent = (current / duration).clamped(to: 0...1.0)
                self.progressPercentageRelay.accept(percent)
            })
    }
    
    private func setMedia(url: URL) {
        guard mediaPlayer.media?.url != url else {
            return
        }
        mediaPlayer.stop()
        let media = VLCMedia(url: url)
        mediaPlayer.media = media
        mediaInfomationBoxModel.setMedia(media)
        if let size = FFprobeKit.sizeInBytes(media: media) {
            importButtonTitleRelay.accept(Constants.importTitle.formatCString(size))
        }
    }
}

private extension MainViewModel {
    
    struct Constants {
        static let importTitle = "\nImport\n%s"
        static let exportTitle = "\nExport\n%s"
    }
}
