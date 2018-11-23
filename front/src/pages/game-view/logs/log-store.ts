import { observable, action, computed } from 'mobx';
import { Log, LogVisibility } from '../defs';

/**
 * Log with additional information
 */
export type StoredLog = Log & {
  /**
   * Id of log which is unique.
   */
  logid: number;
  /**
   * Day of this log.
   */
  day: number;
};

/**
 * Chunk of logs by day.
 */
export interface LogChunk {
  day: number;
  logs: StoredLog[];
}

/**
 * Store of logs.
 */
export class LogStore {
  @observable
  public chunks: LogChunk[] = [
    {
      day: 1,
      logs: [],
    },
  ];
  /**
   * Whether initial log is loaded.
   */
  @observable
  public loaded: boolean = false;
  /**
   * Current day of log.
   */
  private currentDay: number = 1;
  /**
   * Last id of log.
   */
  private lastLogId = 0;

  /**
   * Number of all logs.
   */
  @computed
  public get allLogNumber(): number {
    return this.chunks.reduce((total, chunk) => total + chunk.logs.length, 0);
  }

  /**
   * Add a log to the store.
   */
  @action
  public addLog(log: Log): void {
    // If log is a nextturn log, update current day.
    if (log.mode === 'nextturn' && !log.finished && !log.night) {
      this.currentDay = log.day;
      this.chunks.push({
        day: this.currentDay,
        logs: [],
      });
    }
    // current chunk of logs.
    const chunk: LogChunk = this.chunks[this.chunks.length - 1];

    // Id log log is its index in the logs array.
    const logid = ++this.lastLogId;
    const stored: StoredLog = {
      ...log,
      logid,
      day: this.currentDay,
    };
    chunk.logs.push(stored);
  }
  /**
   * Reset logs.
   */
  @action
  public reset(): void {
    this.chunks = [
      {
        day: 1,
        logs: [],
      },
    ];
  }
  /**
   * Reset logs with initial data.
   */
  @action
  public initializeLogs(logs: Log[]): void {
    this.reset();
    this.loaded = true;
    for (const l of logs) {
      this.addLog(l);
    }
  }
  /**
   * Iterate over all logs.
   */
  public *iterateLogs(visibility?: LogVisibility): IterableIterator<StoredLog> {
    if (visibility == null || visibility.type === 'all') {
      // Iterate all logs.
      for (const chunk of this.chunks) {
        yield* chunk.logs;
      }
      return;
    }
    if (visibility.type === 'one') {
      // Iterate over a chunk.
      for (const chunk of this.chunks) {
        if (chunk.day < visibility.day) {
          continue;
        } else if (chunk.day > visibility.day) {
          break;
        }
        yield* chunk.logs;
      }
      return;
    }
    // today
    yield* this.chunks[this.chunks.length - 1].logs;
  }
}
