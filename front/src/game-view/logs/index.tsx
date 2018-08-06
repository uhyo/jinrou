import * as React from 'react';
import styled, { css } from 'styled-components';
import { observer } from 'mobx-react';
import { Log, LogVisibility } from '../defs';
import { Rule } from '../../defs';

import { OneLog } from './log';
import { assertNever } from '../../util/assert-never';
import { StoredLog, LogStore } from './log-store';
import { mapReverse } from '../../util/map-reverse';
import { withProps } from '../../util/styled';

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

    return (
      <LogWrapper
        logPickup={logPickup}
        logClass={this.logClass}
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
@observer
class LogChunk extends React.Component<
  {
    logClass: string;
    logs: StoredLog[];
    visible: boolean;
    icons: Record<string, string | undefined>;
    rule: Rule | undefined;
  },
  {}
> {
  public render() {
    const { logClass, logs, visible, rule, icons } = this.props;
    return (
      <ChunkWrapper visible={visible}>
        {mapReverse(logs, log => {
          return (
            <OneLog
              key={`${log.time}-${(log as any).comment || ''}`}
              logClass={logClass}
              log={log}
              rule={rule}
              icons={icons}
            />
          );
        })}
      </ChunkWrapper>
    );
  }
}

const LogWrapper = withProps<{
  logClass: string;
  logPickup: string | null;
}>()(styled.div)`
  width: 100%;
  display: table;

  ${({ logClass, logPickup }) =>
    logPickup != null
      ? css`
    .${logClass}:not([data-userid=${logPickup}]) {
      opacity: 0.3;
    }
  `
      : ''}
`;

const ChunkWrapper = withProps<{ visible: boolean }>()(styled.div)`
  display: ${props => (props.visible ? 'table-row-group' : 'none')}
`;
