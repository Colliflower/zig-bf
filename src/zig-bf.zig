const std = @import("std");
const util = @import("util.zig");
const Interpreter = @import("interpreter.zig").Interpreter;
const fs = std.fs;
const Allocator = std.mem.Allocator;

const MAX_FILE_SIZE_IN_BYTES = 0x40000000; // 1 GB

pub fn main() void
{    
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const filepath = util.GetFilenameFromArgs(allocator);

    if (filepath == null)
    {
        std.debug.print("Unable to fetch filepath.\n", .{});
        return;
    }
    
    std.debug.print("Parsing file: \"{s}\"\n", .{filepath.?});

    const file = OpenFileFromPath(filepath.?);

    if (file == null)
    {
        return;
    }

    const contents = file.?.readToEndAlloc(allocator, MAX_FILE_SIZE_IN_BYTES) catch |err|
    {
        std.debug.print("Error: {s}",.{err});
        return;
    };
    
    var bf_interpreter: Interpreter = Interpreter.init(contents, allocator);

    bf_interpreter.run();
}

pub fn OpenFileFromPath(filepath: []u8 ) ?fs.File
{
    const dirname = fs.path.dirname(filepath);
    const filename = fs.path.basename(filepath);

    const dir: ?fs.Dir = 
    if (dirname != null and fs.path.isAbsolute(dirname.?))
        fs.openDirAbsolute(dirname.?, .{}) catch null
    else if (dirname != null)
        fs.cwd().openDir(dirname.?, .{}) catch null
    else
        fs.cwd();

    if (dir == null)
    {
        std.debug.print("Unable to access file directory for {s}.\n", .{filepath});
        return null;
    }

    const openFlags = fs.File.OpenFlags
    {
        .lock = fs.File.Lock.Shared
    };
    
    const file = dir.?.openFile(filename, openFlags) catch null;

    if (file == null)
    {
        std.debug.print("Unable to open file {s}.\n", .{filepath});
        return null;
    }

    return file;
}