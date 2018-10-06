import { observer } from 'mobx-react';
import { i18n } from '../../i18n';
import { ServerConnectionStore } from './store';
import { Transition } from 'react-transition-group';
import { duration } from './def';
import * as React from 'react';
import { Wrapper } from './elements';

/**
 * Component which shows indicator when server connection is lost.
 */
@observer
export class ServerConnection extends React.Component<
  {
    i18n: i18n;
    store: ServerConnectionStore;
  },
  {}
> {
  public render() {
    const {
      i18n,
      store: { connection },
    } = this.props;
    return (
      <Transition timeout={duration} in={!connection} appear>
        {(state: string) => (
          <Wrapper open={state === 'entering' || state === 'entered'}>
            <p>
              <strong>
                {i18n.t(
                  `server_connection_client:${
                    connection ? 'connected' : 'unconnected'
                  }`,
                )}
              </strong>
            </p>
          </Wrapper>
        )}
      </Transition>
    );
  }
}
