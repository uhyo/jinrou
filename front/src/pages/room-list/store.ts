import { observable, action, computed } from 'mobx';
import { Room, RoomListMode } from './defs';

/**
 * States of room list page.
 * @package
 */
export class RoomListStore {
  constructor(private pageNumber: number, mode: RoomListMode) {
    this.mode = mode;
  }
  /**
   * List of rooms.
   */
  @observable
  public rooms: Room[] = [];
  /**
   * Number of page.
   */
  @observable
  public page: number = 0;
  /**
   * Current mode of list.
   */
  @observable
  public mode: RoomListMode;

  /**
   * Whether previous page is available.
   */
  @computed
  get prevAvailable(): boolean {
    return this.page > 0;
  }
  /**
   * Whether next page is available.
   */
  @computed
  get nextAvailable(): boolean {
    // XXX this has false positive
    return this.rooms.length >= this.pageNumber;
  }
  /**
   * Set rooms and page
   */
  @action
  public setRooms(rooms: Room[], page: number): void {
    this.rooms = rooms;
    this.page = page;
  }
}
