import { observable, action, computed } from 'mobx';
import { reopenDuration, delay } from './def';

/**
 * Store of current server connection.
 */
export class ServerConnectionStore {
  /**
   * Whether server connection is currently on.
   */
  @observable public connection: boolean = true;
  /**
   * Whether notification is closed by user.
   */
  @observable public closed: boolean = false;
  /**
   * Forced opennness of notification.
   */
  @observable public forcedOpen: boolean = false;
  /**
   * Final state of notification.
   */
  @computed
  public get open(): boolean {
    return this.forcedOpen || (!this.closed && !this.connection);
  }
  /**
   * Computed delay of animation.
   */
  @computed
  public get delay(): number {
    const nodelay = this.forcedOpen || this.closed;
    return nodelay ? 0 : delay;
  }

  /**
   * Set current connection state.
   */
  @action
  public setConnection(connection: boolean) {
    const privConnection = this.connection;
    this.connection = connection;
    if (connection !== privConnection) {
      // reset closedness.
      this.closed = false;
    }
    if (!privConnection && connection) {
      this.forcedOpen = true;
      setTimeout(() => {
        this.forcedOpen = false;
      }, reopenDuration);
    }
  }
  /**
   * Close action by user.
   */
  @action
  public setUserClosed() {
    this.closed = true;
    this.forcedOpen = false;
  }
}
