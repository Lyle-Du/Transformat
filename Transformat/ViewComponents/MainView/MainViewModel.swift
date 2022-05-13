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
    
    var resize: ControlEvent<()> {
        ControlEvent(events: resizePlayerView)
    }
    
    let windowTitle = "Transformat"
    
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
    let isExportDisabled: Driver<Bool>
    
    private let disposeBag = DisposeBag()
    private let importButtonTitleRelay = BehaviorRelay<String>(value: Constants.importTitle.formatCString(""))
    private let exportButtonTitleRelay = BehaviorRelay<String>(value: Constants.exportTitle.formatCString(""))
    private let startTimeRelay = BehaviorRelay<TimeInterval>(value: .zero)
    private let endTimeRelay = BehaviorRelay<TimeInterval>(value: .zero)
    private let progressPercentageRelay = BehaviorRelay<Double?>(value: nil)
    private let isImportExportDisabledRelay = BehaviorRelay<Bool>(value: false)
    private let isExportDisabledRelay = BehaviorRelay<Bool>(value: true)
    
    private let resizePlayerView = PublishSubject<()>()
    
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
        isExportDisabled = isExportDisabledRelay.asDriver()
        
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
            // Fix buttion is not disabled in the beginning by slight delay
            Observable.just(true).delay(.milliseconds(100), scheduler: MainScheduler.instance).bind(to: isExportDisabledRelay),
            
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
            
            formatBoxModel.outputPath.drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateExportAvailability(self.mediaPlayer.media)
            }),
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
        updateExportAvailability(mediaPlayer.media)
        guard
            let media = mediaPlayer.media,
            let outputURL = formatBoxModel.fileURL,
            let argumentsBuilder = FFmpegArgumentsBuilder(media: media, outputURL: outputURL) else
        {
            return
        }
        
        let arguments = argumentsBuilder.reset()
            .time(start: mediaInfomationBoxModel.startTime, end: mediaInfomationBoxModel.endTime)
            .videoCodec(codec: formatBoxModel.videoCodec)
            .videoBitrate()
            .audioCodec(codec: formatBoxModel.audioCodec)
            .audioBitrate()
            .audioTrack(index: mediaInfomationBoxModel.audioTrackIndex)
            .resolution(mediaInfomationBoxModel.resolution)
            .build()
        
        guard
            let startTimeInterval = mediaInfomationBoxModel.startTime.toTimeInterval(),
            let endTimeInterval = mediaInfomationBoxModel.endTime.toTimeInterval() else
        {
            return
        }
        let duration = endTimeInterval - startTimeInterval
        isImportExportDisabledRelay.accept(true)
        progressPercentageRelay.accept(nil)
        let sesson = FFmpegKit.execute(
            withArgumentsAsync: arguments,
            withCompleteCallback: { [weak self] session in
                self?.isImportExportDisabledRelay.accept(false)
                self?.progressPercentageRelay.accept(1)
            },
            withLogCallback: { _ in },
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
        do { _ = sesson }
    }
    
    private func setMedia(url: URL) {
        guard mediaPlayer.media?.url != url else {
            return
        }
        mediaPlayer.stop()
        resizePlayerView.onNext(())
        let media = VLCMedia(url: url)
        controlPanelViewModel.trimControlModel.loadThumbnails(media)
        mediaPlayer.media = media
        mediaInfomationBoxModel.setMedia(media)
        if let size = FFprobeKit.sizeInBytes(media: media) {
            importButtonTitleRelay.accept(Constants.importTitle.formatCString(size))
        }
        updateExportAvailability(media)
    }
    
    private func updateExportAvailability(_ media: VLCMedia?) {
        if formatBoxModel.fileURL == nil || media?.url?.path == nil || media?.url?.path == formatBoxModel.fileURL?.path {
            isExportDisabledRelay.accept(true || isImportExportDisabledRelay.value)
        } else {
            isExportDisabledRelay.accept(isImportExportDisabledRelay.value)
        }
    }
}

private extension MainViewModel {
    
    struct Constants {
        static let importTitle = "\nImport\n%s"
        static let exportTitle = "\nExport\n%s"
    }
}
