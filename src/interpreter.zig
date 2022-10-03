const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

pub const Interpreter = struct
{
    memory: [30000]u8,
    lineLengths: ArrayList(u32),
    program: []const u8,

    pub fn init(program: []const u8, allocator: Allocator) Interpreter
    {
        var result = Interpreter{
            .memory = [_]u8{0} ** 30000,
            .lineLengths = ArrayList(u32).init(allocator),
            .program = program
        };

        result.countLineLengths();

        return result;
    }

    pub fn deinit(self: *Interpreter) void
    {
        self.lineLengths.deinit();
    }

    fn countLineLengths(self: *Interpreter) void
    {
        assert(self.lineLengths.items.len == 0);
        var currLength: u32 = 0;
        for (self.program) |char|
        {
            currLength += 1;

            if (char == '\n')
            {
                self.lineLengths.append(currLength) catch |err|
                {
                    std.debug.print("Unable to allocate memory for line {d} {s}\n",.{self.lineLengths.items.len, err});
                };
                currLength = 0;
            }
        }
        
        if (currLength > 0)
        {
            self.lineLengths.append(currLength) catch |err|
            {
                std.debug.print("Unable to allocate memory for line {d} {s}\n",.{self.lineLengths.items.len, err});
            };
        }
    }

    pub fn run(self: *Interpreter) void
    {
        var curr: u32 = 0;
        var brackets: i32 = 0;
        var data_pointer: u32 = 0;

        while (true)
        {
            const char = self.program[data_pointer];

            if (char == '[')
            {
                brackets += 1;

                while (self.program[data_pointer] != ']' and self.program[data_pointer] != 0)
                {
                    data_pointer += 1;
                }

                if (self.program[data_pointer] == 0)
                {
                    std.debug.print("Expected ']'", .{});
                    return;
                }
            }
            else if (char == ']')
            {
                brackets -= 1;

                if (brackets < 0)
                {
                    const location = self.getFileLocation(curr);
                    std.debug.print("Unexpected '[' at line {d} col {d}\n",.{location.?.line, location.?.column});
                }

                while (self.program[data_pointer] != '[' and data_pointer != 0)
                {
                    data_pointer -= 1;
                }

                if (self.program[data_pointer] != '[')
                {
                    return;
                }
            }
        }

        if (brackets != 0)
        {
            const location = self.getFileLocation(curr);
            std.debug.print("Unexpected '[' at line {d} col {d}\n",.{location.?.line, location.?.column});
        }
    }

    const FileLocation = struct
    {
        line: u32,
        column: u32,
    };

    fn getFileLocation(self: *Interpreter, index: u32) ?FileLocation
    {
        var location = FileLocation{.line=0,.column=index};

        for (self.lineLengths.items) |length|
        {
            if (location.column >= length)
            {
                location.column -= length;
                location.line += 1;
            }
            else
            {
                return location;
            }
        }

        return null;
    }
};

const testing = std.testing;
const test_allocator = testing.allocator;


test "Interpreter Init" {
    const test_str = "abc\ndef\n";
    var test_interpreter = Interpreter.init(test_str, test_allocator);
    defer test_interpreter.deinit();
    try testing.expect(test_interpreter.lineLengths.items.len == 2);
    try testing.expect(test_interpreter.lineLengths.items[0] == 4);
    try testing.expect(test_interpreter.lineLengths.items[1] == 4);
}

test "Interpreter getFileLocation" {
    const test_str = "abc\ndef\n";
    var test_interpreter = Interpreter.init(test_str, test_allocator);
    defer test_interpreter.deinit();

    const columns = [_]u32{0, 1, 2, 3, 0, 1, 2, 3};
    const lines = [_]u32{0, 0, 0, 0, 1, 1, 1, 1};
    try testing.expect(columns.len == lines.len);
    
    
    var i:u32 = 0;
    while(i < test_str.len) :  (i+= 1)
    {
        const location = test_interpreter.getFileLocation(i);
        var failed = false;
        testing.expect(location != null) catch {
            failed = true;
        };
        testing.expect(location.?.line ==  lines[i]) catch {
            failed = true;
        };
        testing.expect(location.?.column == columns[i]) catch {
            failed = true;
        };

        if (!failed)
        {
            continue;
        }
        
        if (location == null)
        {
            std.debug.print("ix {d} \"{c}\" => null\n", .{i, test_str[i]});
        }
        else
        {
            std.debug.print("ix {d} \"{c}\" => line: {d} column: {d}\n", .{i, test_str[i], location.?.line, location.?.column});
        }
    }
}