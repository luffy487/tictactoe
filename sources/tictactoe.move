module tictactoe::tictactoe;

public struct Game has key {
    id: UID,
    board: vector<vector<u64>>,
    turn: address,
    x: address,
    o: address,
    completed: bool,
}

const MARK_EMPTY: u64 = 0;
const MARK_X: u64 = 1;
const MARK_O: u64 = 2;

const WINNING_COMBINATIONS: vector<vector<vector<u64>>> = vector[
    vector[vector[0, 0], vector[0, 1], vector[0, 2]],
    vector[vector[1, 0], vector[1, 1], vector[1, 2]],
    vector[vector[2, 0], vector[2, 1], vector[2, 2]],
    vector[vector[0, 0], vector[1, 0], vector[2, 0]],
    vector[vector[0, 1], vector[1, 1], vector[2, 1]],
    vector[vector[0, 2], vector[1, 2], vector[2, 2]],
    vector[vector[0, 0], vector[1, 1], vector[2, 2]],
    vector[vector[0, 2], vector[1, 1], vector[2, 0]],
];

#[error]
const UnauthorizedAccess: vector<u8> = b"You can't access the game";

#[error]
const TwoPlayersCantBeSame: vector<u8> = b"Two players can't be same";

#[error]
const NotYourTurn: vector<u8> = b"It's not your turn in the game";

#[error]
const AlreadyMarked: vector<u8> = b"The combition is already marked";

#[error]
const InvalidRowOrColumn: vector<u8> = b"Row and column should be less than or equal 2";

#[error]
const GameAlreadyEnded: vector<u8> = b"Game already ended, you can't make any moves now";

public fun create_game(x: address, o: address, ctx: &mut TxContext) {
    assert!(x != o, TwoPlayersCantBeSame);
    transfer::share_object(Game {
        id: object::new(ctx),
        board: vector[
            vector[MARK_EMPTY, MARK_EMPTY, MARK_EMPTY],
            vector[MARK_EMPTY, MARK_EMPTY, MARK_EMPTY],
            vector[MARK_EMPTY, MARK_EMPTY, MARK_EMPTY],
        ],
        turn: x,
        x: x,
        o: o,
        completed: false,
    });
}

public fun make_move(game: &mut Game, row: u64, col: u64, ctx: &mut TxContext) {
    assert!(game.x == ctx.sender() || game.o == ctx.sender(), UnauthorizedAccess);
    assert!(game.turn == ctx.sender(), NotYourTurn);
    assert!(row <= 2 && col <=2, InvalidRowOrColumn);
    assert!(!game.completed, GameAlreadyEnded);
    let row_vector: &mut vector<u64> = vector::borrow_mut(&mut game.board, row);

    assert!(vector::borrow_mut(row_vector, col) == MARK_EMPTY, AlreadyMarked);

    *vector::borrow_mut(row_vector, col) = if (game.turn == game.x) {
            MARK_X
        } else {
            MARK_O
        };
    if (check_winner(game)) {
        game.completed = true;
    } else {
        game.turn = if (game.turn == game.x) {
                game.o
            } else {
                game.x
            };
    }
}

public fun check_winner(game: &Game): bool {
    check_combinations(&WINNING_COMBINATIONS, game, 0)
}

fun check_combinations(combinations: &vector<vector<vector<u64>>>, game: &Game, index: u64): bool {
    if (index >= vector::length(combinations)) {
        return false;
    };

    let combination = vector::borrow(combinations, index);
    let comb1 = vector::borrow(combination, 0);
    let comb2 = vector::borrow(combination, 1);
    let comb3 = vector::borrow(combination, 2);

    let val1 = vector::borrow(vector::borrow(&game.board, comb1[0]), comb1[1]);
    let val2 = vector::borrow(vector::borrow(&game.board, comb2[0]), comb2[1]);
    let val3 = vector::borrow(vector::borrow(&game.board, comb3[0]), comb3[1]);

    if (*val1 == *val2 && *val2 == *val3 && *val1 != MARK_EMPTY) {
        return true;
    };

    check_combinations(
        combinations,
        game,
        index + 1,
    )
}
