const std = @import("std");
const Random = std.Random;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

var prng = Random.DefaultPrng.init(0);
const r = prng.random();

const Suits = enum(u3) {
    Hearts,
    Clubs,
    Diamonds,
    Spades,
};

const Card = struct {
    suit: Suits,
    value: u4,

    /// Returns an Arraylist(u8) containing the string representation of the card or an error
    /// Takes a card and an allocator
    pub fn toString(self: Card, allocator: std.mem.Allocator) !std.ArrayList(u8) {
        var string = std.ArrayList(u8).init(allocator);
        switch (self.value) {
            1 => try string.writer().print("{s} of {s}\n", .{ "A", @tagName(self.suit) }),
            11 => try string.writer().print("{s} of {s}\n", .{ "J", @tagName(self.suit) }),
            12 => try string.writer().print("{s} of {s}\n", .{ "Q", @tagName(self.suit) }),
            13 => try string.writer().print("{s} of {s}\n", .{ "K", @tagName(self.suit) }),
            else => try string.writer().print("{d} of {s}\n", .{ self.value, @tagName(self.suit) }),
        }
        return string;
    }
};

pub fn main() !void {
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("leaked oh no");
    }

    var stdout = std.io.getStdOut();
    var stdin = std.io.getStdIn().reader();

    // Setup Deck
    var deck = std.ArrayList(Card).init(
        allocator,
    );
    defer deck.deinit();

    newDeck(&deck) catch @panic("Failed to Create Deck");

    // Shuffle
    r.shuffle(Card, deck.items);

    while (deck.popOrNull()) |card| {
        const cardList = try card.toString(allocator);
        defer cardList.deinit();

        const string = cardList.items;

        try stdout.writeAll(string);

        const rawLine = try stdin.readUntilDelimiterAlloc(allocator, '\n', 8192);
        defer allocator.free(rawLine);
        const line = std.mem.trim(u8, rawLine, "\r");
        _ = line;
    }
}

pub fn newDeck(deck: *std.ArrayList(Card)) !void {
    for (0..4) |s| {
        var v: u4 = 0;
        while (v < 13) : (v += 1) {
            try deck.append(Card{
                .suit = switch (s) {
                    0 => Suits.Hearts,
                    1 => Suits.Clubs,
                    2 => Suits.Diamonds,
                    3 => Suits.Spades,
                    else => unreachable,
                },
                .value = v + 1,
            });
        }
    }
}
