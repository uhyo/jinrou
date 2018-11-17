import * as React from 'react';
import styled, { css } from '../../../util/styled';
import { observer, Observer } from 'mobx-react';
import { Log, LogVisibility } from '../defs';
import { Rule } from '../../../defs';

import { OneLog } from './log';
import { assertNever } from '../../../util/assert-never';
import { StoredLog, LogStore } from './log-store';
import { mapReverse } from '../../../util/map-reverse';
import { withProps } from '../../../util/styled';
import { phone } from '../../../common/media';
import { I18n } from '../../../i18n';

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
    if (!visible) {
      return null;
    }
    return (
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
  }
}

const LogWrapper = withProps<{
  logClass: string;
  logPickup: string | null;
}>()(styled.div)`
  width: 100%;
  display: grid;
  grid-template-columns:
    minmax(8px, max-content)
    fit-content(10em)
    1fr
    auto;
  ${({ logClass, logPickup }) =>
    // logPickup should not contain `"` because it is an user id.
    // XXX safer solution?
    logPickup != null
      ? css`
    .${logClass}:not([data-userid="${logPickup}"]) > * {
      opacity: 0.3;
    }
  `
      : ''}

  --base-font-size: 1rem;
  ${phone`
    grid-template-columns:
      minmax(8px, max-content)
      1fr
      auto;
    grid-auto-flow: row dense;
    --base-font-size: 0.88rem;
  `}

`;
