const std = @import("std");
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;
const alloc = std.heap.page_allocator;
const fs = std.fs;

const ffmpeg = @cImport({
    @cInclude("libavcodec/avcodec.h");
    @cInclude("libavformat/avformat.h");
});

pub fn main() !u8 {
    // std.log.default_level = .debug;
    _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    var arg_list = std.ArrayList([]const u8).init(alloc);
    defer arg_list.deinit();
    var arg = args.next();
    while (arg != null) {
        try arg_list.append(arg.?);
        debug("{s}", .{arg.?});
        arg = args.next();
    }
    if (arg_list.items.len < 2) {
        err("You need to specify a media file.", .{});
        return 2;
    }

    // init
    var ctx = ffmpeg.avformat_alloc_context();
    if (ctx == null) {
        err("ERROR could not allocate memory for Format Context.", .{});
        return 1;
    }
    defer ffmpeg.avformat_close_input(&ctx);
    debug("opening the input file {s} and loading format (container) header", .{arg_list.items[1]});

    if (ffmpeg.avformat_open_input(&ctx, @ptrCast(arg_list.items[1]), null, null) != 0) {
        err("ERROR could not open the file.", .{});
        return 1;
    }

    debug("format {s}, duration {} us, bit_rate {}", .{ ctx.*.iformat.*.name, ctx.*.duration, ctx.*.bit_rate });
    debug("finding stream info from format", .{});

    if (ffmpeg.avformat_find_stream_info(ctx, null) < 0) {
        err("ERROR could not find stream info.", .{});
        return 1;
    }

    var p_codec: *ffmpeg.AVCodec = undefined;
    var p_codec_param: *ffmpeg.AVCodecParameters = undefined;
    var video_stream_index: ?usize = null;
    for (0..ctx.*.nb_streams) |i| {
        const pLocalCodecParameters: *ffmpeg.AVCodecParameters = ctx.*.streams[i].*.codecpar;
        debug("AVStream.time_base before open coded {}/{}", .{ ctx.*.streams[i].*.time_base.num, ctx.*.streams[i].*.time_base.den });
        debug("AVStream.r_frame_rate before open coded {}/{}", .{ ctx.*.streams[i].*.r_frame_rate.num, ctx.*.streams[i].*.r_frame_rate.den });
        debug("AVStream.start_time {}", .{ctx.*.streams[i].*.start_time});
        debug("AVStream.duration {}", .{ctx.*.streams[i].*.duration});

        debug("finding the proper decoder (CODEC)", .{});

        const pLocalCodec = ffmpeg.avcodec_find_decoder(pLocalCodecParameters.*.codec_id);
        if (pLocalCodec == null) {
            err("ERROR unsupported codec!\n", .{});
            continue;
        }
        if (pLocalCodecParameters.*.codec_type == ffmpeg.AVMEDIA_TYPE_VIDEO) {
            if (video_stream_index == null) {
                video_stream_index = i;
                p_codec = @constCast(@ptrCast(pLocalCodec));
                p_codec_param = pLocalCodecParameters;
            }
            debug("Video Codec: resolution {} x {}", .{ pLocalCodecParameters.*.width, pLocalCodecParameters.*.height });
        } else if (pLocalCodecParameters.*.codec_type == ffmpeg.AVMEDIA_TYPE_AUDIO) {
            debug("Audio Codec: {} channels, sample rate {}", .{ pLocalCodecParameters.*.channels, pLocalCodecParameters.*.sample_rate });
        }
        debug("\tCodec {s} ID {} bit_rate {}", .{ pLocalCodec.*.name, pLocalCodec.*.id, pLocalCodecParameters.*.bit_rate });
    }
    if (video_stream_index == null) {
        err("File {s} does not contain a video stream!", .{arg_list.items[1]});
        return 1;
    }
    var pCodecContext = ffmpeg.avcodec_alloc_context3(p_codec);
    if (pCodecContext == null) {
        err("failed to allocated memory for AVCodecContext", .{});
        return 1;
    }
    defer ffmpeg.avcodec_free_context(&pCodecContext);
    // Fill the codec context based on the values from the supplied codec
    // parameters
    // https://ffmpeg.org/doxygen/trunk/group__lavc__core.html#gac7b282f51540ca7a99416a3ba6ee0d16
    if (ffmpeg.avcodec_parameters_to_context(pCodecContext, p_codec_param) < 0) {
        err("failed to copy codec params to codec context", .{});
        return 1;
    }

    if (ffmpeg.avcodec_open2(pCodecContext, p_codec, null) < 0) {
        err("failed to open codec through avcodec_open2", .{});
        return 1;
    }

    var pFrame = ffmpeg.av_frame_alloc();
    if (pFrame == null) {
        err("failed to allocate memory for AVFrame", .{});
        return 1;
    }
    defer ffmpeg.av_frame_free(&pFrame);
    var pPacket = ffmpeg.av_packet_alloc();
    if (pPacket == null) {
        err("failed to allocate memory for AVPacket", .{});
        return 1;
    }
    defer ffmpeg.av_packet_free(&pPacket);

    var response: i32 = 0;
    var how_many_packets_to_process: i32 = 8;
    while (ffmpeg.av_read_frame(ctx, pPacket) >= 0) {
        if (pPacket.*.stream_index == @as(c_int, @intCast(video_stream_index.?))) {
            debug("AVPacket->pts {}", .{pPacket.*.pts});

            response = decode_packet(pPacket, pCodecContext, pFrame);
            if (response < 0) {
                break;
            }
            how_many_packets_to_process -= 1;
            if (how_many_packets_to_process <= 0) {
                break;
            }
        }
        ffmpeg.av_packet_unref(pPacket);
    }
    debug("releasing all the resources", .{});
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    debug("All your {} {} are belong to us.\n", .{ 1, 1 });
    return 0;
}

var av_error: [ffmpeg.AV_ERROR_MAX_STRING_SIZE]u8 = undefined;
fn av_err2str(e: c_int) [*c]u8 {
    return ffmpeg.av_make_error_string(&av_error, ffmpeg.AV_ERROR_MAX_STRING_SIZE, e);
}

fn decode_packet(pPacket: [*c]ffmpeg.AVPacket, pCodecContext: [*c]ffmpeg.AVCodecContext, pFrame: [*c]ffmpeg.AVFrame) i32 {
    // Supply raw packet data as input to a decoder
    // https://ffmpeg.org/doxygen/trunk/group__lavc__decoding.html#ga58bc4bf1e0ac59e27362597e467efff3
    var response: c_int = ffmpeg.avcodec_send_packet(pCodecContext, pPacket);

    if (response < 0) {
        err("Error while sending a packet to the decoder: {s}", .{av_err2str(response)});
        return response;
    }

    var frame_filename_buf: [1024]u8 = undefined;
    while (response >= 0) {
        // Return decoded output data (into a frame) from a decoder
        // https://ffmpeg.org/doxygen/trunk/group__lavc__decoding.html#ga11e6542c4e66d3028668788a1a74217c
        response = ffmpeg.avcodec_receive_frame(pCodecContext, pFrame);
        if (response == ffmpeg.AVERROR(ffmpeg.EAGAIN) or response == ffmpeg.AVERROR_EOF) {
            break;
        } else if (response < 0) {
            err("Error while receiving a frame from the decoder: {s}", .{av_err2str(response)});
            return response;
        }

        if (response >= 0) {
            debug("Frame {} (type={c}, size={} bytes, format={}) pts {} key_frame {} [DTS {}]", .{ pCodecContext.*.frame_number, ffmpeg.av_get_picture_type_char(pFrame.*.pict_type), pFrame.*.pkt_size, pFrame.*.format, pFrame.*.pts, pFrame.*.key_frame, pFrame.*.coded_picture_number });

            const frame_filename = std.fmt.bufPrint(&frame_filename_buf, "{s}-{}.pgm", .{ "frame", pCodecContext.*.frame_number }) catch return 1;
            //   snprintf(frame_filename, sizeof(frame_filename), "%s-%d.pgm", "frame",
            //            pCodecContext.*.frame_number);
            // Check if the frame is a planar YUV 4:2:0, 12bpp
            // That is the format of the provided .mp4 file
            // RGB formats will definitely not give a gray image
            // Other YUV image may do so, but untested, so give a warning
            if (pFrame.*.format != ffmpeg.AV_PIX_FMT_YUV420P) {
                warn("Warning: the generated file may not be a grayscale image, but could e.g. be just the R component if the video format is RGB", .{});
            }
            // save a grayscale frame into a .pgm file
            save_gray_frame(pFrame.*.data[0], @intCast(pFrame.*.linesize[0]), @intCast(pFrame.*.width), pFrame.*.height, frame_filename);
        }
    }
    return 0;
}

fn save_gray_frame(buf: [*c]u8, wrap: usize, xsize: usize, ysize: i32, filename: []const u8) void {
    var f1 = std.fs.cwd().makeOpenPath("frame", .{}) catch @panic("makeOpenPath failed");
    var f: ?std.fs.File = null;
    if (f1.openFile(filename, std.fs.File.OpenFlags{ .mode = .write_only })) |data| {
        f = data;
    } else |e| {
        if (e != error.FileNotFound) {
            @panic("openFile failed");
        } else {
            f = f1.createFile(filename, .{}) catch @panic("createFile failed");
        }
    }
    defer f.?.close();

    var frame_buf: [18]u8 = undefined;
    f.?.writeAll(std.fmt.bufPrint(&frame_buf, "P5\n{} {}\n255\n", .{ xsize, ysize }) catch @panic("bufPrint failed")) catch @panic("f.writeAll failed");
    var i: usize = 0;
    while (i < ysize) : (i += 1) {
        _ = f.?.write(buf[i * wrap ..][0..xsize]) catch @panic("f.write failed");
    }
}
