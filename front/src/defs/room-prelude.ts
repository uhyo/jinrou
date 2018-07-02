/**
 * Set of handlers related to room prelude controls.
 */
export interface RoomPreludeHandlers {
  /**
   * Handler for room entry.
   * @param user Data of user when the room is blind.
   */
  join(user: { name: string; icon: string | null }): void;
  /**
   * Handler for room leave.
   */
  unjoin(): void;
  /**
   * Handler for ready/unready button.
   */
  ready(): void;
  /**
   * Handler for helper button.
   */
  helper(userid: string | null): void;
  /**
   * Open game start button.
   */
  openGameStart(): void;
  /**
   * kick button.
   */
  kick(): void;
  /**
   * Reset everyone's ready button.
   */
  resetReady(): void;
  /**
   * Room discard button.
   */
  discard(): void;
}
