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
    
    let cancelAlert = CancelAlert()
    
    var resize: ControlEvent<()> {
        ControlEvent(events: Observable.merge(resizePlayerView, controlPanelViewModel.mediaReset))
    }
    
    let windowTitle = NSLocalizedString("TransVid Forma", comment: "")
    let cancleButtonTitle = NSLocalizedString("Cancel", comment: "")
    
    let controlPanelViewModel: ControlPanelViewModel
    let clipViewModel: ClipViewModel
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
    let isCancelButtonHidden: Driver<Bool>
    let isOptionAreaContainerHidden: Driver<Bool>
    
    private let disposeBag = DisposeBag()
    private let importButtonTitleRelay = BehaviorRelay<String>(value: Constants.importTitle.formatCString(""))
    private let exportButtonTitleRelay = BehaviorRelay<String>(value: Constants.exportTitle.formatCString(""))
    private let progressPercentageRelay = BehaviorRelay<Double?>(value: nil)
    private let isImportExportDisabledRelay = BehaviorRelay<Bool>(value: false)
    private let isExportDisabledRelay = BehaviorRelay<Bool>(value: true)
    private let isOptionAreaContainerHiddenRelay = BehaviorRelay<Bool>(value: false)
    
    private let resizePlayerView = PublishSubject<()>()
    
    private let openPanel: NSOpenPanel
    private let mediaPlayerDelegator: MediaPlayerDelegator
    
    private var ffmpegSession: FFmpegSession?
    
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
        isCancelButtonHidden = progressPercentageRelay.asDriver().map { $0 == nil }
        isOptionAreaContainerHidden = isOptionAreaContainerHiddenRelay.asDriver()
        
        controlPanelViewModel = ControlPanelViewModel(mediaPlayer: mediaPlayer, mediaPlayerDelegator: mediaPlayerDelegator)
        mediaInfomationBoxModel = MediaInfomationBoxModel(mediaPlayer: mediaPlayer, mediaPlayerDelegator: mediaPlayerDelegator)
        clipViewModel = ClipViewModel(
            trimControlModel: controlPanelViewModel.trimControlModel,
            mediaInfomationBoxModel: mediaInfomationBoxModel)
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
            
            // Note:
            // When media is set, mediaInfomationBoxModel.timeRatioRange will fire.
            // We expect playback time should be at beginning of the trim clip in this case.
            // Due to trimControlModel.startTimeRatio and trimControlModel.endTimeRatio will set playback time indivially,
            // startTimeRatio should be set later than endTimeRatio to achieve this behavior.
            mediaInfomationBoxModel.timeRatioRange.map(\.upperBound).drive(controlPanelViewModel.trimControlModel.endTimeRatio),
            mediaInfomationBoxModel.timeRatioRange.map(\.lowerBound).drive(controlPanelViewModel.trimControlModel.startTimeRatio),

            controlPanelViewModel.trimControlModel.timePositionRatioRange.drive(mediaInfomationBoxModel.timeRatioRangeBinder),
            
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
    
    func setPlayerMode(_ isPlayerMode: Bool) {
        isOptionAreaContainerHiddenRelay.accept(isPlayerMode)
    }
    
    func togglePlayerMode(isWindowFullScreen: Bool, window: NSWindow?) {
        guard let window = window else { return }
        let isPlayerMode = isOptionAreaContainerHiddenRelay.value
        if !isPlayerMode && !isWindowFullScreen {
            window.toggleFullScreen(nil)
        }
        isOptionAreaContainerHiddenRelay.accept(!isPlayerMode)
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
            let argumentsBuilder = FFmpegArgumentsBuilder(media: media, outputURL: outputURL, format: formatBoxModel.format) else
        {
            return
        }
        
        let builder = argumentsBuilder.initArguments()
        
        var duration: TimeInterval = .zero
        
        let clips: [Clip]
        if clipViewModel.clips.isEmpty {
            guard
                let start = mediaInfomationBoxModel.startTime?.toTimeInterval(),
                let end = mediaInfomationBoxModel.endTime?.toTimeInterval(),
                start < end else
            {
                return
            }
            clips = [Clip(start: start, end: end)].compactMap { $0 }
        } else {
            clips = clipViewModel.clips
        }
        
        builder.clips(clips)
        
        clips.forEach { clip in
            duration += (clip.end - clip.start) / mediaInfomationBoxModel.speed
        }
        
        guard duration > .zero else { return }
        builder.speed(mediaInfomationBoxModel.speed)
        builder.resolution(mediaInfomationBoxModel.resolution)
            
        if let videoCodec = formatBoxModel.videoCodec {
            builder.videoCodec(codec: videoCodec)
                .videoBitrate()
        }
        
        if let audioCodec = formatBoxModel.audioCodec {
            builder.audioCodec(codec: audioCodec)
                .audioBitrate()
        }
        
        if let framePerSecond = formatBoxModel.framePerSecond {
            builder.framePerSecond(framePerSecond)
        }
        
        let arguments = builder.build()
        #if DEBUG
        print(arguments.joined(separator: " "))
        #endif
        isImportExportDisabledRelay.accept(true)
        progressPercentageRelay.accept(nil)
        
        ffmpegSession = FFmpegKit.execute(
            withArgumentsAsync: arguments,
            withCompleteCallback: { [weak self] session in
                guard session?.getReturnCode()?.isValueSuccess() == true else {
                    self?.isImportExportDisabledRelay.accept(false)
                    self?.progressPercentageRelay.accept(nil)
                    return
                }
                self?.isImportExportDisabledRelay.accept(false)
                self?.progressPercentageRelay.accept(1)
            },
            withLogCallback: { session in
                #if DEBUG
                print("\(session?.getMessage() ?? "session message is nil")")
                #endif
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
    
    func cancel() {
        self.ffmpegSession?.cancel()
        self.isImportExportDisabledRelay.accept(false)
        self.progressPercentageRelay.accept(nil)
    }
    
    private func setMedia(url: URL) {
        guard mediaPlayer.media?.url != url else { return }
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
        static let importTitle = NSLocalizedString("\nImport\n%s", comment: "")
        static let exportTitle = NSLocalizedString("\nExport\n%s", comment: "")
    }
}


struct CancelAlert {
    
    let messageText = NSLocalizedString("Cancel Exporting", comment: "")
    let informativeText = NSLocalizedString("Are you sure to cancel current export task?", comment: "")
    let alertStyle: NSAlert.Style = .warning
    let okButtonTitle = NSLocalizedString("Confirm", comment: "")
    let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
}
