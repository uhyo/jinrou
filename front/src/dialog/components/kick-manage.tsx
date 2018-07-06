import * as React from 'react';
import { IKickManageDialog } from '../defs';
import { I18n } from '../../i18n';
import { Dialog } from './base';
import { NoButton, YesButton, FormTable, FormControlWrapper } from './parts';
import { bind } from 'bind-decorator';
import { FontAwesomeIcon } from '../../util/icon';

export interface KickManageResult {
  /**
   * List of ids of users removed from kick list.
   */
  remove: string[];
}
export interface IPropKickManageDialog extends IKickManageDialog {
  onSelect(result: KickManageResult | null): void;
}

/**
 * Kick list management dialog.
 */
export class KickManageDialog extends React.PureComponent<
  IPropKickManageDialog,
  {
    /**
     * Whether user data is fetcehd.
     */
    fetched: boolean;
    /**
     * List of kicked user ids.
     */
    users: string[];
  }
> {
  /**
   * Flag which tracks mountedness of this component.
   */
  private mounted: boolean = false;
  public state = {
    fetched: false,
    users: [],
  };
  public render() {
    const { modal } = this.props;
    const { fetched, users } = this.state;

    return (
      <I18n namespace="game_client">
        {t => {
          return (
            <Dialog
              modal={modal}
              title={t('kick.manager.title')}
              message={
                fetched
                  ? users.length > 0
                    ? t('kick.manager.message')
                    : t('kick.manager.empty')
                  : undefined
              }
              onCancel={this.handleCancel}
              buttons={() => (
                <>
                  <NoButton onClick={this.handleCancel}>
                    {t('kick.cancel')}
                  </NoButton>
                  {fetched && users.length > 0 ? (
                    <YesButton onClick={this.handleYesClick}>
                      {t('kick.ok')}
                    </YesButton>
                  ) : null}
                </>
              )}
              contents={() =>
                fetched ? (
                  <>
                    <FormTable>
                      <tbody>
                        {users.map(id => (
                          <tr key={id}>
                            <td>
                              <input type="checkbox" />
                            </td>
                            <td>{id}</td>
                          </tr>
                        ))}
                      </tbody>
                    </FormTable>
                  </>
                ) : (
                  <FormControlWrapper>
                    <FontAwesomeIcon icon="spinner" pulse={true} size="3x" />
                  </FormControlWrapper>
                )
              }
            />
          );
        }}
      </I18n>
    );
  }
  public async componentDidMount() {
    this.mounted = true;
    // Listen for input promise.
    const users = await this.props.users;
    // XXX This is anti-pattern
    if (this.mounted) {
      this.setState({
        fetched: true,
        users,
      });
    }
  }
  public componentWillUnmount() {
    this.mounted = false;
  }
  @bind
  private handleCancel() {
    this.props.onSelect(null);
  }
  @bind
  private handleYesClick() {
    // TODO
  }
}
