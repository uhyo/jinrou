import { observer } from 'mobx-react';
import { i18n } from '../../i18n';
import { ServerConnectionStore } from './store';
import { Transition } from 'react-transition-group';
import { duration } from './def';
import * as React from 'react';
import { Wrapper, IconContainer, TextContainer } from './elements';
import { FontAwesomeIcon } from '../../util/icon';
import { bind } from 'bind-decorator';

/**
 * Component which shows indicator when server connection is lost.
 */
@observer
export class ServerConnection extends React.Component<
  {
    i18n: i18n;
    store: ServerConnectionStore;
  },
  {
    /**
     *  whether connection to internet is available
     * (though it just relies on online/offline event)
     */
    internetConnection: boolean;
  }
> {
  state = {
    internetConnection: navigator.onLine,
  };
  public render() {
    const {
      i18n,
      store: { connection, open, delay },
    } = this.props;
    const { internetConnection } = this.state;

    return (
      <Transition timeout={duration} in={open} appear>
        {(state: string) => (
          <Wrapper
            open={state === 'entering' || state === 'entered'}
            delay={delay}
            // give the 'alert' role when connection is lost.
            role={connection ? undefined : 'alert'}
            onClick={this.clickHandler}
          >
            <IconContainer connected={connection}>
              <FontAwesomeIcon
                icon={connection ? 'check' : 'signal'}
                size="3x"
              />
            </IconContainer>
            <TextContainer>
              <p>
                <strong>
                  {i18n.t(
                    `server_connection_client:${
                      connection ? 'connected' : 'unconnected'
                    }`,
                  )}
                </strong>
              </p>
              {connection ? null : (
                <p>
                  {i18n.t(
                    `server_connection_client:${
                      internetConnection ? 'connecting' : 'offline'
                    }`,
                  )}
                </p>
              )}
            </TextContainer>
          </Wrapper>
        )}
      </Transition>
    );
  }
  public componentDidMount() {
    // check online and offline events.
    document.addEventListener('online', this.onlineHandler, false);
    document.addEventListener('offline', this.onlineHandler, false);
  }
  public componentWillUnmount() {
    document.removeEventListener('online', this.onlineHandler, false);
    document.removeEventListener('offline', this.onlineHandler, false);
  }
  @bind
  private clickHandler(): void {
    this.props.store.setUserClosed();
  }
  @bind
  private onlineHandler(e: Event): void {
    this.setState({
      internetConnection: e.type === 'online',
    });
  }
}
