import * as React from 'react';
import { IChecklistDialog } from '../defs';
import { I18n } from '../../i18n';
import { Dialog } from './base';
import { NoButton, YesButton, FormTable, FormControlWrapper } from './parts';
import { bind } from 'bind-decorator';
import { FontAwesomeIcon } from '../../util/icon';
import { WithRandomIds } from '../../util/with-ids';
import { map2 } from '../../util/map2';
import { filter2Right } from '../../util/filter2';
import { updateArray } from '../../util/update-array';

export interface IPropChecklistDialog extends IChecklistDialog {
  onSelect(result: string[] | null): void;
}

/**
 * Select multiple using checklist dialog.
 */
export class ChecklistDialog extends React.PureComponent<
  IPropChecklistDialog,
  {
    /**
     * Whether data is fetcehd.
     */
    fetched: boolean;
    /**
     * List of options.
     */
    options: Array<{
      id: string;
      label: string;
    }>;
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
  constructor(props: IPropChecklistDialog) {
    super(props);
    this.state = {
      fetched: false,
      options: [],
      checks: [],
    };
  }
  public render() {
    const { modal, title, message, empty, ok, cancel } = this.props;
    const { fetched, options, checks } = this.state;

    return (
      <Dialog
        modal={modal}
        title={title}
        message={fetched ? (options.length > 0 ? message : empty) : ''}
        onCancel={this.handleCancel}
        buttons={() => (
          <>
            <NoButton onClick={this.handleCancel}>{cancel}</NoButton>
            {fetched && options.length > 0 ? (
              <YesButton onClick={this.handleYesClick}>{ok}</YesButton>
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
                      {map2(options, checks, ({ id, label }, check, i) => (
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
                            <label htmlFor={`${inputid}-${id}`}>{label}</label>
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
  }
  public async componentDidMount() {
    this.mounted = true;
    // Listen for input promise.
    const options = await this.props.options;
    // Prepare a checklist with the same length.
    const checks: boolean[] = new Array(options.length).fill(false);
    // XXX This is anti-pattern
    if (this.mounted) {
      this.setState({
        fetched: true,
        options,
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
    const { options, checks } = this.state;
    // List checked users.
    const checkedIds = filter2Right(checks, options, check => check).map(
      ({ id }) => id,
    );
    this.props.onSelect(checkedIds);
  }
}
