const std = @import("std");
const process = std.process;
const Allocator = std.mem.Allocator;

pub fn GetFilenameFromArgs(allocator: Allocator) ?[]u8
{
    var argsIterator = process.ArgIteratorWindows.init();
    _ = argsIterator.skip();
    const optional_filepath  = argsIterator.next(allocator);

    if (optional_filepath) |filepath|
    {
        return filepath catch null;
    }
    else
    {
        return null;
    }
}