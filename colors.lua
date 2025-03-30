TerminalColors = {
    {0/3,0/3,0/3},
    {0/3,0/3,2/3},
    {0/3,2/3,0/3},
    {0/3,2/3,2/3},
    {2/3,0/3,0/3},
    {2/3,0/3,2/3},
    {2/3,2/3,0/3},
    {2/3,2/3,2/3},
    {1/3,1/3,1/3},
    {1/3,1/3,3/3},
    {1/3,3/3,1/3},
    {1/3,3/3,3/3},
    {3/3,1/3,1/3},
    {3/3,1/3,3/3},
    {3/3,3/3,1/3},
    {3/3,3/3,3/3}
}

-- TerminalColors = {
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3},
--     {3/3,3/3,3/3}
-- }

ColorID = {
    BLACK = 1,
    BLUE = 2,
    GREEN = 3,
    CYAN = 4,
    RED = 5,
    PURPLE = 6,
    GOLD = 7,
    LIGHT_GRAY = 8,
    DARK_GRAY = 9,
    LIGHT_BLUE = 10,
    LIGHT_GREEN = 11,
    AQUA = 12,
    LIGHT_RED = 13,
    MAGENTA = 14,
    YELLOW = 15,
    WHITE = 16
}

ColorTransitionTable = {
    [ColorID.BLACK]       = {ColorID.BLACK, ColorID.BLACK,      ColorID.BLACK,       ColorID.WHITE},
    [ColorID.BLUE]        = {ColorID.BLACK, ColorID.BLUE,       ColorID.BLUE,        ColorID.WHITE},
    [ColorID.GREEN]       = {ColorID.BLACK, ColorID.GREEN,      ColorID.GREEN,       ColorID.WHITE},
    [ColorID.CYAN]        = {ColorID.BLACK, ColorID.CYAN,       ColorID.CYAN,        ColorID.WHITE},
    [ColorID.RED]         = {ColorID.BLACK, ColorID.RED,        ColorID.RED,         ColorID.WHITE},
    [ColorID.PURPLE]      = {ColorID.BLACK, ColorID.PURPLE,     ColorID.PURPLE,      ColorID.WHITE},
    [ColorID.GOLD]        = {ColorID.BLACK, ColorID.GOLD,       ColorID.GOLD,        ColorID.WHITE},
    [ColorID.LIGHT_GRAY]  = {ColorID.BLACK, ColorID.DARK_GRAY,  ColorID.LIGHT_GRAY,  ColorID.WHITE},
    [ColorID.DARK_GRAY]   = {ColorID.BLACK, ColorID.DARK_GRAY,  ColorID.DARK_GRAY,   ColorID.WHITE},
    [ColorID.LIGHT_BLUE]  = {ColorID.BLACK, ColorID.BLUE,       ColorID.LIGHT_BLUE,  ColorID.WHITE},
    [ColorID.LIGHT_GREEN] = {ColorID.BLACK, ColorID.GREEN,      ColorID.LIGHT_GREEN, ColorID.WHITE},
    [ColorID.AQUA]        = {ColorID.BLACK, ColorID.CYAN,       ColorID.AQUA,        ColorID.WHITE},
    [ColorID.LIGHT_RED]   = {ColorID.BLACK, ColorID.RED,        ColorID.LIGHT_RED,   ColorID.WHITE},
    [ColorID.MAGENTA]     = {ColorID.BLACK, ColorID.PURPLE,     ColorID.MAGENTA,     ColorID.WHITE},
    [ColorID.YELLOW]      = {ColorID.BLACK, ColorID.GOLD,       ColorID.YELLOW,      ColorID.WHITE},
    [ColorID.WHITE]       = {ColorID.BLACK, ColorID.LIGHT_GRAY, ColorID.WHITE,       ColorID.WHITE}
}

NoteColors = {
    {ColorID.BLACK,ColorID.RED,ColorID.LIGHT_RED,ColorID.WHITE},
    {ColorID.BLACK,ColorID.GOLD,ColorID.YELLOW,ColorID.WHITE},
    {ColorID.BLACK,ColorID.GREEN,ColorID.LIGHT_GREEN,ColorID.WHITE},
    {ColorID.BLACK,ColorID.BLUE,ColorID.LIGHT_BLUE,ColorID.WHITE},
    {ColorID.BLACK,ColorID.PURPLE,ColorID.MAGENTA,ColorID.WHITE},
    {ColorID.BLACK,ColorID.CYAN,ColorID.AQUA,ColorID.WHITE},
    {ColorID.BLACK,ColorID.DARK_GRAY,ColorID.LIGHT_GRAY,ColorID.WHITE},
    {ColorID.BLACK,ColorID.LIGHT_GRAY,ColorID.WHITE,ColorID.WHITE}
}

OverchargeColors = {
    ColorID.RED,
    ColorID.GOLD,
    ColorID.YELLOW,
    ColorID.GREEN,
    ColorID.LIGHT_BLUE,
    ColorID.PURPLE
}