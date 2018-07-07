import * as React from 'react';
import { IKickManageDialog } from '../defs';
import { I18n } from '../../i18n';
import { Dialog } from './base';
import { NoButton, YesButton, FormTable, FormControlWrapper } from './parts';
import { bind } from 'bind-decorator';
import { FontAwesomeIcon } from '../../util/icon';
import { WithRandomIds } from '../../util/with-ids';
import { map2 } from '../../util/map2';
import { filter2Right } from '../../util/filter2';
import { updateArray } from '../../util/update-array';

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
    /**
     * List of checks.
     */
    checks: boolean[];
  }
> {
  /**
   * Flag which tracks mountedness of this component.
   */
  private mounted: boolean = false;
  constructor(props: IPropKickManageDialog) {
    super(props);
    this.state = {
      fetched: false,
      users: [],
      checks: [],
    };
  }
  public render() {
    const { modal } = this.props;
    const { fetched, users, checks } = this.state;

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
                    <WithRandomIds names={['inputid']}>
                      {({ inputid }) => (
                        <FormTable>
                          <tbody>
                            {map2(users, checks, (id, check, i) => (
                              <tr key={id}>
                                <td>
                                  <input
                                    type="checkbox"
                                    checked={check}
                                    id={`${inputid}-${id}`}
                                    onChange={this.makeHandleChange(i)}
                                  />
                                </td>
                                <td>
                                  <label htmlFor={`${inputid}-${id}`}>
                                    {id}
                                  </label>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </FormTable>
                      )}
                    </WithRandomIds>
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
    // Prepare a checklist with the same length.
    const checks: boolean[] = new Array(users.length).fill(false);
    // XXX This is anti-pattern
    if (this.mounted) {
      this.setState({
        fetched: true,
        users,
        checks,
      });
    }
  }
  public componentWillUnmount() {
    this.mounted = false;
  }
  /**
   * Make a handler of checkbox change.
   */
  private makeHandleChange(idx: number) {
    return (e: React.SyntheticEvent<HTMLInputElement>) => {
      this.setState({
        checks: updateArray(this.state.checks, idx, e.currentTarget.checked),
      });
    };
  }
  @bind
  private handleCancel() {
    this.props.onSelect(null);
  }
  @bind
  private handleYesClick() {
    const { users, checks } = this.state;
    // List checked users.
    const checkedUsers = filter2Right(checks, users, check => check);
    this.props.onSelect({
      remove: checkedUsers,
    });
  }
}
