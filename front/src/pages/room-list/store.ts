import { observable, action } from 'mobx';
import { Room } from './defs';

/**
 * States of room list page.
 * @package
 */
export class RoomListStore {
  /**
   * List of rooms.
   */
  @observable
  public rooms: Room[] = [];

  /**
   * Set rooms.
   */
  @action
  public setRooms(rooms: Room[]): void {
    this.rooms = rooms;
  }
}
