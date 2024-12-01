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

    const stdout = std.io.getStdOut();
    const outWriter = stdout.writer();
    var stdin = std.io.getStdIn().reader();

    // Setup Deck
    var deck = std.ArrayList(Card).init(
        allocator,
    );
    defer deck.deinit();
    newDeck(&deck) catch @panic("Failed to Create Deck");

    // Shuffle
    r.shuffle(Card, deck.items);

    var playerHand = std.ArrayList(Card).init(
        allocator,
    );
    defer playerHand.deinit();

    try dealNext(&deck, &playerHand, allocator, stdout);
    try dealNext(&deck, &playerHand, allocator, stdout);

    while (deck.items.len > 0) {
        const playerHandValue = getHandValue(&playerHand);
        try outWriter.print("Value: {d}\n", .{playerHandValue});
        if (playerHandValue < 21) {
            try outWriter.print("Hit or Stand: ", .{});
        } else if (playerHandValue > 21) {
            try outWriter.print("Bust\n", .{});
            break;
        } else if (playerHandValue == 21) {
            try outWriter.print("BlackJack!\n", .{});
            break;
        }

        const rawinput = try stdin.readUntilDelimiterAlloc(allocator, '\n', 8192);
        defer allocator.free(rawinput);
        const input = std.mem.trim(u8, rawinput, "\r");
        const lowerCaseInput = try toLower(input, allocator);
        defer allocator.free(lowerCaseInput);
        if (std.mem.eql(u8, lowerCaseInput, "hit")) {
            try dealNext(&deck, &playerHand, allocator, stdout);
        } else if (std.mem.eql(u8, lowerCaseInput, "stand")) {
            break;
        }
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

pub fn dealNext(deck: *std.ArrayList(Card), hand: *std.ArrayList(Card), allocator: std.mem.Allocator, stdout: std.fs.File) !void {
    const card = deck.pop();

    try hand.append(card);

    const cardList = try card.toString(allocator);
    defer cardList.deinit();

    const string = cardList.items;

    try stdout.writeAll(string);
}

pub fn getHandValue(hand: *std.ArrayList(Card)) u16 {
    var runningCount: u16 = 0;
    var numAces: u8 = 0;
    const cards = hand.items;
    for (cards) |card| {
        if (card.value == 1) {
            numAces += 1;
        }
        if (card.value >= 10) {
            runningCount += 10;
        } else {
            runningCount += card.value;
        }
    }

    for (0..numAces) |_| {
        if (runningCount + 10 <= 21) {
            runningCount += 10;
        }
    }

    return runningCount;
}

pub fn toLower(string: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const res: []u8 = try allocator.alloc(u8, string.len);
    for (string, 0..) |from, to| {
        res[to] = std.ascii.toLower(from);
    }
    return res;
}
