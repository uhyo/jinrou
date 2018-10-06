import { observable, action } from 'mobx';

/**
 * Store of current server connection.
 */
export class ServerConnectionStore {
  /**
   * Whether server connection is currently on.
   */
  @observable public connection: boolean = true;

  /**
   * Set current connection state.
   */
  @action
  public setConnection(connection: boolean) {
    this.connection = connection;
  }
}
