const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;


pub const TestType = struct {
    list: ArrayList(u32),

    pub fn init(allocator: Allocator) TestType
    {
        var result =  TestType{.list=ArrayList(u32).init(allocator)};

        _ = result.list.append(20) catch null;

        return result;
    }

    pub fn deinit(self: TestType) void
    {
        self.list.deinit();
    }
};


const testing = std.testing;
const test_allocator = testing.allocator;

test "TestType init" {
    var test_type = TestType.init(test_allocator);
    defer test_type.deinit();
    try testing.expect(test_type.list.items[0] == 20);
}