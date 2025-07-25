module Engine.colors;

struct RGB {
    ubyte r, g, b;
}

// OG Palette
// immutable ubyte[3][RGB] colorReplacementMap = [
//     RGB(245, 213, 5): [0, 0, 0], // background
//     RGB(5, 245, 89): [5, 245, 89], // slime
//     RGB(0, 0, 74): [62, 39, 49], // 1
//     RGB(41, 41, 255): [115, 62, 57], // 2
//     RGB(0, 255, 187): [184, 111, 80], // 3
//     RGB(20, 222, 238): [228, 166, 114], // 4
// ];

// light pink Palette
// immutable ubyte[3][RGB] colorReplacementMap = [
//     RGB(245, 213, 5): [255,176,176], // background
//     RGB(5, 245, 89): [5, 245, 89], // slime
//     RGB(0, 0, 74): [255,195,195], // 1
//     RGB(41, 41, 255): [255,216,216], // 2
//     RGB(0, 255, 187): [255,225,225], // 3
//     RGB(20, 222, 238): [255,225,225], // 4
// ];

// lilac
immutable ubyte[3][RGB] colorReplacementMap = [
    RGB(245, 213, 5): [150,116,220], // background
    RGB(5, 245, 89): [229,208,255], // slime
    RGB(0, 0, 74): [191,139,255], // 1
    RGB(41, 41, 255): [204,163,255], // 2
    RGB(0, 255, 187): [218,188,255], // 3
    RGB(20, 222, 238): [229,208,255], // 4
];
