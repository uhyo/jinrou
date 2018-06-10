import * as React from 'react';
import styled from 'styled-components';
import { observer } from 'mobx-react';
import { Log, LogVisibility } from '../defs';
import { Rule } from '../../defs';
import { i18n } from '../../i18n';

import { OneLog } from './log';
import { assertNever } from '../../util/assert-never';

export interface IPropLogs {
  /**
   * All logs.
   */
  logs: Log[];
  /**
   * Visibility of logs.
   */
  visibility: LogVisibility;
  /**
   * Icons of users.
   */
  icons: Record<string, string | undefined>;
  /**
   * Current rule setting.
   */
  rule: Rule | undefined;
}
/**
 * Shows all logs.
 */
@observer
export class Logs extends React.Component<IPropLogs, {}> {
  public render() {
    const { logs, rule, icons, visibility } = this.props;
    // List of logs to be shown.
    let shownLogs: Log[];
    switch (visibility.type) {
      case 'all': {
        // MobX observable array returns a reversed copy of original array.
        shownLogs = logs.reverse();
        break;
      }
      case 'one': {
        shownLogs = [];
        const vday = visibility.day;
        let day = 1;
        // Filter logs for the day.
        for (const log of logs) {
          if (log.mode === 'nextturn' && !log.finished) {
            if (!log.night) {
              // date is changed.
              day = log.day;
              if (day > vday) {
                // Shown region is passed.
                break;
              }
            }
          }
          if (day === vday) {
            shownLogs.push(log);
          }
        }
        //Reverse the logs so that the newest comes first.
        shownLogs.reverse();
        break;
      }
      case 'today': {
        shownLogs = [];
        // collect logs until the day change log is reached.
        for (const log of logs.reverse()) {
          shownLogs.push(log);
          if (log.mode === 'nextturn' && !log.finished && !log.night) {
            break;
          }
        }
        break;
      }
      default: {
        shownLogs = assertNever(visibility);
      }
    }

    return (
      <LogWrapper>
        {shownLogs.map((log, i) => {
          return <OneLog key={i} log={log} rule={rule} icons={icons} />;
        })}
      </LogWrapper>
    );
  }
}

const LogWrapper = styled.div`
  width: 100%;
  display: table;
`;
