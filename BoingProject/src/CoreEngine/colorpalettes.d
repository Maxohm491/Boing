module Engine.colors;

struct RGB {
    ubyte r, g, b;
}

immutable ubyte[3][RGB] colorReplacementMap = [
    RGB(245, 213, 5): [0, 0, 0], // background
    RGB(0, 0, 74): [62, 39, 49], // 1
    RGB(41, 41, 255): [115, 62, 57], // 2
    RGB(0, 255, 187): [184, 111, 80], // 3
    RGB(20, 222, 238): [228, 166, 114], // 4
];
