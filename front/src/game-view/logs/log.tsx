import * as React from 'react';
import { Log } from '../defs';

export interface IPropOneLog {
  log: Log;
}

export function OneLog({ log }: IPropOneLog): JSX.Element {
  if (log.mode === 'voteresult') {
    return <div>voteresult</div>;
  } else {
    return <div>{log.comment}</div>;
  }
}
