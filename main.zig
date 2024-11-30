const std = @import("std");

const Suits = enum(u3) {
    Hearts,
    Spades,
    Clubs,
    Diamonds,
};

const Card = struct {
    suit: Suits,
    value: u4,

    pub fn print(self: Card) void {
        switch (self.value) {
            1 => std.debug.print("Ace of {s}\n", .{@tagName(self.suit)}),
            11 => std.debug.print("Jack of {s}\n", .{@tagName(self.suit)}),
            12 => std.debug.print("Queen of {s}\n", .{@tagName(self.suit)}),
            13 => std.debug.print("King of {s}\n", .{@tagName(self.suit)}),
            else => std.debug.print("{d} of {s}\n", .{ self.value, @tagName(self.suit) }),
        }
    }
};

var deck: [52]Card = undefined;

pub fn main() void {
    for (0..4) |s| {
        var v: u4 = 0;
        while (v < 13) : (v += 1) {
            deck[13 * s + v] = Card{
                .suit = switch (s) {
                    0 => Suits.Hearts,
                    1 => Suits.Spades,
                    2 => Suits.Clubs,
                    3 => Suits.Diamonds,
                    else => unreachable,
                },
                .value = v + 1,
            };
        }
    }
    for (deck) |card| {
        card.print();
    }
}
