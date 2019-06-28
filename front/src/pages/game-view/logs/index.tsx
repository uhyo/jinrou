import * as React from 'react';
import { observer, Observer } from 'mobx-react';
import { Log, LogVisibility, maxLogsInGrid } from '../defs';
import { Rule } from '../../../defs';

import { OneLog } from './log';
import { StoredLog, LogStore } from './log-store';
import { mapReverse } from '../../../util/map-reverse';
import { I18n } from '../../../i18n';
import {
  LogWrapper,
  FixedSizeChunkWrapper,
  PendingLogMessage,
} from './elements';
import { LogsRenderingState } from './store';
import { toJS } from 'mobx';

export interface IPropLogs {
  /**
   * All logs.
   */
  logs: LogStore;
  /**
   * Visibility of logs.
   */
  visibility: LogVisibility;
  /**
   * Picked-up user id.
   */
  logPickup: string | null;
  /**
   * Icons of users.
   */
  icons: Record<string, string | undefined>;
  /**
   * Current rule setting.
   */
  rule: Rule | undefined;
  /**
   * Callback for resetting log pickup filter.
   */
  onResetLogPickup(): void;
}

export interface IStateLogs {
  renderingState: LogsRenderingState;
}

/**
 * Shows all logs.
 */
@observer
export class Logs extends React.Component<IPropLogs, IStateLogs> {
  /**
   * Classname attached to each log.
   */
  private readonly logClass = 'jf-log';
  constructor(props: IPropLogs) {
    super(props);
    this.state = {
      // what if logs is updated?
      // (getDerivedStateFromProps)
      renderingState: new LogsRenderingState(this.props.logs),
    };
  }
  public componentDidUpdate(prevProps: IPropLogs) {
    if (!prevProps.logs.loaded && this.props.logs.loaded) {
      this.state.renderingState.reset(this.props.logs.allLogNumber);
    }
  }
  public componentWillUnmount() {
    this.state.renderingState.dispose();
  }
  public render() {
    const {
      logs,
      rule,
      icons,
      visibility,
      logPickup,
      onResetLogPickup,
    } = this.props;
    const { renderingState } = this.state;

    if (!logs.loaded) {
      return null;
    }

    const fixedSize = logs.allLogNumber > maxLogsInGrid;
    /*
     * number of logs to render (not pending).
     */
    const renderedLogs = logs.allLogNumber - renderingState.pendingLogNumber;

    let renderedLogCount = 0;
    return (
      <LogWrapper
        logPickup={logPickup}
        logClass={this.logClass}
        fixedSize={fixedSize}
        onClick={onResetLogPickup}
      >
        {mapReverse(logs.chunks, (chunk, i) => {
          // Decide whether this chunk should be shown.
          const visible =
            visibility.type === 'all' ||
            (visibility.type === 'today'
              ? i === logs.chunks.length - 1
              : chunk.day === visibility.day);

          // number of logs in this chunk
          // which should be rendered.
          const chunkRenderedLogs = Math.max(
            0,
            Math.min(chunk.logs.length, renderedLogs - renderedLogCount),
          );
          renderedLogCount += chunk.logs.length;
          return (
            <LogChunk
              key={chunk.day}
              logClass={this.logClass}
              logs={chunk.logs}
              renderedNumber={chunkRenderedLogs}
              visible={visible}
              fixedSize={fixedSize}
              icons={icons}
              rule={rule}
            />
          );
        })}
        {renderingState.pendingLogNumber > 0 ? (
          <PendingLogMessage>読み込み中...</PendingLogMessage>
        ) : null}
      </LogWrapper>
    );
  }
}

/**
 * Show chunk of logs.
 */
class LogChunk extends React.Component<
  {
    /**
     * Class attached to each log.
     */
    logClass: string;
    /**
     * Logs to render.
     */
    logs: StoredLog[];
    /**
     * Whether this chunk is visible.
     */
    visible: boolean;
    /**
     * Whether logs are rendered in fixed-size mode.
     */
    fixedSize: boolean;
    /**
     * Number of logs to render.
     */
    renderedNumber: number;
    /**
     * Icon of each user.
     */
    icons: Record<string, string | undefined>;
    /**
     * Current rule.
     */
    rule: Rule | undefined;
  },
  {}
> {
  public render() {
    const {
      logClass,
      logs,
      visible,
      fixedSize,
      renderedNumber,
      rule,
      icons,
    } = this.props;
    if (!visible && !fixedSize) {
      return null;
    }
    const logsToRender =
      renderedNumber >= logs.length
        ? logs
        : renderedNumber > 0
          ? logs.slice(-renderedNumber)
          : [];

    const chunkContent = (
      <I18n namespace="game_client">
        {t => (
          <Observer>
            {() =>
              mapReverse(logsToRender, log => {
                return (
                  <OneLog
                    key={`${log.time}-${(log as any).comment || ''}`}
                    t={t}
                    logClass={logClass}
                    fixedSize={fixedSize}
                    log={log}
                    rule={rule}
                    icons={icons}
                  />
                );
              })
            }
          </Observer>
        )}
      </I18n>
    );
    if (fixedSize) {
      return (
        <FixedSizeChunkWrapper visible={visible}>
          {chunkContent}
        </FixedSizeChunkWrapper>
      );
    } else {
      return chunkContent;
    }
  }
}
