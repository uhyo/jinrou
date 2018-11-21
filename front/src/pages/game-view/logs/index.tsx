import * as React from 'react';
import { observer, Observer } from 'mobx-react';
import { Log, LogVisibility, maxLogsInGrid } from '../defs';
import { Rule } from '../../../defs';

import { OneLog } from './log';
import { assertNever } from '../../../util/assert-never';
import { StoredLog, LogStore } from './log-store';
import { mapReverse } from '../../../util/map-reverse';
import { I18n } from '../../../i18n';
import { LogWrapper, FixedSizeChunkWrapper } from './elements';

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
/**
 * Shows all logs.
 */
@observer
export class Logs extends React.Component<IPropLogs, {}> {
  /**
   * Classname attached to each log.
   */
  private readonly logClass = 'jf-log';
  public render() {
    const {
      logs,
      rule,
      icons,
      visibility,
      logPickup,
      onResetLogPickup,
    } = this.props;

    const fixedSize = logs.allLogNumber > maxLogsInGrid;

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
          return (
            <LogChunk
              key={chunk.day}
              logClass={this.logClass}
              logs={chunk.logs}
              visible={visible}
              fixedSize={fixedSize}
              icons={icons}
              rule={rule}
            />
          );
        })}
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
    const { logClass, logs, visible, fixedSize, rule, icons } = this.props;
    if (!visible && !fixedSize) {
      return null;
    }
    const chunkContent = (
      <I18n namespace="game_client">
        {t => (
          <Observer>
            {() =>
              mapReverse(logs, log => {
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
