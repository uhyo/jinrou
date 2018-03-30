import * as React from 'react';
import { observer } from 'mobx-react';
import { Log, LogVisibility } from '../defs';

import { OneLog } from './log';

export interface IPropLogs {
  logs: Log[];
  visibility: LogVisibility;
}
/**
 * Shows all logs.
 */
@observer
export class Logs extends React.PureComponent<IPropLogs, {}> {
  public render() {
    const { logs } = this.props;
    // MobX observable array returns a reversed copy of original array.
    const rev = logs.reverse();
    return (
      <div>
        {rev.map((log, i) => {
          return <OneLog key={i} log={log} />;
        })}
      </div>
    );
  }
}
