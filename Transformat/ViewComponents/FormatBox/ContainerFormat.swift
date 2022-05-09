//
//  Format.swift
//  Transformat
//
//  Created by QIU DU on 7/5/22.
//

enum ContainerFormat: String, CaseIterable {
    
    case gif
    case mp4
    case mkv
    case mov
    
    var title: String {
        switch self {
        case .gif, .mov:
            return self.rawValue.uppercased()
        case .mp4:
            return "MPEG-4"
        case .mkv:
            return "Matroska"
        }
    }
    
    var titleWithFileExtension: String {
        "\(title) (.\(rawValue))"
    }
    
    var audioCodecs: [AudioCodec] {
        switch self {
        case .gif:
            return []
        case .mp4:
            return [.aac, .ac3, .alac, .mp3]
        case .mkv:
            return AudioCodec.allCases
        case .mov:
            return [.aac, .ac3, .alac, .mp3]
        }
    }
    
    var videoCodecs: [VideoCodec] {
        switch self {
        case .gif:
            return []
        case .mp4:
            return [.h264, .hevc, .mpeg4]
        case .mkv:
            return VideoCodec.allCases
        case .mov:
            return [.h264, .mpeg4, .prores]
        }
    }
}

enum AudioCodec: String, CaseIterable {
    /// AAC (Advanced Audio Coding) (decoders: aac aac_fixed aac_at ) (encoders: aac aac_at )
    case aac
    /// ATSC A/52A (AC-3) (decoders: ac3 ac3_fixed ac3_at ) (encoders: ac3 ac3_fixed )
    case ac3
    /// ALAC (Apple Lossless Audio Codec) (decoders: alac alac_at ) (encoders: alac alac_at )
    case alac
    /// DCA (DTS Coherent Acoustics) (decoders: dca ) (encoders: dca )
    case dts
    /// ATSC A/52B (AC-3, E-AC-3) (decoders: eac3 eac3_at )
    case eac3
    /// FLAC (Free Lossless Audio Codec)
    case flac
    /// MP3 (MPEG audio layer 3) (decoders: mp3float mp3 mp3_at ) (encoders: libmp3lame )
    case mp3
    /// TrueHD
    case truehd
    /// Vorbis (decoders: vorbis libvorbis ) (encoders: vorbis libvorbis )
    case vorbis
    
    var title: String {
        switch self {
        case .aac:
            return "AAC (Advanced Audio Coding)"
        case .ac3:
            return "ATSC A/52A (AC-3)"
        case .alac:
            return "ALAC (Apple Lossless Audio Codec)"
        case .dts:
            return "DCA (DTS Coherent Acoustics)"
        case .eac3:
            return "ATSC A/52B (AC-3, E-AC-3)"
        case .flac:
            return "FLAC (Free Lossless Audio Codec)"
        case .mp3:
            return "MP3 (MPEG audio layer 3)"
        case .truehd:
            return "TrueHD"
        case .vorbis:
            return "Vorbis"
        }
    }
    
    var encoder: String {
        switch self {
        case .aac: return "aac_at"
        default: return rawValue
        }
    }
}

//MP4 MPEG-H Part 2 (H.265/HEVC), MPEG-4 Part 10 (H.264/AVC) and MPEG-4 Part 2
//x265, 10bit x265, x264, 10bit x264, h.265, AVC, DivX, Xvid, MPEG4, MPEG2, AVCHD


//MOV file format can be encoded by the mainstream video codecs includes MPEG-2, MPEG4-ASP(XVID), H.264, HEVC/h.265, Apple ProRes
enum VideoCodec: String, CaseIterable {
    /// H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10
    case h264
    /// H.265 / HEVC (High Efficiency Video Coding)
    case hevc
    /// MPEG-4 part 2
    case mpeg4
    /// Apple ProRes (iCodec Pro)
    case prores
    
    var title: String {
        switch self {
        case .h264:
            return "H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10"
        case .hevc:
            return "H.265 / HEVC (High Efficiency Video Coding)"
        case .mpeg4:
            return "MPEG-4 part 2"
        case .prores:
            return "Apple ProRes (iCodec Pro)"
        }
    }
}
