export enum CellType {
  Start,
  End,
  Wall,
  Path,
  Visited,
  CorrectPath,
}

export type Grid = CellType[][];

export type AnimationStep = {
  row: number;
  col: number;
  type: CellType;
};
