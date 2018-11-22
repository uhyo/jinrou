import { observable, action, when } from 'mobx';
import { LogStore } from './log-store';

/**
 * Number of logs initially rendered.
 */
const initialLogNumber = 5;

/**
 * Store for log rendering management
 */
export class LogsRenderingState {
  /**
   * Number of logs whose rendering is pending.
   * Counts from the beginning (bottom).
   */
  @observable
  public pendingLogNumber: number = 0;
  constructor(private logState: LogStore) {
    when(() => logState.loaded, () => this.countLogs());
  }
  /**
   * Count logs to set number of initially rendered logs.
   */
  @action
  private countLogs() {
    this.pendingLogNumber = Math.max(
      0,
      this.logState.allLogNumber - initialLogNumber,
    );
  }
  /**
   * Reset pending log number.
   */
  @action
  public reset(logNumber: number) {
    this.pendingLogNumber = Math.max(0, logNumber - initialLogNumber);
  }
}
