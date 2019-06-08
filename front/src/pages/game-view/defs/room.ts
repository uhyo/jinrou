/**
 * State of room before starting.
 */
export interface RoomPrelude {
  type: 'prelude';
  /**
   * Whether you are an owner.
   */
  owner: boolean;
  /**
   * Whether you have already joined the room.
   */
  joined: boolean;
  /**
   * Whether this room is old.
   */
  old: boolean;
  /**
   * Whether this room is blind mode.
   */
  blind: boolean;
  /**
   * Whether this room has a theme.
   */
  theme: boolean;
}
/**
 * State of room during endless yaminabe.
 */
export interface RoomDuringEndless {
  type: 'endless';
  /**
   * Whether you have already joined the room.
   */
  joined: boolean;
  /**
   * Whether this room is blind mode.
   */
  blind: boolean;
}
/**
 * State of room after the end.
 */
export interface RoomPostlude {
  type: 'postlude';
}
export type RoomControlInfo = RoomPrelude | RoomDuringEndless | RoomPostlude;
