import { observable, action, when } from 'mobx';
import { LogStore } from './log-store';

/**
 * Number of logs initially rendered.
 */
const initialLogNumber = 50;

/**
 * Number of logs rendered in one period.
 */
const periodLogNumber = 100;

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
  /**
   * Handle of ongoing rendering task.
   */
  private renderingHandle: number | null = null;

  constructor(private logState: LogStore) {
    when(() => logState.loaded, () => this.startRendering());
  }
  /**
   * Reset pending log number.
   */
  @action
  public reset(logNumber: number) {
    this.pendingLogNumber = Math.max(0, logNumber - initialLogNumber);
  }
  /**
   * Dispose ongoing task to render.
   */
  public dispose() {
    if (this.renderingHandle != null) {
      cancelIdleCallback(this.renderingHandle);
    }
  }
  /**
   * Start the rendering logic.
   */
  private startRendering() {
    this.countLogs();
    // register tasks to render others.
    this.registerNextRenderingTask();
  }
  private registerNextRenderingTask() {
    if (this.pendingLogNumber === 0) {
      // nothing to render anymore.
      return;
    }
    this.renderingHandle = requestIdleCallback(() => {
      this.renderForward();
      this.registerNextRenderingTask();
    });
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
   * Decrease number of pending logs.
   */ @action
  private renderForward() {
    this.pendingLogNumber = Math.max(
      0,
      this.pendingLogNumber - periodLogNumber,
    );
  }
}
